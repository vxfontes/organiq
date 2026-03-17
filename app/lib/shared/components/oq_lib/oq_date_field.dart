import 'package:flutter/material.dart';

import 'package:organiq/shared/components/oq_lib/oq_icon.dart';
import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class OQDateField extends StatelessWidget {
  const OQDateField({
    super.key,
    required this.valueLabel,
    required this.enabled,
    required this.hasValue,
    required this.onTap,
    this.onClear,
    this.label = 'Data',
  });

  final String valueLabel;
  final bool enabled;
  final bool hasValue;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final String label;

  static Future<DateTime?> pickDateTime(
    BuildContext context, {
    DateTime? current,
    String helpText = 'Selecionar data',
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateTime.now();
    final initial = current ?? now;
    final startDate = firstDate ?? DateTime(now.year, now.month, now.day);
    final endDate = lastDate ?? DateTime(now.year + 5, 12, 31);
    final pickerTheme = _buildPickerTheme(context);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: startDate,
      lastDate: endDate,
      helpText: helpText,
      builder: (dialogContext, child) {
        return Theme(
          data: pickerTheme,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedDate == null) return current;
    if (!context.mounted) return current;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (dialogContext, child) {
        return Theme(
          data: pickerTheme,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    final resolvedTime = pickedTime ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      resolvedTime.hour,
      resolvedTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentColor = enabled ? AppColors.text : AppColors.textMuted;
    final iconColor = enabled ? AppColors.primary600 : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
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
            OQIcon(OQIcon.eventAvailableOutlined, color: iconColor, size: 20),
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
            if (hasValue && onClear != null)
              IconButton(
                tooltip: 'Limpar data',
                onPressed: enabled ? onClear : null,
                icon: const OQIcon(
                  OQIcon.closeRounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                splashRadius: 18,
              )
            else
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

    final dayForeground = WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.textMuted.withAlpha((0.35 * 255).round());
      }
      if (states.contains(WidgetState.selected)) {
        return AppColors.surface;
      }
      return AppColors.text;
    });

    final dayBackground = WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary700;
      }
      return AppColors.transparent;
    });

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary700,
        onPrimary: AppColors.surface,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        onSurfaceVariant: AppColors.textMuted,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary700),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        headerBackgroundColor: AppColors.surface,
        headerForegroundColor: AppColors.text,
        headerHeadlineStyle: const TextStyle(
          color: AppColors.text,
          fontSize: 34,
          fontWeight: FontWeight.w500,
        ),
        headerHelpStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        weekdayStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        dayStyle: const TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dayForegroundColor: dayForeground,
        dayBackgroundColor: dayBackground,
        todayForegroundColor: const WidgetStatePropertyAll<Color>(
          AppColors.text,
        ),
        todayBorder: const BorderSide(color: AppColors.primary700),
        yearStyle: const TextStyle(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        yearForegroundColor: const WidgetStatePropertyAll<Color>(
          AppColors.text,
        ),
        dividerColor: AppColors.border,
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
        hourMinuteTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        dayPeriodTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        helpTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        entryModeIconColor: AppColors.primary700,
      ),
    );
  }
}
