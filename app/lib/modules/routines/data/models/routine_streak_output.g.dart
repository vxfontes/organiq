// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_streak_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
