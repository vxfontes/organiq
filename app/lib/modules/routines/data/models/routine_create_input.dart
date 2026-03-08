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
