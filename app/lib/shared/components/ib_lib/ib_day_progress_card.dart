import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBDayProgressCard extends StatelessWidget {
  const IBDayProgressCard({
    super.key,
    required this.progressPercent,
    required this.routinesDone,
    required this.routinesTotal,
    required this.tasksDone,
    required this.tasksTotal,
    required this.remindersDone,
    required this.remindersTotal,
  });

  final double progressPercent;
  final int routinesDone;
  final int routinesTotal;
  final int tasksDone;
  final int tasksTotal;
  final int remindersDone;
  final int remindersTotal;

  @override
  Widget build(BuildContext context) {
    final overallDone = routinesDone + tasksDone + remindersDone;
    final overallTotal = routinesTotal + tasksTotal + remindersTotal;
    final safeProgress = overallTotal == 0
        ? progressPercent.clamp(0.0, 1.0).toDouble()
        : (overallDone / overallTotal).clamp(0.0, 1.0).toDouble();
    const progressColor = AppColors.primary600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AnimatedProgressRing(
                progress: safeProgress,
                color: progressColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IBText('Hoje', context: context).subtitulo.build(),
                    const SizedBox(height: 2),
                    IBText(
                      '${(safeProgress * 100).round()}%',
                      context: context,
                    ).titulo.color(progressColor).build(),
                    const SizedBox(height: 2),
                    IBText(
                      '$overallDone de $overallTotal concluidos',
                      context: context,
                    ).caption.build(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CategoryProgressLine(
            label: 'Rotinas',
            done: routinesDone,
            total: routinesTotal,
            color: AppColors.primary600,
          ),
          const SizedBox(height: 8),
          _CategoryProgressLine(
            label: 'Tarefas',
            done: tasksDone,
            total: tasksTotal,
            color: AppColors.ai500,
          ),
          const SizedBox(height: 8),
          _CategoryProgressLine(
            label: 'Lembretes',
            done: remindersDone,
            total: remindersTotal,
            color: AppColors.warning500,
          ),
        ],
      ),
    );
  }
}

class _AnimatedProgressRing extends StatelessWidget {
  const _AnimatedProgressRing({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 60,
        height: 60,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) {
            return Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 8,
                    color: AppColors.border,
                  ),
                ),
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    color: color,
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Center(
                    child: IBText('${(value * 100).round()}%', context: context)
                        .label
                        .weight(FontWeight.w700)
                        .color(AppColors.text)
                        .build(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryProgressLine extends StatelessWidget {
  const _CategoryProgressLine({
    required this.label,
    required this.done,
    required this.total,
    required this.color,
  });

  final String label;
  final int done;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0
        ? 0.0
        : (done / total).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IBText(label, context: context).caption.build(),
            IBText(
              '$done/$total',
              context: context,
            ).caption.color(color).build(),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress,
            backgroundColor: AppColors.surface2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
