import 'package:json_annotation/json_annotation.dart';

part 'routine_activity_day_output.g.dart';

@JsonSerializable()
class RoutineActivityDayOutput {
  const RoutineActivityDayOutput({
    required this.date,
    required this.isCompleted,
    required this.isScheduled,
    required this.isToday,
    required this.isSkipped,
    required this.weekdayLabel,
  });

  final String date;
  final bool isCompleted;
  final bool isScheduled;
  final bool isToday;
  final bool isSkipped;
  final String weekdayLabel;

  factory RoutineActivityDayOutput.fromJson(Map<String, dynamic> json) {
    return _$RoutineActivityDayOutputFromJson(json);
  }
}