import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:inbota/shared/components/ib_lib/ib_huge_icons.dart';
import 'package:inbota/shared/components/ib_lib/ib_text.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class IBEmptyState extends StatelessWidget {
  const IBEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = IBHugeIcon.emptyInbox,
  });

  final String title;
  final String subtitle;
  final IBHugeIcon icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HugeIcon(
          icon: icon.data,
          size: 48,
          color: AppColors.primary600,
          strokeWidth: 1.8,
        ),
        const SizedBox(height: 12),
        IBText(title, context: context).subtitulo.build(),
        const SizedBox(height: 6),
        IBText(subtitle, context: context).muted.align(TextAlign.center).build(),
      ],
    );
  }
}
