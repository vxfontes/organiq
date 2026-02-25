import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:inbota/modules/tasks/data/models/task_output.dart';

class WidgetBridgeService {
  WidgetBridgeService._();

  static final WidgetBridgeService instance = WidgetBridgeService._();

  static const MethodChannel _channel = MethodChannel('inbota.widget');

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

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
}
