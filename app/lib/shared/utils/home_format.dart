import 'package:flutter/material.dart';
import 'package:inbota/modules/events/data/models/event_output.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class HomeFormat {
  HomeFormat._();

  static String todayHeadline({DateTime? now}) {
    final date = (now ?? DateTime.now()).toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return 'Atualizado para $day/$month';
  }

  static String taskSubtitle(TaskOutput task, {DateTime? now}) {
    if (task.dueAt == null) return 'Sem data definida';
    return 'Prazo: ${relativeDateTimeLabel(task.dueAt, now: now)}';
  }

  static String eventSubtitle(EventOutput event) {
    final start = event.startAt?.toLocal();
    if (start == null) return 'Sem data definida';

    final day = start.day.toString().padLeft(2, '0');
    final month = start.month.toString().padLeft(2, '0');

    if (event.allDay) {
      return '$day/$month · Dia inteiro';
    }

    final startTime = formatHourMinute(start);
    final end = event.endAt?.toLocal();
    if (end == null) return '$day/$month · $startTime';

    final endTime = formatHourMinute(end);
    return '$day/$month · $startTime - $endTime';
  }

  static String eventStatus(EventOutput event, {DateTime? now}) {
    final start = event.startAt?.toLocal();
    if (start == null) return 'SEM DATA';

    final base = (now ?? DateTime.now()).toLocal();
    final today = DateTime(base.year, base.month, base.day);
    final eventDay = DateTime(start.year, start.month, start.day);
    final diff = eventDay.difference(today).inDays;

    if (diff == 0) return 'HOJE';
    if (diff == 1) return 'AMANHA';
    return 'AGENDADO';
  }

  static String relativeDateTimeLabel(DateTime? date, {DateTime? now}) {
    if (date == null) return 'Sem horario';
    final local = date.toLocal();
    final base = (now ?? DateTime.now()).toLocal();
    final today = DateTime(base.year, base.month, base.day);
    final target = DateTime(local.year, local.month, local.day);
    final diff = target.difference(today).inDays;

    final time = formatHourMinute(local);
    if (diff == 0) return 'Hoje $time';
    if (diff == 1) return 'Amanha $time';
    if (diff == -1) return 'Ontem $time';

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month $time';
  }

  static Color reminderColor(int index) {
    switch (index % 3) {
      case 0:
        return AppColors.primary700;
      case 1:
        return AppColors.warning500;
      default:
        return AppColors.success600;
    }
  }

  static String formatHourMinute(DateTime date) {
    return TextUtils.formatHourMinute(date);
  }
}
