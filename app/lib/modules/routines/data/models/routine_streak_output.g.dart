// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_streak_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineStreakOutput _$RoutineStreakOutputFromJson(Map<String, dynamic> json) =>
    RoutineStreakOutput(
      currentStreak: (json['currentStreak'] as num).toInt(),
      totalCompletions: (json['totalCompletions'] as num).toInt(),
      streakText: json['streakText'] as String,
      activity: (json['activity'] as List<dynamic>)
          .map(
            (e) => RoutineActivityDayOutput.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$RoutineStreakOutputToJson(
  RoutineStreakOutput instance,
) => <String, dynamic>{
  'currentStreak': instance.currentStreak,
  'totalCompletions': instance.totalCompletions,
  'streakText': instance.streakText,
  'activity': instance.activity,
};
