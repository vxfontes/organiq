import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:organiq/modules/reminders/data/models/reminder_output.dart';
import 'package:organiq/modules/tasks/data/models/task_output.dart';

/// Widget limits for iOS home screen widgets.
class _WidgetLimits {
  static const tasks = 10;
  static const nextActions = 8;
  static const reminders = 5;
}

/// Bridge service for syncing data to iOS home screen widgets.
///
/// This service communicates with native iOS widgets via MethodChannel,
/// storing data in a shared UserDefaults container (App Group).
///
/// All methods gracefully fail on non-iOS platforms or when bridge is unavailable.
class WidgetBridgeService {
  WidgetBridgeService._();

  static final WidgetBridgeService instance = WidgetBridgeService._();

  static const MethodChannel _channel = MethodChannel('organiq.widget');

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  // ─── Tasks ────────────────────────────────────────────────────────────────

  /// Syncs tasks to iOS widgets.
  ///
  /// Only incomplete tasks are sent, ordered by priority (overdue → today → future).
  /// Maximum of [_WidgetLimits.tasks] tasks are kept in the widget store.
  ///
  /// Called automatically by [HomeController] after data refresh.
  Future<void> syncTasks(List<TaskOutput> tasks) async {
    if (!_isSupported) return;

    final now = DateTime.now().toLocal();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    int priority(TaskOutput task) {
      final due = task.dueAt?.toLocal();
      if (due == null) return 2; // sem data
      if (!due.isBefore(todayStart) && due.isBefore(tomorrowStart)) return 0; // hoje
      if (due.isBefore(todayStart)) return 1; // atrasada
      return 3; // futura com data
    }

    final ordered = tasks
        .where(
          (task) =>
              task.id.trim().isNotEmpty &&
              task.title.trim().isNotEmpty &&
              !task.isDone,
        )
        .toList(growable: false)
      ..sort((a, b) {
        final byPriority = priority(a).compareTo(priority(b));
        if (byPriority != 0) return byPriority;

        final aDue = a.dueAt?.toLocal();
        final bDue = b.dueAt?.toLocal();
        if (aDue == null && bDue == null) {
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        }
        if (aDue == null) return 1;
        if (bDue == null) return -1;

        final byDate = aDue.compareTo(bDue);
        if (byDate != 0) return byDate;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

    final payload = ordered
        .take(_WidgetLimits.tasks)
        .map(
          (task) => <String, dynamic>{
            'id': task.id,
            'title': task.title,
            'done': task.isDone,
            'dueAt': task.dueAt?.toUtc().toIso8601String(),
            'flagName': task.subflagName ?? task.flagName,
            'flagColor': task.subflagColor ?? task.flagColor,
          },
        )
        .toList(growable: false);

    try {
      await _channel.invokeMethod<bool>('syncTasks', {'tasks': payload});
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('WidgetBridge.syncTasks failed: ${e.code} ${e.message}');
      }
    }
  }

  /// Consumes and clears the list of task IDs completed via widgets.
  ///
  /// Returns a list of task IDs that were marked as done in iOS widgets
  /// since the last call. The native side clears the list after returning.
  ///
  /// Should be called when the app resumes or after syncing tasks.
  Future<List<String>> consumeCompletedTaskIds() async {
    if (!_isSupported) return const <String>[];

    try {
      final raw = await _channel.invokeListMethod<dynamic>(
        'consumeCompletedTaskIds',
      );

      if (raw == null) return const <String>[];

      return raw
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
    } on PlatformException {
      return const <String>[];
    }
  }

  // ─── Day Progress ─────────────────────────────────────────────────────────

  /// Syncs daily progress metrics to iOS widgets.
  ///
  /// Sends aggregated completion stats for tasks, routines, and reminders.
  /// The [percent] value should be between 0.0 and 1.0.
  Future<void> syncDayProgress({
    required double percent,
    required int tasksDone,
    required int tasksTotal,
    required int routinesDone,
    required int routinesTotal,
    required int remindersDone,
    required int remindersTotal,
  }) async {
    if (!_isSupported) return;

    try {
      await _channel.invokeMethod<void>('syncDayProgress', {
        'percent': percent,
        'tasksDone': tasksDone,
        'tasksTotal': tasksTotal,
        'routinesDone': routinesDone,
        'routinesTotal': routinesTotal,
        'remindersDone': remindersDone,
        'remindersTotal': remindersTotal,
      });
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('WidgetBridge.syncDayProgress failed: ${e.code} ${e.message}');
      }
    }
  }

  // ─── Next Actions ─────────────────────────────────────────────────────────

  /// Syncs upcoming timeline items to iOS widgets.
  ///
  /// [items] should contain maps with keys:
  /// - id, title, type (event|reminder|routine|task)
  /// - scheduledTime (ISO8601 or null), endScheduledTime (ISO8601 or null)
  /// - isCompleted, isOverdue
  /// - subtitle (optional), accentColor (optional)
  ///
  /// Maximum of [_WidgetLimits.nextActions] items are sent.
  Future<void> syncNextActions(List<Map<String, dynamic>> items) async {
    if (!_isSupported) return;

    try {
      await _channel.invokeMethod<void>(
        'syncNextActions',
        {'items': items.take(_WidgetLimits.nextActions).toList(growable: false)},
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('WidgetBridge.syncNextActions failed: ${e.code} ${e.message}');
      }
    }
  }

  // ─── Reminders ────────────────────────────────────────────────────────────

  /// Syncs upcoming reminders to iOS widgets.
  ///
  /// Only incomplete reminders are sent.
  /// Maximum of [_WidgetLimits.reminders] reminders are kept.
  Future<void> syncReminders(List<ReminderOutput> reminders) async {
    if (!_isSupported) return;

    final payload = reminders
        .where((r) => !r.isDone && r.id.trim().isNotEmpty)
        .take(_WidgetLimits.reminders)
        .map(
          (r) => {
            'id': r.id,
            'title': r.title,
            'remindAt': r.remindAt?.toUtc().toIso8601String(),
          },
        )
        .toList(growable: false);

    try {
      await _channel.invokeMethod<void>(
        'syncReminders',
        {'reminders': payload},
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('WidgetBridge.syncReminders failed: ${e.code} ${e.message}');
      }
    }
  }

  /// Helper to validate non-empty trimmed strings.
  bool _isValidId(String? value) =>
      value?.trim().isNotEmpty ?? false;
}
