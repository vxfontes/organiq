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

RoutineStreakOutput _$RoutineStreakOutputFromJson(Map<String, dynamic> json) =>
    RoutineStreakOutput(
      currentStreak: (json['currentStreak'] as num).toInt(),
      totalCompletions: (json['totalCompletions'] as num).toInt(),
    );

Map<String, dynamic> _$RoutineStreakOutputToJson(
  RoutineStreakOutput instance,
) => <String, dynamic>{
  'currentStreak': instance.currentStreak,
  'totalCompletions': instance.totalCompletions,
};

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
