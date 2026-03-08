// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_today_summary_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineTodaySummaryOutput _$RoutineTodaySummaryOutputFromJson(
  Map<String, dynamic> json,
) => RoutineTodaySummaryOutput(
  total: (json['total'] as num).toInt(),
  completed: (json['completed'] as num).toInt(),
);

Map<String, dynamic> _$RoutineTodaySummaryOutputToJson(
  RoutineTodaySummaryOutput instance,
) => <String, dynamic>{
  'total': instance.total,
  'completed': instance.completed,
};
