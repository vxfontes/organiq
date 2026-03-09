import 'package:flutter/material.dart';
import 'package:inbota/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:inbota/shared/components/ib_lib/ib_toggle.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SettingsNotificationsQuietHoursContent extends StatelessWidget {
  const SettingsNotificationsQuietHoursContent({
    super.key,
    required this.prefs,
    required this.onEnabledChanged,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final NotificationPreferencesModel prefs;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IBToggle(
          title: 'Ativar silêncio',
          subtitle: 'Bloqueia alertas dentro do intervalo configurado.',
          leadingIcon: IBIcon.notificationsNoneOutlined,
          value: prefs.quietHoursEnabled,
          onChanged: onEnabledChanged,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: prefs.quietHoursEnabled
              ? Row(
                  key: const ValueKey('quiet-hours-enabled'),
                  children: [
                    Expanded(
                      child: IBTimeField(
                        label: 'Das',
                        valueLabel: prefs.quietStart ?? '22:00',
                        enabled: true,
                        hasValue: true,
                        onTap: onPickStart,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: IBTimeField(
                        label: 'Até',
                        valueLabel: prefs.quietEnd ?? '08:00',
                        enabled: true,
                        hasValue: true,
                        onTap: onPickEnd,
                      ),
                    ),
                  ],
                )
              : Container(
                  key: const ValueKey('quiet-hours-disabled'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IBText(
                    'As notificações serão enviadas a qualquer hora enquanto essa opção estiver desativada.',
                    context: context,
                  ).caption.build(),
                ),
        ),
      ],
    );
  }
}
