import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBChipOption<T> {
  final String label;
  final T value;

  const IBChipOption({required this.label, required this.value});
}

class IBChipGroup<T> extends StatelessWidget {
  final List<IBChipOption<T>> options;
  final List<T> selectedValues;
  final ValueChanged<List<T>> onChanged;
  final bool multiSelect;
  final bool enabled;
  final double spacing;
  final double runSpacing;

  const IBChipGroup({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.multiSelect = true,
    this.enabled = true,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: options.map((option) {
          final isSelected = selectedValues.contains(option.value);
          final textColor = isSelected
              ? AppColors.primary700
              : AppColors.textMuted;

          return Semantics(
            button: true,
            selected: isSelected,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: enabled
                    ? () {
                        if (multiSelect) {
                          final newValues = List<T>.from(selectedValues);
                          if (isSelected) {
                            newValues.remove(option.value);
                          } else {
                            newValues.add(option.value);
                          }
                          onChanged(newValues);
                          return;
                        }

                        if (!isSelected) {
                          onChanged([option.value]);
                        }
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary50
                        : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary600
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.primary700,
                        ),
                        const SizedBox(width: 6),
                      ],
                      IBText(
                        option.label,
                        context: context,
                      ).label.color(textColor).build(),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
