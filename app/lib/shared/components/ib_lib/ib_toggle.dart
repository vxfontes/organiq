import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBToggle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final EdgeInsetsGeometry padding;

  const IBToggle({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    required this.value,
    this.enabled = true,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final canInteract = enabled;
    final titleColor = canInteract ? AppColors.text : AppColors.textMuted;
    final subtitleColor = canInteract
        ? AppColors.textMuted
        : AppColors.textMuted.withValues(alpha: 0.9);

    return Opacity(
      opacity: canInteract ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canInteract ? () => onChanged(!value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: padding,
            decoration: BoxDecoration(
              color: value ? AppColors.surface : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: value ? AppColors.primary600 : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: value ? AppColors.primary50 : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: value ? AppColors.primary600 : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      leadingIcon,
                      size: 18,
                      color: value ? AppColors.primary700 : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IBText(
                        title,
                        context: context,
                      ).body.color(titleColor).build(),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        IBText(
                          subtitle!,
                          context: context,
                        ).caption.color(subtitleColor).build(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch.adaptive(
                  value: value,
                  onChanged: canInteract ? onChanged : null,
                  activeThumbColor: AppColors.primary700,
                  activeTrackColor: AppColors.primary200,
                  inactiveTrackColor: AppColors.borderStrong,
                  inactiveThumbColor: AppColors.surface,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
