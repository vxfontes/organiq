import 'package:flutter/material.dart';
import 'package:organiq/shared/components/ib_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class SettingsNotificationsHeaderCard extends StatelessWidget {
  const SettingsNotificationsHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return IBCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IBIcon(
            IBIcon.notificationsActiveRounded,
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
                  'Central de notificações',
                  context: context,
                ).subtitulo.build(),
                const SizedBox(height: 4),
                IBText(
                  'Escolha quais alertas receber, com qual antecedência e quando silenciar.',
                  context: context,
                ).caption.build(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
