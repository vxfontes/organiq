import 'package:json_annotation/json_annotation.dart';

part 'routine_streak_output.g.dart';

@JsonSerializable()
class RoutineStreakOutput {
  const RoutineStreakOutput({
    required this.currentStreak,
    required this.totalCompletions,
  });

  final int currentStreak;
  final int totalCompletions;

  factory RoutineStreakOutput.fromJson(Map<String, dynamic> json) {
    return _$RoutineStreakOutputFromJson(json);
  }
}
