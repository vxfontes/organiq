import 'package:flutter/material.dart';

import 'package:organiq/modules/tasks/data/models/task_output.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';
import 'package:organiq/shared/utils/date_time.dart';
import 'package:organiq/shared/utils/text_utils.dart';

class HomeFocusList extends StatelessWidget {
  const HomeFocusList({
    super.key,
    required this.tasks,
    required this.onSeeAllTap,
    this.onToggleTask,
  });

  final List<TaskOutput> tasks;
  final VoidCallback onSeeAllTap;
  final void Function(int index, bool done)? onToggleTask;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OQTodoList(
          title: 'Foco e prioridades',
          subtitle: TextUtils.countLabel(
            tasks.length,
            'tarefa priorizada',
            'tarefas priorizadas',
          ),
          emptyLabel: 'Nenhuma tarefa pendente.',
          items: tasks
              .map(
                (task) => OQTodoItemData(
                  id: task.id,
                  title: task.title,
                  subtitle: _subtitleFor(task),
                  subtitleTagLabel: _normalize(task.subflagName),
                  subtitleTagColor: _parseHexColor(
                    task.subflagColor ?? task.flagColor,
                    fallback: AppColors.ai600,
                  ),
                  done: task.isDone,
                  isOverdue: _isOverdue(task),
                ),
              )
              .toList(growable: false),
          onToggle: onToggleTask,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onSeeAllTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary700,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OQText(
                'Ver todas as tarefas',
                context: context,
              ).label.color(AppColors.primary700).build(),
              const SizedBox(width: 4),
              const OQIcon(
                OQIcon.chevronRight,
                size: 16,
                color: AppColors.primary700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isOverdue(TaskOutput task) {
    final due = task.dueAt?.toLocal();
    if (due == null) return false;

    final todayStart = _startOfDay(DateTimeUtils.nowInUserTimezone());
    return due.isBefore(todayStart);
  }

  String _subtitleFor(TaskOutput task) {
    final due = task.dueAt?.toLocal();
    if (due == null) return 'Sem data definida';

    final now = DateTimeUtils.nowInUserTimezone();
    final todayStart = _startOfDay(now);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    if (due.isBefore(todayStart)) {
      final days = todayStart.difference(_startOfDay(due)).inDays;
      if (days <= 1) return 'Venceu ha 1 dia';
      return 'Venceu ha $days dias';
    }

    if (!due.isBefore(todayStart) && due.isBefore(tomorrowStart)) {
      return 'Hoje';
    }

    final dd = due.day.toString().padLeft(2, '0');
    final mm = due.month.toString().padLeft(2, '0');
    return 'Prazo: $dd/$mm';
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String? _normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  Color _parseHexColor(String? value, {required Color fallback}) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return fallback;

    var hex = raw.toUpperCase().replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return fallback;

    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }
}
