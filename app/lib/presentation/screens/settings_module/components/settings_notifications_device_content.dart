import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/services/push/push_notification_service.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SettingsNotificationsDeviceContent extends StatelessWidget {
  const SettingsNotificationsDeviceContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IBText(
          'Use este tópico no app ntfy para manter o recebimento de notificações em segundo plano.',
          context: context,
        ).caption.build(),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable:
              PushNotificationService.instance.topicLoadingListenable,
          builder: (context, loading, _) {
            return ValueListenableBuilder<String?>(
              valueListenable: PushNotificationService.instance.topicListenable,
              builder: (context, topic, __) {
                final topicLabel =
                    topic ??
                    (loading ? 'Gerando tópico...' : 'Tópico indisponível');

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const IBIcon(
                              IBIcon.notificationsNoneOutlined,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: IBText(
                                topicLabel,
                                context: context,
                              ).body.maxLines(2).build(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: topic == null
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: topic));
                              IBSnackBar.success(context, 'Tópico copiado!');
                            },
                      tooltip: 'Copiar tópico',
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceSoft,
                        foregroundColor: AppColors.primary700,
                        disabledForegroundColor: AppColors.textMuted,
                      ),
                    ),
                    IconButton(
                      onPressed: loading
                          ? null
                          : () => unawaited(
                              PushNotificationService.instance.ensureTopic(
                                forceRefresh: true,
                              ),
                            ),
                      tooltip: 'Gerar novamente',
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceSoft,
                        foregroundColor: AppColors.primary700,
                        disabledForegroundColor: AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
