// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_activity_day_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineActivityDayOutput _$RoutineActivityDayOutputFromJson(
  Map<String, dynamic> json,
) => RoutineActivityDayOutput(
  date: json['date'] as String,
  isCompleted: json['isCompleted'] as bool,
  isScheduled: json['isScheduled'] as bool,
  isToday: json['isToday'] as bool,
  isSkipped: json['isSkipped'] as bool,
  weekdayLabel: json['weekdayLabel'] as String,
);

Map<String, dynamic> _$RoutineActivityDayOutputToJson(
  RoutineActivityDayOutput instance,
) => <String, dynamic>{
  'date': instance.date,
  'isCompleted': instance.isCompleted,
  'isScheduled': instance.isScheduled,
  'isToday': instance.isToday,
  'isSkipped': instance.isSkipped,
  'weekdayLabel': instance.weekdayLabel,
};
