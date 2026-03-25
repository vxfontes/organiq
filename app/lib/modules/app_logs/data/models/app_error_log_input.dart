class AppErrorLogInput {
  AppErrorLogInput({
    this.sessionId,
    this.screenName,
    this.routePath,
    required this.source,
    this.errorCode,
    required this.message,
    this.stackTrace,
    this.requestId,
    this.requestPath,
    this.requestMethod,
    this.httpStatus,
    this.metadata,
    this.occurredAt,
  });

  final String? sessionId;
  final String? screenName;
  final String? routePath;
  final String source;
  final String? errorCode;
  final String message;
  final String? stackTrace;
  final String? requestId;
  final String? requestPath;
  final String? requestMethod;
  final int? httpStatus;
  final Map<String, dynamic>? metadata;
  final DateTime? occurredAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'source': source.trim(),
      'message': message.trim(),
    };
    _writeString(map, 'sessionId', sessionId);
    _writeString(map, 'screenName', screenName);
    _writeString(map, 'routePath', routePath);
    _writeString(map, 'errorCode', errorCode);
    _writeString(map, 'stackTrace', stackTrace);
    _writeString(map, 'requestId', requestId);
    _writeString(map, 'requestPath', requestPath);
    _writeString(map, 'requestMethod', requestMethod);
    if (httpStatus != null) {
      map['httpStatus'] = httpStatus;
    }
    if (metadata != null && metadata!.isNotEmpty) {
      map['metadata'] = metadata;
    }
    if (occurredAt != null) {
      map['occurredAt'] = occurredAt!.toUtc().toIso8601String();
    }
    return map;
  }

  void _writeString(Map<String, dynamic> map, String key, String? value) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      map[key] = trimmed;
    }
  }
}
