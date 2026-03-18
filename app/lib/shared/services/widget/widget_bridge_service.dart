import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:organiq/modules/reminders/data/models/reminder_output.dart';
import 'package:organiq/modules/tasks/data/models/task_output.dart';

class WidgetBridgeService {
  WidgetBridgeService._();

  static final WidgetBridgeService instance = WidgetBridgeService._();

  static const MethodChannel _channel = MethodChannel('organiq.widget');

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  // ─── Tasks ────────────────────────────────────────────────────────────────

  Future<void> syncTasks(List<TaskOutput> tasks) async {
    if (!_isSupported) return;

    final payload = tasks
        .where((task) => task.id.trim().isNotEmpty)
        .take(8)
        .map(
          (task) => {'id': task.id, 'title': task.title, 'done': task.isDone},
        )
        .toList(growable: false);

    try {
      await _channel.invokeMethod<bool>('syncTasks', {'tasks': payload});
    } on PlatformException {
      // Silently ignore bridge failures to avoid breaking core app flows.
    }
  }

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
    } on PlatformException {
      // Silently ignore.
    }
  }

  // ─── Next Actions ─────────────────────────────────────────────────────────

  /// [items] is a list of maps with keys:
  /// id, title, type (event|reminder|routine|task),
  /// scheduledTime (ISO8601 or null), endScheduledTime (ISO8601 or null),
  /// isCompleted, isOverdue.
  Future<void> syncNextActions(List<Map<String, dynamic>> items) async {
    if (!_isSupported) return;

    try {
      await _channel.invokeMethod<void>(
        'syncNextActions',
        {'items': items.take(8).toList(growable: false)},
      );
    } on PlatformException {
      // Silently ignore.
    }
  }

  // ─── Reminders ────────────────────────────────────────────────────────────

  Future<void> syncReminders(List<ReminderOutput> reminders) async {
    if (!_isSupported) return;

    final payload = reminders
        .where((r) => !r.isDone && r.id.trim().isNotEmpty)
        .take(5)
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
    } on PlatformException {
      // Silently ignore.
    }
  }
}
