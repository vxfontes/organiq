import 'package:json_annotation/json_annotation.dart';

part 'routine_today_summary_output.g.dart';

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
