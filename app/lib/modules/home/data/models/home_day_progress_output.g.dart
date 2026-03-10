// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_day_progress_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeDayProgressOutput _$HomeDayProgressOutputFromJson(
  Map<String, dynamic> json,
) => HomeDayProgressOutput(
  routinesDone: (json['routines_done'] as num).toInt(),
  routinesTotal: (json['routines_total'] as num).toInt(),
  tasksDone: (json['tasks_done'] as num).toInt(),
  tasksTotal: (json['tasks_total'] as num).toInt(),
  progressPercent: (json['progress_percent'] as num).toDouble(),
);

Map<String, dynamic> _$HomeDayProgressOutputToJson(
  HomeDayProgressOutput instance,
) => <String, dynamic>{
  'routines_done': instance.routinesDone,
  'routines_total': instance.routinesTotal,
  'tasks_done': instance.tasksDone,
  'tasks_total': instance.tasksTotal,
  'progress_percent': instance.progressPercent,
};
