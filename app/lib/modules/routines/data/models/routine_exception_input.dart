import 'package:json_annotation/json_annotation.dart';

part 'routine_exception_input.g.dart';

@JsonSerializable()
class RoutineExceptionInput {
  const RoutineExceptionInput({
    required this.exceptionDate,
    this.action,
    this.newStartTime,
    this.newEndTime,
    this.reason,
  });

  final String exceptionDate;
  final String? action;
  final String? newStartTime;
  final String? newEndTime;
  final String? reason;

  factory RoutineExceptionInput.fromJson(Map<String, dynamic> json) {
    return _$RoutineExceptionInputFromJson(json);
  }

  Map<String, dynamic> toJson() => _$RoutineExceptionInputToJson(this);
}
