import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:organiq/modules/notifications/data/models/notification_log_model.dart';
import 'package:organiq/shared/components/ib_lib/ib_text.dart';
import 'package:organiq/shared/theme/app_colors.dart';

class NotificationCard extends StatelessWidget {
  final NotificationLogModel notification;
  final VoidCallback? onTap;

  const NotificationCard({super.key, required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRead = notification.readAt != null;
    final local = notification.scheduledFor.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final date = '$day/$month $hour:$minute';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead
              ? AppColors.surface
              : AppColors.primary50.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppColors.border : AppColors.primary200,
          ),
          boxShadow: isRead
              ? null
              : [
            BoxShadow(
              color: AppColors.primary500.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isRead ? AppColors.surface : AppColors.primary100,
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: _getIconForType(notification.type),
                size: 20,
                color: isRead ? AppColors.textMuted : AppColors.primary700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: IBText(
                          notification.title,
                          context: context,
                        ).build(),
                      ),
                      const SizedBox(width: 8),
                      IBText(date, context: context).caption.muted.build(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  IBText(
                    notification.body,
                    context: context,
                  ).muted.maxLines(3).build(),
                ],
              ),
            ),
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary600,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<List<dynamic>> _getIconForType(String type) {
    switch (type) {
      case 'routine':
        return HugeIcons.strokeRoundedTaskDaily02;
      case 'reminder':
        return HugeIcons.strokeRoundedReminder;
      case 'event':
        return HugeIcons.strokeRoundedCalendar01;
      case 'shopping_list':
        return HugeIcons.strokeRoundedShoppingBag01;
      case 'digest':
        return HugeIcons.strokeRoundedMail01;
      default:
        return HugeIcons.strokeRoundedNotification01;
    }
  }
}
