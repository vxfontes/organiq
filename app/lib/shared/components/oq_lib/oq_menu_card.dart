import 'package:flutter/material.dart';

import 'package:organiq/shared/components/oq_lib/oq_icon.dart';
import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class OQMenuItem {
  const OQMenuItem({
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
}

class OQMenuCard extends StatelessWidget {
  const OQMenuCard({super.key, required this.items});

  final List<OQMenuItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withAlpha((0.05 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isLast = index == items.length - 1;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OQMenuRow(item: item),
                if (!isLast)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _OQMenuRow extends StatelessWidget {
  const _OQMenuRow({required this.item});

  final OQMenuItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: OQIcon(
                item.icon,
                color: item.iconColor ?? AppColors.primary600,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OQText(item.title, context: context).subtitulo.build(),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 4),
                    OQText(
                      item.subtitle!,
                      context: context,
                    ).caption.color(AppColors.textMuted).build(),
                  ],
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
              ),
              child: const OQIcon(
                OQIcon.chevronRight,
                color: AppColors.primary600,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
