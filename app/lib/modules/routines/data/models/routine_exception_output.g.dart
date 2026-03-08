// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_exception_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineExceptionOutput _$RoutineExceptionOutputFromJson(
  Map<String, dynamic> json,
) => RoutineExceptionOutput(
  id: json['id'] as String,
  routineId: json['routineId'] as String,
  exceptionDate: json['exceptionDate'] as String,
  action: json['action'] as String,
  newStartTime: json['newStartTime'] as String?,
  newEndTime: json['newEndTime'] as String?,
  reason: json['reason'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$RoutineExceptionOutputToJson(
  RoutineExceptionOutput instance,
) => <String, dynamic>{
  'id': instance.id,
  'routineId': instance.routineId,
  'exceptionDate': instance.exceptionDate,
  'action': instance.action,
  'newStartTime': instance.newStartTime,
  'newEndTime': instance.newEndTime,
  'reason': instance.reason,
  'createdAt': instance.createdAt.toIso8601String(),
};
