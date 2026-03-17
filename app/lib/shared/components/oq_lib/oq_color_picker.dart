import 'package:flutter/material.dart';

import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class OQColorPicker extends StatelessWidget {
  final String? selectedColor;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final String label;
  final String noneLabel;
  final List<String> palette;

  const OQColorPicker({
    super.key,
    required this.selectedColor,
    this.onChanged,
    this.enabled = true,
    this.label = 'Cor',
    this.noneLabel = 'Sem cor',
    this.palette = defaultPalette,
  });

  static const List<String> defaultPalette = [
    '#0F766E',
    '#0D9488',
    '#14B8A6',
    '#059669',
    '#16A34A',
    '#65A30D',
    '#CA8A04',
    '#D97706',
    '#EA580C',
    '#DC2626',
    '#E11D48',
    '#DB2777',
    '#9333EA',
    '#7C3AED',
    '#4F46E5',
    '#2563EB',
    '#0284C7',
    '#0891B2',
    '#0369A1',
    '#475569',
  ];

  static String? normalizeHex(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    var hex = value.toUpperCase().replaceAll('#', '');
    if (hex.length == 3) {
      hex = hex.split('').map((char) => '$char$char').join();
    }
    if (hex.length == 8) {
      hex = hex.substring(2);
    }
    if (hex.length != 6) return null;
    if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(hex)) return null;
    return '#$hex';
  }

  @override
  Widget build(BuildContext context) {
    final normalizedSelected = normalizeHex(selectedColor);
    final selectedLabel = normalizedSelected ?? noneLabel;

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
          Row(
            children: [
              OQText(label, context: context).caption.build(),
              const Spacer(),
              _ColorPreview(
                colorHex: normalizedSelected,
                noneLabel: noneLabel,
                valueLabel: selectedLabel,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ColorOption(
                selected: normalizedSelected == null,
                enabled: enabled,
                onTap: onChanged == null ? null : () => onChanged!(null),
                child: const Icon(
                  Icons.block_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
              ...palette
                  .map(normalizeHex)
                  .whereType<String>()
                  .map(
                    (hex) => _ColorOption(
                      selected: normalizedSelected == hex,
                      enabled: enabled,
                      onTap: onChanged == null ? null : () => onChanged!(hex),
                      color: _parseHex(hex),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _parseHex(String hex) {
    final normalized = hex.replaceAll('#', '');
    final value = int.tryParse('FF$normalized', radix: 16);
    if (value == null) return AppColors.primary600;
    return Color(value);
  }
}

class _ColorPreview extends StatelessWidget {
  const _ColorPreview({
    required this.colorHex,
    required this.noneLabel,
    required this.valueLabel,
  });

  final String? colorHex;
  final String noneLabel;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    final hasColor = colorHex != null;

    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasColor
                ? OQColorPicker._parseHex(colorHex!)
                : AppColors.surface,
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: hasColor
              ? null
              : const Icon(
                  Icons.close_rounded,
                  size: 10,
                  color: AppColors.textMuted,
                ),
        ),
        const SizedBox(width: 6),
        OQText(
          valueLabel == noneLabel ? noneLabel : valueLabel,
          context: context,
        ).caption.color(AppColors.textMuted).build(),
      ],
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.color,
    this.child,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.surface;
    final foreground = resolvedColor.computeLuminance() > 0.58
        ? AppColors.text
        : AppColors.surface;

    return InkWell(
      onTap: !enabled ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: resolvedColor,
            border: Border.all(
              color: selected ? AppColors.text : AppColors.surface,
              width: selected ? 2.6 : 1.5,
            ),
            boxShadow: selected && color != null
                ? [
                    BoxShadow(
                      color: resolvedColor.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: selected
              ? Icon(Icons.check_rounded, size: 16, color: foreground)
              : child,
        ),
      ),
    );
  }
}
