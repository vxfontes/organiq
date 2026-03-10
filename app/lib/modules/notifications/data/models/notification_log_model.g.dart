// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationLogModel _$NotificationLogModelFromJson(
  Map<String, dynamic> json,
) => NotificationLogModel(
  id: json['id'] as String,
  type: json['type'] as String,
  referenceId: json['referenceId'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  leadMins: (json['leadMins'] as num?)?.toInt(),
  status: json['status'] as String,
  scheduledFor: DateTime.parse(json['scheduledFor'] as String),
  sentAt: json['sentAt'] == null
      ? null
      : DateTime.parse(json['sentAt'] as String),
  readAt: json['readAt'] == null
      ? null
      : DateTime.parse(json['readAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$NotificationLogModelToJson(
  NotificationLogModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'referenceId': instance.referenceId,
  'title': instance.title,
  'body': instance.body,
  'leadMins': instance.leadMins,
  'status': instance.status,
  'scheduledFor': instance.scheduledFor.toIso8601String(),
  'sentAt': instance.sentAt?.toIso8601String(),
  'readAt': instance.readAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
};
