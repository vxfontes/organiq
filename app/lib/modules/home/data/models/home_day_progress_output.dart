import 'package:json_annotation/json_annotation.dart';

part 'home_day_progress_output.g.dart';

@JsonSerializable()
class HomeDayProgressOutput {
  const HomeDayProgressOutput({
    required this.routinesDone,
    required this.routinesTotal,
    required this.tasksDone,
    required this.tasksTotal,
    required this.progressPercent,
  });

  @JsonKey(name: 'routines_done')
  final int routinesDone;
  @JsonKey(name: 'routines_total')
  final int routinesTotal;
  @JsonKey(name: 'tasks_done')
  final int tasksDone;
  @JsonKey(name: 'tasks_total')
  final int tasksTotal;
  @JsonKey(name: 'progress_percent')
  final double progressPercent;

  factory HomeDayProgressOutput.fromJson(Map<String, dynamic> json) {
    return _$HomeDayProgressOutputFromJson(json);
  }

  factory HomeDayProgressOutput.fromDynamic(dynamic value) {
    try {
      return HomeDayProgressOutput.fromJson(_asMap(value));
    } catch (_) {
      return const HomeDayProgressOutput(
        routinesDone: 0,
        routinesTotal: 0,
        tasksDone: 0,
        tasksTotal: 0,
        progressPercent: 0,
      );
    }
  }

  HomeDayProgressOutput copyWith({
    int? routinesDone,
    int? routinesTotal,
    int? tasksDone,
    int? tasksTotal,
    double? progressPercent,
  }) {
    return HomeDayProgressOutput(
      routinesDone: routinesDone ?? this.routinesDone,
      routinesTotal: routinesTotal ?? this.routinesTotal,
      tasksDone: tasksDone ?? this.tasksDone,
      tasksTotal: tasksTotal ?? this.tasksTotal,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }

  Map<String, dynamic> toJson() => _$HomeDayProgressOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }
}
