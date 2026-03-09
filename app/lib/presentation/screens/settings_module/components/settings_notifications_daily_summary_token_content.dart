import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SettingsNotificationsDailySummaryTokenContent extends StatelessWidget {
  const SettingsNotificationsDailySummaryTokenContent({
    super.key,
    required this.token,
    required this.url,
    required this.loading,
    required this.onRefresh,
    required this.onRotate,
  });

  final String? token;
  final String? url;
  final bool loading;
  final VoidCallback onRefresh;
  final Future<void> Function() onRotate;

  @override
  Widget build(BuildContext context) {
    final tokenLabel = token?.trim().isNotEmpty == true
        ? token!
        : (loading ? 'Carregando...' : 'Token indisponível');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IBText(
          'Use este token para acessar o endpoint público de resumo diário (sem login).',
          context: context,
        ).caption.build(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const IBIcon(
                IBIcon.keyRounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: IBText(tokenLabel, context: context)
                    .body
                    .maxLines(2)
                    .build(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const IBIcon(
                      IBIcon.linkRounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: IBText(url ?? 'URL indisponível', context: context)
                          .body
                          .maxLines(1)
                          .build(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: (url?.trim().isNotEmpty == true)
                  ? () {
                      Clipboard.setData(ClipboardData(text: url!));
                      IBSnackBar.success(context, 'Link copiado!');
                    }
                  : null,
              tooltip: 'Copiar link',
              icon: const Icon(Icons.copy_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: url?.trim().isNotEmpty == true
                    ? AppColors.primary50
                    : AppColors.surfaceSoft,
                foregroundColor: url?.trim().isNotEmpty == true
                    ? AppColors.primary700
                    : AppColors.textMuted,
                disabledBackgroundColor: AppColors.surfaceSoft,
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: loading
                  ? null
                  : () => unawaited(onRotate()),
              tooltip: 'Rotacionar token',
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textMuted,
                      ),
                    )
                  : const IBIcon(IBIcon.autoRenew, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: loading
                    ? AppColors.surfaceSoft
                    : AppColors.primary50,
                foregroundColor: loading
                    ? AppColors.textMuted
                    : AppColors.primary700,
                disabledBackgroundColor: AppColors.surfaceSoft,
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: IBButton(
            label: 'Atualizar',
            variant: IBButtonVariant.ghost,
            onPressed: loading ? null : onRefresh,
          ),
        ),
      ],
    );
  }
}
