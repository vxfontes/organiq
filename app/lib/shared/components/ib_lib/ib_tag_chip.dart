import 'package:flutter/material.dart';

import 'package:organiq/shared/components/ib_lib/ib_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class IBTagChip extends StatelessWidget {
  const IBTagChip({
    super.key,
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withAlpha((0.08 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withAlpha((0.2 * 255).round())),
      ),
      child: IBText(label, context: context)
          .caption
          .color(baseColor)
          .build(),
    );
  }
}
