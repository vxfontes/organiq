import 'package:json_annotation/json_annotation.dart';

part 'routine_streak_output.g.dart';

@JsonSerializable()
class RoutineStreakOutput {
  const RoutineStreakOutput({
    required this.currentStreak,
    required this.totalCompletions,
    required this.streakText,
  });

  final int currentStreak;
  final int totalCompletions;
  final String streakText;

  factory RoutineStreakOutput.fromJson(Map<String, dynamic> json) {
    return _$RoutineStreakOutputFromJson(json);
  }
}
