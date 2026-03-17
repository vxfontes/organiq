import 'package:organiq/modules/reminders/data/models/reminder_output.dart';
import 'package:organiq/modules/tasks/data/models/task_output.dart';

class RemindersFormat {
  RemindersFormat._();

  static String taskSubtitle(TaskOutput task) {
    if (task.dueAt == null) return 'Sem data definida';
    final date = task.dueAt!.toLocal();
    return 'Prazo: ${formatDate(date)}';
  }

  static String formatReminderTime(ReminderOutput reminder) {
    final date = reminder.remindAt?.toLocal();
    if (date == null) return 'Sem data';

    final now = DateTime.now();
    if (isSameDay(date, now)) {
      return 'Hoje ${formatHour(date)}';
    }
    if (isSameDay(date, now.add(const Duration(days: 1)))) {
      return 'Amanhã ${formatHour(date)}';
    }
    return '${formatDate(date)} ${formatHour(date)}';
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  static String formatHour(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isAfterDay(DateTime a, DateTime b) {
    if (isSameDay(a, b)) return false;
    return a.isAfter(DateTime(b.year, b.month, b.day, 23, 59, 59));
  }
}
