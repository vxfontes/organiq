class NotificationLogModel {
  final String id;
  final String type;
  final String referenceId;
  final String title;
  final String body;
  final int? leadMins;
  final String status;
  final DateTime scheduledFor;
  final DateTime? sentAt;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationLogModel({
    required this.id,
    required this.type,
    required this.referenceId,
    required this.title,
    required this.body,
    this.leadMins,
    required this.status,
    required this.scheduledFor,
    this.sentAt,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationLogModel.fromMap(Map<String, dynamic> map) {
    return NotificationLogModel(
      id: map['id'],
      type: map['type'],
      referenceId: map['referenceId'],
      title: map['title'],
      body: map['body'],
      leadMins: map['leadMins'],
      status: map['status'],
      scheduledFor: DateTime.parse(map['scheduledFor']),
      sentAt: map['sentAt'] != null ? DateTime.parse(map['sentAt']) : null,
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt']) : null,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
