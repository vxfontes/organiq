import 'package:flutter/material.dart';
import 'package:organiq/modules/inbox/data/models/create_processing_line.dart';
import 'package:organiq/shared/components/ib_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class CreateProcessingLineItem extends StatelessWidget {
  const CreateProcessingLineItem({super.key, required this.line});

  final CreateProcessingLine line;

  @override
  Widget build(BuildContext context) {
    final statusIcon = _buildStatusIcon(line.status);
    final textColor = switch (line.status) {
      LineProcessingStatus.pending => AppColors.textMuted,
      LineProcessingStatus.processing => AppColors.text,
      LineProcessingStatus.done => AppColors.text,
      LineProcessingStatus.failed => AppColors.danger600,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: statusIcon),
        const SizedBox(width: 8),
        Expanded(
          child: IBText(
            line.text,
            context: context,
          ).caption.color(textColor).build(),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(LineProcessingStatus status) {
    switch (status) {
      case LineProcessingStatus.pending:
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textMuted, width: 1.6),
          ),
        );
      case LineProcessingStatus.processing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.ai600,
          ),
        );
      case LineProcessingStatus.done:
        return const IBIcon(
          IBIcon.checkRounded,
          color: AppColors.success600,
          size: 16,
        );
      case LineProcessingStatus.failed:
        return const IBIcon(
          IBIcon.closeRounded,
          color: AppColors.danger600,
          size: 16,
        );
    }
  }
}
