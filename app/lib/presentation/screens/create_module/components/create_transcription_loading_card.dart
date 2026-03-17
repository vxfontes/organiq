import 'package:flutter/material.dart';
import 'package:organiq/shared/components/ib_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class CreateTranscriptionLoadingCard extends StatelessWidget {
  const CreateTranscriptionLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          IBText(
            'Transcrevendo áudio...',
            context: context,
          ).caption.color(AppColors.textMuted).build(),
        ],
      ),
    );
  }
}
