import 'package:inbota/modules/tasks/data/models/task_output.dart';

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

  final HomeDayProgressOutput dayProgress;
  final HomeInsightOutput? insight;
  final List<HomeTimelineItemOutput> timeline;
  final List<HomeShoppingPreviewOutput> shoppingPreview;
  final Map<String, int> weekDensity;
  final List<TaskOutput> focusTasks;
  final int? eventsTodayCount;
  final int? remindersTodayCount;

  factory HomeDashboardOutput.fromDynamic(dynamic value) {
    final map = _asMap(value);
    final timelineRaw = _first(map, const ['timeline']);
    final shoppingRaw = _first(map, const [
      'shopping_preview',
      'shoppingPreview',
    ]);
    final weekDensityRaw = _first(map, const ['week_density', 'weekDensity']);
    final focusTasksRaw = _first(map, const ['focus_tasks', 'focusTasks']);

    return HomeDashboardOutput(
      dayProgress: HomeDayProgressOutput.fromDynamic(
        _first(map, const ['day_progress', 'dayProgress']),
      ),
      insight: _first(map, const ['insight']) == null
          ? null
          : HomeInsightOutput.fromDynamic(_first(map, const ['insight'])),
      timeline: _asList(
        timelineRaw,
      ).map(HomeTimelineItemOutput.fromDynamic).toList(growable: false),
      shoppingPreview: _asList(
        shoppingRaw,
      ).map(HomeShoppingPreviewOutput.fromDynamic).toList(growable: false),
      weekDensity: _parseWeekDensity(weekDensityRaw),
      focusTasks: _asList(
        focusTasksRaw,
      ).map(TaskOutput.fromDynamic).toList(growable: false),
      eventsTodayCount: _readInt(
        _first(map, const ['events_today_count', 'eventsTodayCount']),
      ),
      remindersTodayCount: _readInt(
        _first(map, const ['reminders_today_count', 'remindersTodayCount']),
      ),
    );
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

  static dynamic _first(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) return map[key];
    }
    return null;
  }

  static Map<String, int> _parseWeekDensity(dynamic value) {
    if (value is! Map) return const {};
    final output = <String, int>{};
    value.forEach((key, val) {
      final parsed = _readInt(val);
      if (parsed == null) return;
      output[key.toString()] = parsed;
    });
    return output;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static List _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _readDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class HomeDayProgressOutput {
  const HomeDayProgressOutput({
    required this.routinesDone,
    required this.routinesTotal,
    required this.tasksDone,
    required this.tasksTotal,
    required this.progressPercent,
  });

  final int routinesDone;
  final int routinesTotal;
  final int tasksDone;
  final int tasksTotal;
  final double progressPercent;

  factory HomeDayProgressOutput.fromDynamic(dynamic value) {
    final map = HomeDashboardOutput._asMap(value);
    return HomeDayProgressOutput(
      routinesDone:
          HomeDashboardOutput._readInt(
            HomeDashboardOutput._first(map, const [
              'routines_done',
              'routinesDone',
            ]),
          ) ??
          0,
      routinesTotal:
          HomeDashboardOutput._readInt(
            HomeDashboardOutput._first(map, const [
              'routines_total',
              'routinesTotal',
            ]),
          ) ??
          0,
      tasksDone:
          HomeDashboardOutput._readInt(
            HomeDashboardOutput._first(map, const ['tasks_done', 'tasksDone']),
          ) ??
          0,
      tasksTotal:
          HomeDashboardOutput._readInt(
            HomeDashboardOutput._first(map, const [
              'tasks_total',
              'tasksTotal',
            ]),
          ) ??
          0,
      progressPercent: HomeDashboardOutput._readDouble(
        HomeDashboardOutput._first(map, const [
          'progress_percent',
          'progressPercent',
        ]),
      ),
    );
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
}

class HomeInsightOutput {
  const HomeInsightOutput({
    required this.title,
    required this.summary,
    required this.footer,
    required this.isFocus,
  });

  final String title;
  final String summary;
  final String footer;
  final bool isFocus;

  factory HomeInsightOutput.fromDynamic(dynamic value) {
    final map = HomeDashboardOutput._asMap(value);
    return HomeInsightOutput(
      title: HomeDashboardOutput._readString(
        HomeDashboardOutput._first(map, const ['title']),
      ),
      summary: HomeDashboardOutput._readString(
        HomeDashboardOutput._first(map, const ['summary']),
      ),
      footer: HomeDashboardOutput._readString(
        HomeDashboardOutput._first(map, const ['footer']),
      ),
      isFocus:
          HomeDashboardOutput._first(map, const ['is_focus', 'isFocus']) ==
          true,
    );
  }
}

class HomeTimelineItemOutput {
  const HomeTimelineItemOutput({
    required this.id,
    required this.itemType,
    required this.title,
    this.subtitle,
    required this.scheduledTime,
    this.endScheduledTime,
    required this.isCompleted,
    required this.isOverdue,
  });

  final String id;
  final String itemType;
  final String title;
  final String? subtitle;
  final DateTime scheduledTime;
  final DateTime? endScheduledTime;
  final bool isCompleted;
  final bool isOverdue;

  factory HomeTimelineItemOutput.fromDynamic(dynamic value) {
    final map = HomeDashboardOutput._asMap(value);
    return HomeTimelineItemOutput(
      id: HomeDashboardOutput._readString(
        HomeDashboardOutput._first(map, const ['id']),
      ),
      itemType: HomeDashboardOutput._readString(
        HomeDashboardOutput._first(map, const ['item_type', 'itemType']),
      ).toLowerCase(),
      title: HomeDashboardOutput._readString(
        HomeDashboardOutput._first(map, const ['title']),
      ),
      subtitle: _readOptionalString(
        HomeDashboardOutput._first(map, const ['subtitle']),
      ),
      scheduledTime:
          DateTime.tryParse(
            HomeDashboardOutput._readString(
              HomeDashboardOutput._first(map, const [
                'scheduled_time',
                'scheduledTime',
              ]),
            ),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endScheduledTime: DateTime.tryParse(
        HomeDashboardOutput._readString(
          HomeDashboardOutput._first(map, const [
            'end_scheduled_time',
            'endScheduledTime',
          ]),
        ),
      ),
      isCompleted:
          HomeDashboardOutput._first(map, const [
            'is_completed',
            'isCompleted',
          ]) ==
          true,
      isOverdue:
          HomeDashboardOutput._first(map, const ['is_overdue', 'isOverdue']) ==
          true,
    );
  }

  HomeTimelineItemOutput copyWith({
    bool? isCompleted,
    bool? isOverdue,
    DateTime? scheduledTime,
    DateTime? endScheduledTime,
  }) {
    return HomeTimelineItemOutput(
      id: id,
      itemType: itemType,
      title: title,
      subtitle: subtitle,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      endScheduledTime: endScheduledTime ?? this.endScheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isOverdue: isOverdue ?? this.isOverdue,
    );
  }

  static String? _readOptionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }
}

class HomeShoppingPreviewOutput {
  const HomeShoppingPreviewOutput({
    required this.id,
    required this.title,
    required this.totalItems,
    required this.pendingItems,
    required this.previewItems,
  });

  final String id;
  final String title;
  final int totalItems;
  final int pendingItems;
  final List<String> previewItems;

  factory HomeShoppingPreviewOutput.fromDynamic(dynamic value) {
    final map = HomeDashboardOutput._asMap(value);
    return HomeShoppingPreviewOutput(
      id: HomeDashboardOutput._readString(
        HomeDashboardOutput._first(map, const ['id']),
      ),
      title: HomeDashboardOutput._readString(
        HomeDashboardOutput._first(map, const ['title']),
      ),
      totalItems:
          HomeDashboardOutput._readInt(
            HomeDashboardOutput._first(map, const [
              'total_items',
              'totalItems',
            ]),
          ) ??
          0,
      pendingItems:
          HomeDashboardOutput._readInt(
            HomeDashboardOutput._first(map, const [
              'pending_items',
              'pendingItems',
            ]),
          ) ??
          0,
      previewItems: HomeDashboardOutput._asList(
        HomeDashboardOutput._first(map, const [
          'preview_items',
          'previewItems',
        ]),
      ).map((item) => item.toString()).toList(growable: false),
    );
  }
}
