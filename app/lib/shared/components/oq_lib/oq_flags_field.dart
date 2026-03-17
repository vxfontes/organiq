import 'package:flutter/material.dart';

import 'package:organiq/shared/components/oq_lib/oq_chip.dart';
import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class OQFlagsFieldOption {
  const OQFlagsFieldOption({required this.id, required this.label, this.color});

  final String id;
  final String label;
  final String? color;
}

class OQFlagsField extends StatelessWidget {
  const OQFlagsField({
    super.key,
    required this.options,
    this.selectedId,
    this.onChanged,
    this.enabled = true,
    this.label = 'Flag',
    this.emptyLabel = 'Nenhuma flag disponivel',
  });

  final List<OQFlagsFieldOption> options;
  final String? selectedId;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final String label;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OQText(label, context: context).caption.build(),
          const SizedBox(height: 8),
          if (options.isEmpty)
            OQText(emptyLabel, context: context).muted.build()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: !enabled || onChanged == null
                        ? null
                        : () {
                            final selected = selectedId == option.id;
                            onChanged!(selected ? null : option.id);
                          },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: !enabled
                          ? 0.5
                          : selectedId == option.id
                          ? 1
                          : 0.55,
                      child: OQChip(
                        label: option.label,
                        color: _parseFlagColor(option.color),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Color _parseFlagColor(String? rawColor) {
    const fallback = AppColors.primary600;
    if (rawColor == null || rawColor.trim().isEmpty) return fallback;

    var hex = rawColor.trim().replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) return fallback;

    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }
}
