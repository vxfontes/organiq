import 'dart:async';

class AppErrorReportPayload {
  AppErrorReportPayload({
    required this.source,
    required this.message,
    this.errorCode,
    this.stackTrace,
    this.requestId,
    this.requestPath,
    this.requestMethod,
    this.httpStatus,
    this.metadata,
    this.screenName,
    this.routePath,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now();

  final String source;
  final String message;
  final String? errorCode;
  final String? stackTrace;
  final String? requestId;
  final String? requestPath;
  final String? requestMethod;
  final int? httpStatus;
  final Map<String, dynamic>? metadata;
  final String? screenName;
  final String? routePath;
  final DateTime occurredAt;
}

typedef AppErrorReportSink =
    Future<void> Function(AppErrorReportPayload payload);

class AppErrorReporter {
  AppErrorReporter._();

  static final List<AppErrorReportPayload> _pending = <AppErrorReportPayload>[];
  static AppErrorReportSink? _sink;

  static void attach(AppErrorReportSink sink) {
    _sink = sink;
    final pending = List<AppErrorReportPayload>.from(_pending);
    _pending.clear();
    for (final payload in pending) {
      unawaited(_dispatch(payload));
    }
  }

  static void detach() {
    _sink = null;
  }

  static void report(AppErrorReportPayload payload) {
    if (_sink == null) {
      _pending.add(payload);
      return;
    }
    unawaited(_dispatch(payload));
  }

  static Future<void> _dispatch(AppErrorReportPayload payload) async {
    final sink = _sink;
    if (sink == null) {
      _pending.add(payload);
      return;
    }
    try {
      await sink(payload);
    } catch (_) {
      // Logging must never crash the app.
    }
  }
}
