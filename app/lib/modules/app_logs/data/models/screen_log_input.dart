class ScreenLogInput {
  ScreenLogInput({
    this.sessionId,
    required this.screenName,
    required this.routePath,
    this.previousRoutePath,
    this.eventName,
    this.platform,
    this.appVersion,
    this.metadata,
    this.occurredAt,
  });

  final String? sessionId;
  final String screenName;
  final String routePath;
  final String? previousRoutePath;
  final String? eventName;
  final String? platform;
  final String? appVersion;
  final Map<String, dynamic>? metadata;
  final DateTime? occurredAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'screenName': screenName,
      'routePath': routePath,
    };
    final session = sessionId?.trim();
    if (session != null && session.isNotEmpty) {
      map['sessionId'] = session;
    }
    final previous = previousRoutePath?.trim();
    if (previous != null && previous.isNotEmpty) {
      map['previousRoutePath'] = previous;
    }
    final event = eventName?.trim();
    if (event != null && event.isNotEmpty) {
      map['eventName'] = event;
    }
    final currentPlatform = platform?.trim();
    if (currentPlatform != null && currentPlatform.isNotEmpty) {
      map['platform'] = currentPlatform;
    }
    final currentAppVersion = appVersion?.trim();
    if (currentAppVersion != null && currentAppVersion.isNotEmpty) {
      map['appVersion'] = currentAppVersion;
    }
    if (metadata != null && metadata!.isNotEmpty) {
      map['metadata'] = metadata;
    }
    if (occurredAt != null) {
      map['occurredAt'] = occurredAt!.toUtc().toIso8601String();
    }
    return map;
  }
}
