import 'dart:async';

import 'package:organiq/modules/app_logs/data/models/app_error_log_input.dart';
import 'package:organiq/modules/app_logs/domain/usecases/log_app_error_usecase.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/shared/services/analytics/app_error_reporter.dart';
import 'package:organiq/shared/services/analytics/app_session_service.dart';

class AppErrorLogService {
  AppErrorLogService(this._logAppErrorUsecase, this._sessionService);

  static const Duration _dedupeWindow = Duration(seconds: 2);

  final LogAppErrorUsecase _logAppErrorUsecase;
  final AppSessionService _sessionService;

  bool _started = false;
  String? _lastFingerprint;
  DateTime? _lastLoggedAt;

  void start() {
    if (_started) return;
    _started = true;
    AppErrorReporter.attach(_handlePayload);
  }

  void dispose() {
    if (!_started) return;
    _started = false;
    AppErrorReporter.detach();
  }

  Future<void> _handlePayload(AppErrorReportPayload payload) async {
    await _sessionService.start();

    final routePath = _normalizeRoutePath(
      payload.routePath ?? AppNavigation.path,
    );
    final screenName = routePath == null
        ? payload.screenName
        : _screenNameFromRoute(routePath);
    final message = payload.message.trim();
    if (message.isEmpty) return;

    final fingerprint = [
      payload.source.trim(),
      payload.errorCode?.trim() ?? '',
      message,
      routePath ?? '',
      payload.requestPath?.trim() ?? '',
      payload.httpStatus?.toString() ?? '',
    ].join('|');
    final now = DateTime.now();
    if (_lastFingerprint == fingerprint &&
        _lastLoggedAt != null &&
        now.difference(_lastLoggedAt!) < _dedupeWindow) {
      return;
    }

    _lastFingerprint = fingerprint;
    _lastLoggedAt = now;

    final input = AppErrorLogInput(
      sessionId: _sessionService.sessionId,
      screenName: screenName,
      routePath: routePath,
      source: payload.source,
      errorCode: payload.errorCode,
      message: message,
      stackTrace: payload.stackTrace,
      requestId: payload.requestId,
      requestPath: payload.requestPath,
      requestMethod: payload.requestMethod,
      httpStatus: payload.httpStatus,
      metadata: payload.metadata,
      occurredAt: payload.occurredAt,
    );
    final result = await _logAppErrorUsecase.call(input);
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

  String? _screenNameFromRoute(String routePath) {
    if (routePath == '/') return 'splash';
    final parts = routePath
        .split('/')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return null;
    return parts.join('_');
  }
}
