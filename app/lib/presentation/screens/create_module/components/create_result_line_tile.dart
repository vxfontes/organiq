import 'package:flutter/material.dart';
import 'package:organiq/modules/inbox/data/models/inbox_create_line_result.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class CreateResultLineTile extends StatelessWidget {
  const CreateResultLineTile({super.key, required this.result, this.onDelete});

  final CreateLineResult result;
  final Future<bool> Function(CreateLineResult result)? onDelete;

  @override
  Widget build(BuildContext context) {
    final success = result.status == CreateLineStatus.success;
    final accentColor = success ? AppColors.primary700 : AppColors.danger600;
    final badgeBackground = success
        ? AppColors.primary50
        : AppColors.danger600.withAlpha(18);
    final borderColor = success ? AppColors.border : AppColors.danger600;
    final statusLabel = success ? 'Criado' : 'Falha';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: success ? borderColor : borderColor.withAlpha(76),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withAlpha(8),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: OQIcon(
                    success ? OQIcon.checkRounded : OQIcon.closeRounded,
                    color: accentColor,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBackground,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: OQText(
                        statusLabel,
                        context: context,
                      ).caption.color(accentColor).build(),
                    ),
                    const SizedBox(height: 6),
                    OQText(
                      result.message,
                      context: context,
                    ).label.weight(FontWeight.w700).build(),
                  ],
                ),
              ),
              if (result.canDelete && onDelete != null) ...[
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: result.deleting ? null : () => onDelete!(result),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: result.deleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const OQIcon(
                                OQIcon.deleteOutlineRounded,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          OQText(
            result.sourceText,
            context: context,
          ).body.color(AppColors.textMuted).maxLines(3).build(),
        ],
      ),
    );
  }
}
