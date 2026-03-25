import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppMonitoringService {
  AppMonitoringService._();

  static final AppMonitoringService instance = AppMonitoringService._();
  static const String _screenTransitionTrace = 'screen_transition';
  static const String _appEnv = String.fromEnvironment('APP_ENV');

  bool _initialized = false;
  String? _appVersion;
  String? _buildNumber;
  String? _currentRoute;
  String? _currentScreenName;
  String? _userId;

  bool get isInitialized => _initialized;
  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;
  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;
  FirebasePerformance get _performance => FirebasePerformance.instance;

  Future<void> initialize() async {
    if (_initialized || !_isSupportedPlatform) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    } catch (_) {
      _appVersion = null;
      _buildNumber = null;
    }

    await _analytics.setAnalyticsCollectionEnabled(true);
    await _analytics.setUserProperty(
      name: 'environment',
      value: _environmentLabel,
    );
    await _analytics.setUserProperty(name: 'build_mode', value: _buildMode);
    await _analytics.setUserProperty(name: 'platform', value: _platformLabel);
    await _analytics.setUserProperty(name: 'app_version', value: _appVersion);

    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    await _setCrashlyticsKeys(_baseContextParameters());

    await _performance.setPerformanceCollectionEnabled(true);

    _initialized = true;
  }

  Future<void> identifyUser({required String userId}) async {
    _userId = userId.trim().isEmpty ? null : userId.trim();
    if (!_initialized || _userId == null) return;

    await _analytics.setUserId(id: _userId);
    await _analytics.setUserProperty(name: 'user_id', value: _userId);
    await _crashlytics.setUserIdentifier(_userId!);
    await _crashlytics.setCustomKey('user_id', _userId!);
  }

  Future<void> clearUser() async {
    _userId = null;
    if (!_initialized) return;

    await _analytics.setUserId(id: null);
    await _analytics.setUserProperty(name: 'user_id', value: null);
    await _crashlytics.setUserIdentifier('');
    await _crashlytics.setCustomKey('user_id', '');
  }

  Future<void> setCustomKey(String key, Object value) async {
    if (!_initialized) return;

    final normalizedKey = _normalizeParamName(key);
    final normalizedValue = _normalizeParameterValue(value);
    if (normalizedValue == null) return;

    await _crashlytics.setCustomKey(normalizedKey, normalizedValue);
  }

  Future<void> setCurrentScreen({
    required String screenName,
    String? routePath,
  }) async {
    _currentScreenName = _normalizeScreenName(screenName);
    _currentRoute = routePath?.trim().isNotEmpty == true
        ? routePath!.trim()
        : _currentRoute;

    if (!_initialized) return;

    await _analytics.logScreenView(
      screenName: _currentScreenName,
      screenClass: _screenClass(routePath ?? screenName),
    );
    await _setCrashlyticsKeys(<String, Object?>{
      'screen_name': _currentScreenName,
      'route_path': _currentRoute,
    });
  }

  Future<void> logScreen({
    required String screenName,
    String? routePath,
  }) async {
    await setCurrentScreen(screenName: screenName, routePath: routePath);
  }

  Future<void> traceScreenTransition({required String screenName}) async {
    if (!_initialized || !_isSupportedPlatform) return;

    final trace = _performance.newTrace(_screenTransitionTrace);
    final normalizedScreenName = _normalizeScreenName(screenName);

    try {
      trace.putAttribute('screen_name', normalizedScreenName);
      await trace.start();
    } catch (_) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await trace.stop();
      } catch (_) {
        // Best-effort performance trace.
      }
    });
  }

  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    if (!_initialized) return;

    final normalizedName = _normalizeEventName(name);
    final analyticsParameters = _sanitizeParameters(<String, Object?>{
      ..._baseContextParameters(),
      if (_currentScreenName != null) 'screen_name': _currentScreenName,
      if (_currentRoute != null) 'route_path': _currentRoute,
      ...?parameters,
    });

    await _analytics.logEvent(
      name: normalizedName,
      parameters: analyticsParameters.isEmpty ? null : analyticsParameters,
    );
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, Object?>? parameters,
  }) async {
    if (!_initialized) return;

    await _setCrashlyticsKeys(<String, Object?>{
      ..._baseContextParameters(),
      if (_currentScreenName != null) 'screen_name': _currentScreenName,
      if (_currentRoute != null) 'route_path': _currentRoute,
      ...?parameters,
    });

    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    if (!_initialized) return;

    await _setCrashlyticsKeys(<String, Object?>{
      ..._baseContextParameters(),
      if (_currentScreenName != null) 'screen_name': _currentScreenName,
      if (_currentRoute != null) 'route_path': _currentRoute,
      if (details.library != null) 'flutter_library': details.library,
      if (details.context != null)
        'flutter_context': details.context!.toDescription(),
    });

    await _crashlytics.recordFlutterFatalError(details);
  }

  HttpMetric? newHttpMetric({required Uri url, required String method}) {
    if (!_initialized || !_isSupportedPlatform) return null;

    final httpMethod = _httpMethod(method);
    if (httpMethod == null) return null;

    return _performance.newHttpMetric(url.toString(), httpMethod);
  }

  Future<void> startHttpMetric(
    HttpMetric? metric, {
    int? requestPayloadSize,
  }) async {
    if (metric == null) return;

    if (requestPayloadSize != null && requestPayloadSize >= 0) {
      metric.requestPayloadSize = requestPayloadSize;
    }

    try {
      await metric.start();
    } catch (_) {
      // Best-effort performance metric.
    }
  }

  Future<void> stopHttpMetric(
    HttpMetric? metric, {
    int? statusCode,
    String? responseContentType,
    int? responsePayloadSize,
  }) async {
    if (metric == null) return;

    if (statusCode != null) {
      metric.httpResponseCode = statusCode;
    }
    if (responseContentType != null && responseContentType.isNotEmpty) {
      metric.responseContentType = responseContentType;
    }
    if (responsePayloadSize != null && responsePayloadSize >= 0) {
      metric.responsePayloadSize = responsePayloadSize;
    }

    try {
      await metric.stop();
    } catch (_) {
      // Best-effort performance metric.
    }
  }

  Map<String, Object?> _baseContextParameters() {
    return <String, Object?>{
      'environment': _environmentLabel,
      'build_mode': _buildMode,
      'platform': _platformLabel,
      if (_appVersion != null) 'app_version': _appVersion,
      if (_buildNumber != null) 'build_number': _buildNumber,
      if (_userId != null) 'user_id': _userId,
    };
  }

  Future<void> _setCrashlyticsKeys(Map<String, Object?> values) async {
    final sanitized = _sanitizeParameters(values);
    for (final entry in sanitized.entries) {
      await _crashlytics.setCustomKey(entry.key, entry.value);
    }
  }

  Map<String, Object> _sanitizeParameters(Map<String, Object?> values) {
    final sanitized = <String, Object>{};

    for (final entry in values.entries) {
      final normalizedValue = _normalizeParameterValue(entry.value);
      if (normalizedValue == null) continue;

      sanitized[_normalizeParamName(entry.key)] = normalizedValue;
    }

    return sanitized;
  }

  Object? _normalizeParameterValue(Object? value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is DateTime) return value.toIso8601String();

    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text.length > 100 ? text.substring(0, 100) : text;
  }

  String _normalizeEventName(String rawName) {
    final sanitized = rawName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final prefixed = sanitized.isEmpty ? 'event' : sanitized;
    final startsWithLetter = RegExp(r'^[a-z]').hasMatch(prefixed);
    final withPrefix = startsWithLetter ? prefixed : 'event_$prefixed';
    return withPrefix.length > 40 ? withPrefix.substring(0, 40) : withPrefix;
  }

  String _normalizeParamName(String rawName) {
    final sanitized = rawName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final prefixed = sanitized.isEmpty ? 'param' : sanitized;
    final startsWithLetter = RegExp(r'^[a-z]').hasMatch(prefixed);
    final withPrefix = startsWithLetter ? prefixed : 'param_$prefixed';
    return withPrefix.length > 40 ? withPrefix.substring(0, 40) : withPrefix;
  }

  String _normalizeScreenName(String rawName) {
    final normalized = rawName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (normalized.isEmpty) return 'unknown';
    return normalized.length > 36 ? normalized.substring(0, 36) : normalized;
  }

  String _screenClass(String value) {
    final normalized = _normalizeScreenName(value);
    return normalized.length > 36 ? normalized.substring(0, 36) : normalized;
  }

  HttpMethod? _httpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'DELETE':
        return HttpMethod.Delete;
      case 'GET':
        return HttpMethod.Get;
      case 'PATCH':
        return HttpMethod.Patch;
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      default:
        return null;
    }
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String get _environmentLabel {
    final configured = _appEnv.trim().toLowerCase();
    if (configured.isNotEmpty) return configured;
    if (kReleaseMode) return 'production';
    if (kProfileMode) return 'profile';
    return 'development';
  }

  String get _buildMode {
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'debug';
  }

  String get _platformLabel {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
