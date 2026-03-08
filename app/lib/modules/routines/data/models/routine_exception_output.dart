import 'package:json_annotation/json_annotation.dart';

part 'routine_exception_output.g.dart';

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
