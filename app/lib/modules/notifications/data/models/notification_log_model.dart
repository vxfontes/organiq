import 'package:json_annotation/json_annotation.dart';

part 'notification_log_model.g.dart';

@JsonSerializable()
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

  const NotificationLogModel({
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

  factory NotificationLogModel.fromJson(Map<String, dynamic> json) {
    return _$NotificationLogModelFromJson(json);
  }

  factory NotificationLogModel.fromMap(Map<String, dynamic> map) {
    return NotificationLogModel.fromJson(map);
  }

  Map<String, dynamic> toJson() => _$NotificationLogModelToJson(this);
}
