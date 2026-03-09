import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SettingsContextsHeaderRow extends StatelessWidget {
  const SettingsContextsHeaderRow({
    super.key,
    required this.disabled,
    required this.onCreateFlag,
    required this.flagCount,
    required this.subflagCount,
  });

  final bool disabled;
  final VoidCallback onCreateFlag;
  final int flagCount;
  final int subflagCount;

  @override
  Widget build(BuildContext context) {
    return IBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IBIcon(
                IBIcon.tune,
                size: 20,
                color: AppColors.primary700,
                backgroundColor: AppColors.surfaceSoft,
                borderColor: AppColors.primary200,
                padding: EdgeInsets.all(10),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IBText(
                      'Organize suas áreas de foco',
                      context: context,
                    ).subtitulo.build(),
                    const SizedBox(height: 2),
                    IBText(
                      '$flagCount flag(s) • $subflagCount subflag(s)',
                      context: context,
                    ).caption.build(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: IBText(
                  'Defina contextos para separar tarefas, eventos e rotinas.',
                  context: context,
                ).muted.build(),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: IBButton(
                  label: 'Nova flag',
                  variant: IBButtonVariant.secondary,
                  onPressed: disabled ? null : onCreateFlag,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
