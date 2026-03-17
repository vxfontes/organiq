import 'package:flutter/material.dart';

import 'package:organiq/shared/components/oq_lib/oq_icon.dart';
import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class OQTimeField extends StatelessWidget {
  const OQTimeField({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.enabled,
    required this.hasValue,
    required this.onTap,
  });

  final String label;
  final String valueLabel;
  final bool enabled;
  final bool hasValue;
  final VoidCallback? onTap;

  static Future<TimeOfDay?> pickTime(
    BuildContext context, {
    TimeOfDay? initialTime,
    String helpText = 'Selecionar horário',
  }) async {
    final pickerTheme = _buildPickerTheme(context);

    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      helpText: helpText,
      builder: (dialogContext, child) {
        return Theme(
          data: pickerTheme,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentColor = enabled && hasValue
        ? AppColors.text
        : AppColors.textMuted;
    final iconColor = enabled ? AppColors.primary600 : AppColors.textMuted;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            OQIcon(OQIcon.alarmOutlined, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OQText(label, context: context).caption.build(),
                  const SizedBox(height: 2),
                  OQText(
                    valueLabel,
                    context: context,
                  ).body.color(contentColor).build(),
                ],
              ),
            ),
            const OQIcon(
              OQIcon.chevronRight,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  static ThemeData _buildPickerTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary700,
        onPrimary: AppColors.surface,
        surface: AppColors.surface,
        onSurface: AppColors.text,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.surface,
        dialBackgroundColor: AppColors.surface2,
        dialTextColor: AppColors.text,
        dialHandColor: AppColors.primary700,
        hourMinuteColor: AppColors.surface2,
        dayPeriodColor: AppColors.surface2,
        hourMinuteTextColor: AppColors.text,
        dayPeriodTextColor: AppColors.text,
      ),
    );
  }
}
