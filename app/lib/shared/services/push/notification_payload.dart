enum NotificationType {
  reminder,
  event,
  task,
  routine,
  test;

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.test,
    );
  }
}

class NotificationPayload {
  final String? id; // notification_log_id
  final NotificationType type;
  final String? referenceId;
  final int? leadMins;
  final String? title;
  final String? body;

  NotificationPayload({
    this.id,
    required this.type,
    this.referenceId,
    this.leadMins,
    this.title,
    this.body,
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> data) {
    return NotificationPayload(
      id: data['notification_log_id']?.toString(),
      type: NotificationType.fromString(data['type']?.toString()),
      referenceId: data['reference_id']?.toString(),
      leadMins: int.tryParse(data['lead_mins']?.toString() ?? ''),
      title: data['title']?.toString(),
      body: data['body']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notification_log_id': id,
      'type': type.name,
      'reference_id': referenceId,
      'lead_mins': leadMins,
      'title': title,
      'body': body,
    };
  }
}
