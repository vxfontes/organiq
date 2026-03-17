import 'package:flutter/material.dart';

import 'package:organiq/shared/components/ib_lib/ib_chip.dart';
import 'package:organiq/shared/components/ib_lib/ib_tag_chip.dart';
import 'package:organiq/shared/components/ib_lib/ib_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class IBInboxItemCard extends StatelessWidget {
  const IBInboxItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.tags,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: IBText(title, context: context).subtitulo.build(),
              ),
              IBChip(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          IBText(subtitle, context: context).caption.build(),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags) IBTagChip(label: tag),
            ],
          ),
        ],
      ),
    );
  }
}
