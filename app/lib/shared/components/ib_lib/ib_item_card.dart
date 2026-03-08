import 'package:flutter/material.dart';

import 'package:inbota/shared/components/ib_lib/ib_icon.dart';
import 'package:inbota/shared/components/ib_lib/ib_tag_chip.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBItemCard extends StatelessWidget {
  const IBItemCard({
    super.key,
    required this.title,
    required this.typeLabel,
    required this.typeColor,
    required this.typeIcon,
    required this.timeLabel,
    this.secondary,
    this.done = false,
    this.doneLabel = 'Feito',
    this.timeIcon,
    this.footer,
    this.onToggle,
  });

  final String title;
  final String? secondary;
  final bool done;
  final String doneLabel;
  final String typeLabel;
  final Color typeColor;
  final IconData typeIcon;
  final String timeLabel;
  final IconData? timeIcon;
  final Widget? footer;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    IBIcon(typeIcon, color: typeColor, size: 18),
                    const SizedBox(width: 6),
                    IBTagChip(label: typeLabel, color: typeColor),
                    if (done) ...[
                      const SizedBox(width: 6),
                      IBTagChip(label: doneLabel, color: AppColors.success600),
                    ],
                  ],
                ),
              ),
              if (onToggle != null)
                GestureDetector(
                  onTap: () => onToggle!(!done),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.primary600 : Colors.transparent,
                      border: Border.all(
                        color: done ? AppColors.primary600 : AppColors.borderStrong,
                        width: 2,
                      ),
                    ),
                    child: done
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.surface,
                          )
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: done ? AppColors.textMuted : AppColors.text,
              decoration: done
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (secondary != null && secondary!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            IBText(secondary!, context: context).muted.maxLines(2).build(),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              IBIcon(
                timeIcon ?? IBIcon.alarmOutlined,
                size: 16,
                color: AppColors.primary600,
              ),
              const SizedBox(width: 6),
              IBText(
                timeLabel,
                context: context,
              ).caption.color(AppColors.primary700).build(),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 10), footer!],
        ],
      ),
    );
  }
}
