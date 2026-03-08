// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_exception_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineExceptionInput _$RoutineExceptionInputFromJson(
  Map<String, dynamic> json,
) => RoutineExceptionInput(
  exceptionDate: json['exceptionDate'] as String,
  action: json['action'] as String?,
  newStartTime: json['newStartTime'] as String?,
  newEndTime: json['newEndTime'] as String?,
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$RoutineExceptionInputToJson(
  RoutineExceptionInput instance,
) => <String, dynamic>{
  'exceptionDate': instance.exceptionDate,
  'action': instance.action,
  'newStartTime': instance.newStartTime,
  'newEndTime': instance.newEndTime,
  'reason': instance.reason,
};
