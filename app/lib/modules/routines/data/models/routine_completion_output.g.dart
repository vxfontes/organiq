// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_completion_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineCompletionOutput _$RoutineCompletionOutputFromJson(
  Map<String, dynamic> json,
) => RoutineCompletionOutput(
  id: json['id'] as String,
  routineId: json['routineId'] as String,
  completedOn: json['completedOn'] as String,
  completedAt: DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$RoutineCompletionOutputToJson(
  RoutineCompletionOutput instance,
) => <String, dynamic>{
  'id': instance.id,
  'routineId': instance.routineId,
  'completedOn': instance.completedOn,
  'completedAt': instance.completedAt.toIso8601String(),
};
