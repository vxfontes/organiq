import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/ib_chip.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBChipOption<T> {
  final String label;
  final T value;

  IBChipOption({required this.label, required this.value});
}

class IBChipGroup<T> extends StatelessWidget {
  final List<IBChipOption<T>> options;
  final List<T> selectedValues;
  final Function(List<T>) onChanged;
  final bool multiSelect;

  const IBChipGroup({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.multiSelect = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValues.contains(option.value);
        final color = isSelected ? AppColors.primary700 : AppColors.textMuted;

        return IBChip(
          label: option.label,
          color: color,
          onTap: () {
            if (multiSelect) {
              final newValues = List<T>.from(selectedValues);
              if (isSelected) {
                newValues.remove(option.value);
              } else {
                newValues.add(option.value);
              }
              onChanged(newValues);
            } else {
              onChanged([option.value]);
            }
          },
        );
      }).toList(),
    );
  }
}
