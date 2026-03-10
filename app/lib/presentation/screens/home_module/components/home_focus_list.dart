import 'package:flutter/material.dart';

import 'package:inbota/modules/tasks/data/models/task_output.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/text_utils.dart';

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
        IBTodoList(
          title: 'Foco e prioridades',
          subtitle: TextUtils.countLabel(
            tasks.length,
            'tarefa priorizada',
            'tarefas priorizadas',
          ),
          emptyLabel: 'Nenhuma tarefa pendente.',
          items: tasks
              .map(
                (task) => IBTodoItemData(
                  id: task.id,
                  title: task.title,
                  subtitle: _subtitleFor(task),
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
              IBText(
                'Ver todas as tarefas',
                context: context,
              ).label.color(AppColors.primary700).build(),
              const SizedBox(width: 4),
              const IBIcon(
                IBIcon.chevronRight,
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

    final todayStart = _startOfDay(DateTime.now());
    return due.isBefore(todayStart);
  }

  String _subtitleFor(TaskOutput task) {
    final due = task.dueAt?.toLocal();
    if (due == null) return 'Sem data definida';

    final now = DateTime.now();
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
}
