import 'package:flutter/material.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/date_time.dart';

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
    return 'Prazo: ${DateTimeUtils.relativeDateTimeLabel(task.dueAt, now: now)}';
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

}
