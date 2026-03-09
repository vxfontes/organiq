import 'package:flutter/material.dart';
import 'package:inbota/modules/notifications/data/models/notification_log_model.dart';
import 'package:inbota/presentation/screens/notifications_module/components/notification_card.dart';
import 'package:inbota/presentation/screens/notifications_module/controller/notifications_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends IBState<NotificationsPage, NotificationsController> {
  @override
  void initState() {
    super.initState();
    controller.fetchNotifications();
    controller.error.addListener(_onErrorChanged);
  }

  @override
  void dispose() {
    controller.error.removeListener(_onErrorChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final error = controller.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      IBSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IBLightAppBar(
        title: 'Notificações',
        actions: [
          ValueListenableBuilder<List<NotificationLogModel>>(
            valueListenable: controller.notifications,
            builder: (context, notifications, _) {
              final hasUnread = notifications.any((n) => n.readAt == null);
              if (!hasUnread) return const SizedBox.shrink();

              return IconButton(
                onPressed: controller.markAllAsRead,
                tooltip: 'Marcar todas como lidas',
                icon: const IBIcon(
                  IBIcon.checkRounded,
                  color: AppColors.primary700,
                  size: 22,
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: controller.loading,
        builder: (context, loading, _) {
          return ValueListenableBuilder<List<NotificationLogModel>>(
            valueListenable: controller.notifications,
            builder: (context, notifications, _) {
              if (loading && notifications.isEmpty) {
                return const Center(child: IBLoader());
              }

              if (notifications.isEmpty) {
                return const Center(
                  child: IBEmptyState(
                    title: 'Nenhuma notificação',
                    subtitle: 'Suas notificações aparecerão aqui.',
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchNotifications,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return NotificationCard(
                      notification: notification,
                      onTap: notification.readAt == null
                          ? () => controller.markAsRead(notification.id)
                          : null,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
