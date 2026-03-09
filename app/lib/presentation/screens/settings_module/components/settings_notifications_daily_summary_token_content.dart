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
              child: IBButton(
                label: 'Copiar link',
                variant: IBButtonVariant.secondary,
                onPressed: (url?.trim().isNotEmpty == true)
                    ? () {
                        Clipboard.setData(ClipboardData(text: url!));
                        IBSnackBar.success(context, 'Link copiado!');
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: IBButton(
                label: 'Rotacionar',
                variant: IBButtonVariant.secondary,
                onPressed: loading ? null : () => unawaited(onRotate()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        IBButton(
          label: 'Atualizar',
          variant: IBButtonVariant.ghost,
          onPressed: loading ? null : onRefresh,
        ),
      ],
    );
  }
}
