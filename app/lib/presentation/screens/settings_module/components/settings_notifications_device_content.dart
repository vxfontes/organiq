import 'dart:async';

import 'package:flutter/material.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/services/push/push_notification_service.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class SettingsNotificationsDeviceContent extends StatelessWidget {
  const SettingsNotificationsDeviceContent({
    super.key,
    required this.onSendTest,
    required this.sendingTest,
  });

  final Future<void> Function() onSendTest;
  final bool sendingTest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OQText(
          'As push notifications deste aparelho sao sincronizadas automaticamente com o backend.',
          context: context,
        ).caption.build(),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable:
              PushNotificationService.instance.pushTokenLoadingListenable,
          builder: (context, loading, _) {
            return Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: loading
                    ? null
                    : () => unawaited(
                        PushNotificationService.instance.ensurePushToken(
                          forceRefresh: true,
                        ),
                      ),
                tooltip: 'Sincronizar novamente',
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textMuted,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
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
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OQButton(
            label: 'Enviar notificacao de teste',
            loading: sendingTest,
            onPressed: onSendTest,
            variant: OQButtonVariant.secondary,
          ),
        ),
      ],
    );
  }
}
