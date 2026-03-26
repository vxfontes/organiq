import 'dart:async';

import 'package:organiq/modules/app_logs/data/models/screen_log_input.dart';
import 'package:organiq/modules/app_logs/domain/usecases/log_screen_usecase.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/shared/services/analytics/app_monitoring_service.dart';
import 'package:organiq/shared/services/analytics/app_session_service.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';

class ScreenLogService {
  ScreenLogService(
    this._logScreenUsecase,
    this._tokenStore,
    this._monitoringService,
    this._sessionService,
  );

  static const Duration _dedupeWindow = Duration(milliseconds: 800);

  final LogScreenUsecase _logScreenUsecase;
  final AuthTokenStore _tokenStore;
  final AppMonitoringService _monitoringService;
  final AppSessionService _sessionService;

  bool _started = false;
  String? _lastLoggedRoutePath;
  DateTime? _lastLoggedAt;

  void start() {
    if (_started) return;
    _started = true;
    unawaited(_sessionService.start());
    AppNavigation.addListener(_onRouteChanged);
    unawaited(_logCurrentRoute(force: true));
  }

  void dispose() {
    if (!_started) return;
    AppNavigation.removeListener(_onRouteChanged);
    _started = false;
  }

  void logInteraction({
    required String action,
    String? targetType,
    String? targetId,
    String? result,
    String? origin,
    String? flowName,
    String? flowStep,
    Map<String, dynamic>? metadata,
  }) {
    _logEvent(
      eventName: 'interaction',
      action: action,
      targetType: targetType,
      targetId: targetId,
      result: result,
      origin: origin,
      flowName: flowName,
      flowStep: flowStep,
      metadata: metadata,
    );
  }

  void logFlowStep({
    required String flowName,
    required String flowStep,
    String? action,
    String? targetType,
    String? targetId,
    String? result,
    String? origin,
    Map<String, dynamic>? metadata,
  }) {
    _logEvent(
      eventName: 'flow_step',
      action: action,
      targetType: targetType,
      targetId: targetId,
      result: result,
      origin: origin,
      flowName: flowName,
      flowStep: flowStep,
      metadata: metadata,
    );
  }

  void _logEvent({
    required String eventName,
    String? action,
    String? targetType,
    String? targetId,
    String? result,
    String? origin,
    String? flowName,
    String? flowStep,
    Map<String, dynamic>? metadata,
  }) {
    final routePath = _normalizeRoutePath(AppNavigation.path);
    if (routePath == null) return;
    final screenName = _screenNameFromRoute(routePath);
    final nextMetadata = _buildMetadata(
      action: action,
      targetType: targetType,
      targetId: targetId,
      result: result,
      origin: origin,
      flowName: flowName,
      flowStep: flowStep,
      metadata: metadata,
    );

    unawaited(
      _monitoringService.logEvent(
        eventName,
        parameters: <String, Object?>{
          'screen_name': screenName,
          'route_path': routePath,
          ..._analyticsMetadata(nextMetadata),
        },
      ),
    );

    unawaited(
      _sendLog(
        screenName: screenName,
        routePath: routePath,
        previousRoutePath: _lastLoggedRoutePath,
        eventName: eventName,
        metadata: nextMetadata,
        occurredAt: DateTime.now(),
      ),
    );
  }

  void _onRouteChanged() {
    unawaited(_logCurrentRoute());
  }

  Future<void> _logCurrentRoute({bool force = false}) async {
    final routePath = _normalizeRoutePath(AppNavigation.path);
    if (routePath == null) return;

    final now = DateTime.now();
    if (!force &&
        _lastLoggedRoutePath == routePath &&
        _lastLoggedAt != null &&
        now.difference(_lastLoggedAt!) < _dedupeWindow) {
      return;
    }

    final previousRoutePath = _lastLoggedRoutePath;
    _lastLoggedRoutePath = routePath;
    _lastLoggedAt = now;
    final screenName = _screenNameFromRoute(routePath);

    unawaited(
      _monitoringService.logScreen(
        screenName: screenName,
        routePath: routePath,
      ),
    );
    unawaited(_monitoringService.traceScreenTransition(screenName: screenName));

    await _sendLog(
      screenName: screenName,
      routePath: routePath,
      previousRoutePath: previousRoutePath,
      eventName: 'screen_view',
      metadata: null,
      occurredAt: now,
    );
  }

  Future<void> _sendLog({
    required String screenName,
    required String routePath,
    required String eventName,
    required DateTime occurredAt,
    String? previousRoutePath,
    Map<String, dynamic>? metadata,
  }) async {
    await _sessionService.start();
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) return;

    final input = ScreenLogInput(
      sessionId: _sessionService.sessionId,
      screenName: screenName,
      routePath: routePath,
      previousRoutePath: previousRoutePath,
      eventName: eventName,
      platform: _sessionService.platform,
      appVersion: _sessionService.appVersion,
      metadata: metadata,
      occurredAt: occurredAt,
    );
    final result = await _logScreenUsecase.call(input);
    result.fold((_) => null, (_) => null);
  }

  String? _normalizeRoutePath(String? rawPath) {
    if (rawPath == null) return null;
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return null;

    final withoutQuery = trimmed.split('?').first.split('#').first.trim();
    if (withoutQuery.isEmpty) return null;
    if (withoutQuery == '/') return '/';

    final cleaned = withoutQuery.endsWith('/')
        ? withoutQuery.substring(0, withoutQuery.length - 1)
        : withoutQuery;
    return cleaned.isEmpty ? '/' : cleaned;
  }

  String _screenNameFromRoute(String routePath) {
    if (routePath == '/') return 'splash';
    final parts = routePath
        .split('/')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'unknown';
    return parts.join('_');
  }

  Map<String, dynamic>? _buildMetadata({
    String? action,
    String? targetType,
    String? targetId,
    String? result,
    String? origin,
    String? flowName,
    String? flowStep,
    Map<String, dynamic>? metadata,
  }) {
    final map = <String, dynamic>{};

    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      map[key] = value;
    }

    put('flow_name', flowName);
    put('flow_step', flowStep);
    put('action', action);
    put('target_type', targetType);
    put('target_id', targetId);
    put('result', result);
    put('origin', origin);
    if (metadata != null && metadata.isNotEmpty) {
      map.addAll(metadata);
    }

    return map.isEmpty ? null : map;
  }

  Map<String, Object?> _analyticsMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return const <String, Object?>{};

    final mapped = <String, Object?>{};
    for (final entry in metadata.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is Object) {
        mapped[entry.key] = value;
      }
    }
    return mapped;
  }
}
