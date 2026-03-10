import 'package:json_annotation/json_annotation.dart';
import 'package:inbota/modules/home/data/models/home_day_progress_output.dart';
import 'package:inbota/modules/home/data/models/home_insight_output.dart';
import 'package:inbota/modules/home/data/models/home_shopping_preview_output.dart';
import 'package:inbota/modules/home/data/models/home_timeline_item_output.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';

part 'home_dashboard_output.g.dart';

@JsonSerializable()
class HomeDashboardOutput {
  const HomeDashboardOutput({
    required this.dayProgress,
    this.insight,
    required this.timeline,
    required this.shoppingPreview,
    required this.weekDensity,
    required this.focusTasks,
    this.eventsTodayCount,
    this.remindersTodayCount,
  });

  @JsonKey(name: 'day_progress', fromJson: _dayProgressFromJson)
  final HomeDayProgressOutput dayProgress;
  @JsonKey(fromJson: _insightFromJson)
  final HomeInsightOutput? insight;
  @JsonKey(
    fromJson: _timelineFromJson,
    defaultValue: <HomeTimelineItemOutput>[],
  )
  final List<HomeTimelineItemOutput> timeline;
  @JsonKey(
    name: 'shopping_preview',
    fromJson: _shoppingPreviewFromJson,
    defaultValue: <HomeShoppingPreviewOutput>[],
  )
  final List<HomeShoppingPreviewOutput> shoppingPreview;
  @JsonKey(
    name: 'week_density',
    fromJson: _weekDensityFromJson,
    defaultValue: <String, int>{},
  )
  final Map<String, int> weekDensity;
  @JsonKey(
    name: 'focus_tasks',
    fromJson: _focusTasksFromJson,
    defaultValue: <TaskOutput>[],
  )
  final List<TaskOutput> focusTasks;
  @JsonKey(name: 'events_today_count')
  final int? eventsTodayCount;
  @JsonKey(name: 'reminders_today_count')
  final int? remindersTodayCount;

  factory HomeDashboardOutput.fromJson(Map<String, dynamic> json) {
    return _$HomeDashboardOutputFromJson(json);
  }

  factory HomeDashboardOutput.fromDynamic(dynamic value) {
    try {
      return HomeDashboardOutput.fromJson(_asMap(value));
    } catch (_) {
      return const HomeDashboardOutput(
        dayProgress: HomeDayProgressOutput(
          routinesDone: 0,
          routinesTotal: 0,
          tasksDone: 0,
          tasksTotal: 0,
          progressPercent: 0,
        ),
        timeline: [],
        shoppingPreview: [],
        weekDensity: {},
        focusTasks: [],
      );
    }
  }

  HomeDashboardOutput copyWith({
    HomeDayProgressOutput? dayProgress,
    HomeInsightOutput? insight,
    bool clearInsight = false,
    List<HomeTimelineItemOutput>? timeline,
    List<HomeShoppingPreviewOutput>? shoppingPreview,
    Map<String, int>? weekDensity,
    List<TaskOutput>? focusTasks,
    int? eventsTodayCount,
    int? remindersTodayCount,
    bool clearEventsTodayCount = false,
    bool clearRemindersTodayCount = false,
  }) {
    return HomeDashboardOutput(
      dayProgress: dayProgress ?? this.dayProgress,
      insight: clearInsight ? null : (insight ?? this.insight),
      timeline: timeline ?? this.timeline,
      shoppingPreview: shoppingPreview ?? this.shoppingPreview,
      weekDensity: weekDensity ?? this.weekDensity,
      focusTasks: focusTasks ?? this.focusTasks,
      eventsTodayCount: clearEventsTodayCount
          ? null
          : (eventsTodayCount ?? this.eventsTodayCount),
      remindersTodayCount: clearRemindersTodayCount
          ? null
          : (remindersTodayCount ?? this.remindersTodayCount),
    );
  }

  Map<String, dynamic> toJson() => _$HomeDashboardOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static HomeDayProgressOutput _dayProgressFromJson(dynamic value) {
    return HomeDayProgressOutput.fromDynamic(value);
  }

  static HomeInsightOutput? _insightFromJson(dynamic value) {
    if (value == null || value is! Map) return null;
    return HomeInsightOutput.fromDynamic(value);
  }

  static List<HomeTimelineItemOutput> _timelineFromJson(dynamic value) {
    if (value is! List) return const [];

    final timeline = <HomeTimelineItemOutput>[];
    for (final item in value) {
      if (item is! Map) continue;
      try {
        timeline.add(HomeTimelineItemOutput.fromJson(_asMap(item)));
      } catch (_) {
      }
    }
    return timeline;
  }

  static List<HomeShoppingPreviewOutput> _shoppingPreviewFromJson(
    dynamic value,
  ) {
    if (value is! List) return const [];

    final preview = <HomeShoppingPreviewOutput>[];
    for (final item in value) {
      if (item is! Map) continue;
      try {
        preview.add(HomeShoppingPreviewOutput.fromJson(_asMap(item)));
      } catch (_) {
      }
    }
    return preview;
  }

  static Map<String, int> _weekDensityFromJson(dynamic value) {
    if (value is! Map) return const {};

    final density = <String, int>{};
    value.forEach((key, rawCount) {
      final count = _asInt(rawCount);
      if (count == null) return;
      density[key.toString()] = count;
    });
    return density;
  }

  static List<TaskOutput> _focusTasksFromJson(dynamic value) {
    if (value is! List) return const [];

    final tasks = <TaskOutput>[];
    for (final item in value) {
      if (item is! Map) continue;
      try {
        tasks.add(TaskOutput.fromJson(_asMap(item)));
      } catch (_) {
      }
    }
    return tasks;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
