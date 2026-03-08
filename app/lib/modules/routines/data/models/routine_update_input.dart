import 'package:json_annotation/json_annotation.dart';

part 'routine_update_input.g.dart';

@JsonSerializable()
class RoutineUpdateInput {
  const RoutineUpdateInput({
    this.title,
    this.description,
    this.recurrenceType,
    this.weekdays,
    this.startTime,
    this.endTime,
    this.weekOfMonth,
    this.startsOn,
    this.endsOn,
    this.color,
    this.flagId,
    this.subflagId,
  });

  final String? title;
  final String? description;
  final String? recurrenceType;
  final List<int>? weekdays;
  final String? startTime;
  final String? endTime;
  final int? weekOfMonth;
  final String? startsOn;
  final String? endsOn;
  final String? color;
  final String? flagId;
  final String? subflagId;

  factory RoutineUpdateInput.fromJson(Map<String, dynamic> json) {
    return _$RoutineUpdateInputFromJson(json);
  }

  Map<String, dynamic> toJson() => _$RoutineUpdateInputToJson(this);
}
