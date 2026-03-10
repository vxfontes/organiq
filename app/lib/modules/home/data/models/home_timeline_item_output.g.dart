// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_timeline_item_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeTimelineItemOutput _$HomeTimelineItemOutputFromJson(
  Map<String, dynamic> json,
) => HomeTimelineItemOutput(
  id: json['id'] == null
      ? ''
      : HomeTimelineItemOutput._stringFromJson(json['id']),
  itemType: json['item_type'] == null
      ? ''
      : HomeTimelineItemOutput._itemTypeFromJson(json['item_type']),
  title: json['title'] == null
      ? ''
      : HomeTimelineItemOutput._stringFromJson(json['title']),
  subtitle: HomeTimelineItemOutput._subtitleFromJson(json['subtitle']),
  scheduledTime: HomeTimelineItemOutput._scheduledTimeFromJson(
    json['scheduled_time'],
  ),
  endScheduledTime: HomeTimelineItemOutput._nullableDateTimeFromJson(
    json['end_scheduled_time'],
  ),
  isCompleted: json['is_completed'] == null
      ? false
      : HomeTimelineItemOutput._boolFromJson(json['is_completed']),
  isOverdue: json['is_overdue'] == null
      ? false
      : HomeTimelineItemOutput._boolFromJson(json['is_overdue']),
);

Map<String, dynamic> _$HomeTimelineItemOutputToJson(
  HomeTimelineItemOutput instance,
) => <String, dynamic>{
  'id': instance.id,
  'item_type': instance.itemType,
  'title': instance.title,
  'subtitle': instance.subtitle,
  'scheduled_time': instance.scheduledTime.toIso8601String(),
  'end_scheduled_time': instance.endScheduledTime?.toIso8601String(),
  'is_completed': instance.isCompleted,
  'is_overdue': instance.isOverdue,
};
