import 'package:json_annotation/json_annotation.dart';

part 'routine_create_input.g.dart';

@JsonSerializable()
class RoutineCreateInput {
  const RoutineCreateInput({
    required this.title,
    this.description,
    this.recurrenceType,
    required this.weekdays,
    required this.startTime,
    this.endTime,
    this.weekOfMonth,
    this.startsOn,
    this.endsOn,
    this.color,
    this.flagId,
    this.subflagId,
  });

  final String title;
  final String? description;
  final String? recurrenceType;
  final List<int> weekdays;
  final String startTime;
  final String? endTime;
  final int? weekOfMonth;
  final String? startsOn;
  final String? endsOn;
  final String? color;
  final String? flagId;
  final String? subflagId;

  factory RoutineCreateInput.fromJson(Map<String, dynamic> json) {
    return _$RoutineCreateInputFromJson(json);
  }

  Map<String, dynamic> toJson() => _$RoutineCreateInputToJson(this);
}

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
