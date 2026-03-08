import 'package:json_annotation/json_annotation.dart';

part 'routine_completion_output.g.dart';

@JsonSerializable()
class RoutineCompletionOutput {
  const RoutineCompletionOutput({
    required this.id,
    required this.routineId,
    required this.completedOn,
    required this.completedAt,
  });

  final String id;
  final String routineId;
  final String completedOn;
  final DateTime completedAt;

  factory RoutineCompletionOutput.fromJson(Map<String, dynamic> json) {
    return _$RoutineCompletionOutputFromJson(json);
  }

  Map<String, dynamic> toJson() => _$RoutineCompletionOutputToJson(this);
}

@JsonSerializable()
class RoutineExceptionOutput {
  const RoutineExceptionOutput({
    required this.id,
    required this.routineId,
    required this.exceptionDate,
    required this.action,
    this.newStartTime,
    this.newEndTime,
    this.reason,
    required this.createdAt,
  });

  final String id;
  final String routineId;
  final String exceptionDate;
  final String action;
  final String? newStartTime;
  final String? newEndTime;
  final String? reason;
  final DateTime createdAt;

  factory RoutineExceptionOutput.fromJson(Map<String, dynamic> json) {
    return _$RoutineExceptionOutputFromJson(json);
  }

  Map<String, dynamic> toJson() => _$RoutineExceptionOutputToJson(this);
}

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

@JsonSerializable()
class RoutineTodaySummaryOutput {
  const RoutineTodaySummaryOutput({
    required this.total,
    required this.completed,
  });

  final int total;
  final int completed;

  factory RoutineTodaySummaryOutput.fromJson(Map<String, dynamic> json) {
    return _$RoutineTodaySummaryOutputFromJson(json);
  }
}
