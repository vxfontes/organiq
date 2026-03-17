import 'package:flutter/material.dart';

import 'package:organiq/shared/components/oq_lib/oq_icon.dart';
import 'package:organiq/shared/components/oq_lib/oq_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';
import 'package:organiq/shared/utils/text_utils.dart';

class OQShoppingBanner extends StatelessWidget {
  const OQShoppingBanner({
    super.key,
    required this.listCount,
    required this.itemCount,
    required this.onTap,
  });

  final int listCount;
  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasLists = listCount > 0;
    final backgroundColor = hasLists ? AppColors.surfaceAi : AppColors.surface2;
    final summary = hasLists
        ? '${TextUtils.countLabel(listCount, 'lista', 'listas')} - ${TextUtils.countLabel(itemCount, 'item pendente', 'itens pendentes')}'
        : 'Sem listas ativas';

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasLists
                  ? AppColors.ai500.withValues(alpha: 0.26)
                  : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OQIcon(
                OQIcon.shoppingBagOutlined,
                color: AppColors.ai500,
                size: 20,
              ),
              const SizedBox(height: 8),
              OQText('Compras', context: context).subtitulo.build(),
              const SizedBox(height: 4),
              OQText(summary, context: context).muted.maxLines(2).build(),
              const SizedBox(height: 12),
              Row(
                children: [
                  OQText(
                    hasLists ? 'Ver listas' : 'Abrir compras',
                    context: context,
                  ).label.color(AppColors.ai500).build(),
                  const SizedBox(width: 6),
                  const OQIcon(
                    OQIcon.chevronRight,
                    size: 16,
                    color: AppColors.ai500,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
