import 'package:flutter/material.dart';

import 'package:organiq/shared/components/ib_lib/ib_icon.dart';
import 'package:organiq/shared/components/ib_lib/ib_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class IBStatCard extends StatelessWidget {
  const IBStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withAlpha((0.04 * 255).round()),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.12 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: IBIcon(icon!, color: color, size: 18),
                ),
              if (icon != null) const SizedBox(width: 10),
              Expanded(
                child: IBText(title, context: context).caption.build(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          IBText(value, context: context).subtitulo.build(),
          const SizedBox(height: 4),
          IBText(subtitle, context: context).caption.build(),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withAlpha((0.45 * 255).round()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
