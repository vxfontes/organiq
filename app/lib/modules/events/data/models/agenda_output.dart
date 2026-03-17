import 'package:organiq/modules/events/data/models/event_output.dart';
import 'package:organiq/modules/reminders/data/models/reminder_output.dart';
import 'package:organiq/modules/tasks/data/models/task_output.dart';

class AgendaOutput {
  const AgendaOutput({
    required this.events,
    required this.tasks,
    required this.reminders,
  });

  final List<EventOutput> events;
  final List<TaskOutput> tasks;
  final List<ReminderOutput> reminders;

  factory AgendaOutput.fromJson(Map<String, dynamic> json) {
    return AgendaOutput(
      events: _parseEvents(json['events']),
      tasks: _parseTasks(json['tasks']),
      reminders: _parseReminders(json['reminders']),
    );
  }

  factory AgendaOutput.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return AgendaOutput.fromJson(value);
    }
    if (value is Map) {
      return AgendaOutput.fromJson(
        value.map((key, val) => MapEntry(key.toString(), val)),
      );
    }
    return const AgendaOutput(events: [], tasks: [], reminders: []);
  }

  static List<EventOutput> _parseEvents(dynamic raw) {
    if (raw is! List) return const [];
    final list = <EventOutput>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        list.add(EventOutput.fromJson(item));
      } else if (item is Map) {
        list.add(
          EventOutput.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      }
    }
    return list;
  }

  static List<TaskOutput> _parseTasks(dynamic raw) {
    if (raw is! List) return const [];
    final list = <TaskOutput>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        list.add(TaskOutput.fromJson(item));
      } else if (item is Map) {
        list.add(
          TaskOutput.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      }
    }
    return list;
  }

  static List<ReminderOutput> _parseReminders(dynamic raw) {
    if (raw is! List) return const [];
    final list = <ReminderOutput>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        list.add(ReminderOutput.fromJson(item));
      } else if (item is Map) {
        list.add(
          ReminderOutput.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      }
    }
    return list;
  }
}
