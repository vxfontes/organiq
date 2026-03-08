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
