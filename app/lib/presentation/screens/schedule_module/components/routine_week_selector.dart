import 'package:flutter/material.dart';
import 'package:inbota/presentation/screens/schedule_module/controller/schedule_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class RoutineWeekSelector extends StatelessWidget {
  const RoutineWeekSelector({
    super.key,
    required this.controller,
  });

  final ScheduleController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: controller.selectedWeekOffset,
      builder: (context, currentOffset, _) {
        return Row(
          children: [
            _buildWeekButton(context, 'Esta semana', 0, currentOffset),
            const SizedBox(width: 8),
            _buildWeekButton(context, 'Próxima semana', 1, currentOffset),
          ],
        );
      },
    );
  }

  Widget _buildWeekButton(
    BuildContext context,
    String label,
    int offset,
    int currentOffset,
  ) {
    final isSelected = currentOffset == offset;
    final bgColor = isSelected ? AppColors.primary700 : AppColors.surfaceSoft;
    final textColor = isSelected ? AppColors.surface : AppColors.text;
    final borderColor = isSelected ? AppColors.primary700 : AppColors.border;

    return Expanded(
      child: InkWell(
        onTap: () => controller.selectWeekOffset(offset),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: IBText(label, context: context)
                .label
                .color(textColor)
                .build(),
          ),
        ),
      ),
    );
  }
}
