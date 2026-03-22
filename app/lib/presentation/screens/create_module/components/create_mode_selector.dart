import 'package:flutter/material.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class CreateModeSelector extends StatelessWidget {
  const CreateModeSelector({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.enabled = true,
  });

  final int mode;
  final ValueChanged<int> onModeChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildModeButton(
          context,
          label: 'Organizar',
          selected: mode == 0,
          selectedColor: AppColors.primary700,
          onTap: () => onModeChanged(0),
        ),
        const SizedBox(width: 8),
        _buildModeButton(
          context,
          label: 'Sugerir',
          selected: mode == 1,
          selectedColor: AppColors.ai600,
          onTap: () => onModeChanged(1),
        ),
      ],
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required String label,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    final backgroundColor = selected ? selectedColor : AppColors.surfaceSoft;
    final borderColor = selected ? selectedColor : AppColors.border;
    final textColor = selected ? AppColors.surface : AppColors.text;

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: enabled
                ? backgroundColor
                : backgroundColor.withAlpha((0.6 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: OQText(
              label,
              context: context,
            ).label.color(textColor).build(),
          ),
        ),
      ),
    );
  }
}
