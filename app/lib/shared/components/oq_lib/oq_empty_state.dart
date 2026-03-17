import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:organiq/shared/components/oq_lib/oq_huge_icons.dart';
import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class OQEmptyState extends StatelessWidget {
  const OQEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = OQHugeIcon.emptyInbox,
  });

  final String title;
  final String subtitle;
  final OQHugeIcon icon;

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
        OQText(title, context: context).subtitulo.build(),
        const SizedBox(height: 6),
        OQText(
          subtitle,
          context: context,
        ).muted.align(TextAlign.center).build(),
      ],
    );
  }
}
