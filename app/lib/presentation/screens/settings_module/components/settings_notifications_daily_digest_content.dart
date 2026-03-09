import 'package:flutter/material.dart';
import 'package:inbota/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:inbota/shared/components/ib_lib/ib_toggle.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SettingsNotificationsDailyDigestContent extends StatelessWidget {
  const SettingsNotificationsDailyDigestContent({
    super.key,
    required this.prefs,
    required this.onEnabledChanged,
    required this.onPickHour,
    required this.onSendTest,
    required this.sendingTest,
  });

  final NotificationPreferencesModel prefs;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onPickHour;
  final VoidCallback onSendTest;
  final bool sendingTest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IBToggle(
          title: 'Daily Digest por e-mail',
          subtitle: 'Receba um resumo matinal com sua agenda e tarefas.',
          leadingIcon: IBIcon.mailOutlineRounded,
          value: prefs.dailyDigestEnabled,
          onChanged: onEnabledChanged,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: prefs.dailyDigestEnabled
              ? Column(
                  key: const ValueKey('daily-digest-enabled'),
                  children: [
                    IBTimeField(
                      label: 'Horário de envio',
                      valueLabel: '${prefs.dailyDigestHour.toString().padLeft(2, '0')}:00',
                      enabled: true,
                      hasValue: true,
                      onTap: onPickHour,
                    ),
                    const SizedBox(height: 16),
                    // IBButton(
                    //   label: 'Enviar e-mail de teste agora',
                    //   variant: IBButtonVariant.secondary,
                    //   onPressed: onSendTest,
                    //   loading: sendingTest,
                    //   // icon: IBIcon.sendRounded,
                    // ),
                  ],
                )
              : Container(
                  key: const ValueKey('daily-digest-disabled'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IBText(
                    'Ative para receber um e-mail diário com tudo o que você precisa fazer no dia.',
                    context: context,
                  ).caption.build(),
                ),
        ),
      ],
    );
  }
}
