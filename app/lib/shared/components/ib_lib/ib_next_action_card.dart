import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/ib_chip.dart';
import 'package:inbota/shared/components/ib_lib/ib_icon.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class IBNextActionItem {
  const IBNextActionItem({
    required this.id,
    required this.title,
    required this.type,
    required this.scheduledTime,
    this.endScheduledTime,
    this.subtitle,
    this.isCompleted = false,
    this.isOverdue = false,
  });

  final String id;
  final String title;
  final String? subtitle;
  final IBNextActionType type;
  final DateTime scheduledTime;
  final DateTime? endScheduledTime;
  final bool isCompleted;
  final bool isOverdue;
}

enum IBNextActionType { event, reminder, routine, task }

class IBNextActionCard extends StatelessWidget {
  const IBNextActionCard({
    super.key,
    required this.item,
    required this.onComplete,
    this.isPast = false,
    this.width = 150,
    this.height = 138,
  });

  final IBNextActionItem item;
  final VoidCallback? onComplete;
  final bool isPast;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(item.type);
    final completionColor = item.type == IBNextActionType.reminder
        ? AppColors.warning600
        : AppColors.primary700;
    final doneColor = item.type == IBNextActionType.reminder
        ? AppColors.warning600
        : AppColors.success600;
    final showCompleteButton =
        onComplete != null &&
        item.type != IBNextActionType.event &&
        !isPast &&
        !item.isCompleted;

    return Opacity(
      opacity: isPast ? 0.5 : 1,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.accent.withValues(alpha: 0.22)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight <= 150;
            final subtitle = item.subtitle?.trim();
            final showSubtitle =
                subtitle != null && subtitle.isNotEmpty && !compact;
            final showOverdueBadge =
                item.isOverdue && !item.isCompleted && !compact;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IBIcon(palette.icon, size: 16, color: palette.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child:
                          IBText(
                                _formatTimeLabel(
                                  item.scheduledTime,
                                  end: item.endScheduledTime,
                                ),
                                context: context,
                              ).label
                              .weight(FontWeight.w700)
                              .color(AppColors.text)
                              .maxLines(1)
                              .build(),
                    ),
                    if (showOverdueBadge) const _OverdueBadge(),
                  ],
                ),
                if (compact) ...[
                  const SizedBox(height: 6),
                  IBText(
                    item.title,
                    context: context,
                  ).body.weight(FontWeight.w700).maxLines(2).build(),
                  const Spacer(),
                ] else ...[
                  const SizedBox(height: 8),
                  IBChip(label: palette.label, color: palette.accent),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IBText(
                          item.title,
                          context: context,
                        ).body.weight(FontWeight.w700).maxLines(1).build(),
                        if (showSubtitle) ...[
                          const SizedBox(height: 2),
                          IBText(
                            subtitle,
                            context: context,
                          ).caption.maxLines(1).build(),
                        ],
                      ],
                    ),
                  ),
                ],
                SizedBox(height: compact ? 6 : 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: showCompleteButton
                      ? _CompleteButton(
                          key: ValueKey('complete-${item.id}'),
                          onPressed: onComplete,
                          color: completionColor,
                        )
                      : _DoneState(
                          key: ValueKey('done-${item.id}'),
                          isDone: item.isCompleted,
                          color: doneColor,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTimeLabel(DateTime start, {DateTime? end}) {
    return TextUtils.formatHourRange(start, end: end);
  }

  _ActionPalette _paletteFor(IBNextActionType type) {
    switch (type) {
      case IBNextActionType.routine:
        return const _ActionPalette(
          background: AppColors.primary50,
          accent: AppColors.primary700,
          icon: IBIcon.repeatRounded,
          label: 'ROTINA',
        );
      case IBNextActionType.reminder:
        return const _ActionPalette(
          background: Color(0xFFFFFBEB),
          accent: AppColors.warning500,
          icon: IBIcon.alarmOutlined,
          label: 'LEMBRETE',
        );
      case IBNextActionType.event:
        return const _ActionPalette(
          background: Color(0xFFF0FDF4),
          accent: AppColors.success600,
          icon: IBIcon.calendar,
          label: 'EVENTO',
        );
      case IBNextActionType.task:
        return const _ActionPalette(
          background: AppColors.surface2,
          accent: AppColors.text,
          icon: IBIcon.taskAltRounded,
          label: 'TAREFA',
        );
    }
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({super.key, this.onPressed, required this.color});

  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            color: color.withValues(alpha: 0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IBIcon(IBIcon.checkRounded, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: IBText(
                  'Concluir',
                  context: context,
                ).label.color(color).maxLines(1).build(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneState extends StatelessWidget {
  const _DoneState({super.key, required this.isDone, required this.color});

  final bool isDone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!isDone) {
      return const SizedBox(height: 30);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IBIcon(IBIcon.checkCircleOutlineRounded, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: IBText(
              'Concluido',
              context: context,
            ).label.color(color).maxLines(1).build(),
          ),
        ],
      ),
    );
  }
}

class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger600.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.danger600.withValues(alpha: 0.28)),
      ),
      child: IBText(
        'Atras.',
        context: context,
      ).caption.color(AppColors.danger600).build(),
    );
  }
}

class _ActionPalette {
  const _ActionPalette({
    required this.background,
    required this.accent,
    required this.icon,
    required this.label,
  });

  final Color background;
  final Color accent;
  final IconData icon;
  final String label;
}
