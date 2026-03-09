import 'package:flutter/material.dart';
import 'package:inbota/modules/notifications/data/models/notification_log_model.dart';
import 'package:inbota/modules/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:inbota/modules/notifications/domain/usecases/mark_all_notifications_as_read_usecase.dart';
import 'package:inbota/modules/notifications/domain/usecases/mark_notification_as_read_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';

class NotificationsController implements IBController {
  final GetNotificationsUsecase _getNotificationsUsecase;
  final MarkNotificationAsReadUsecase _markAsReadUsecase;
  final MarkAllNotificationsAsReadUsecase _markAllAsReadUsecase;

  NotificationsController(
    this._getNotificationsUsecase,
    this._markAsReadUsecase,
    this._markAllAsReadUsecase,
  );

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<NotificationLogModel>> notifications = ValueNotifier(
    [],
  );

  Future<void> fetchNotifications() async {
    loading.value = true;
    error.value = null;

    final result = await _getNotificationsUsecase(limit: 50);

    result.fold(
      (failure) => error.value = _failureMessage(
        failure,
        fallback: 'Erro ao carregar notificações.',
      ),
      (data) => notifications.value = data,
    );

    loading.value = false;
  }

  Future<void> markAsRead(String id) async {
    final result = await _markAsReadUsecase(id);

    result.fold(
      (failure) => error.value = _failureMessage(
        failure,
        fallback: 'Erro ao marcar como lida.',
      ),
      (_) => fetchNotifications(),
    );
  }

  Future<void> markAllAsRead() async {
    loading.value = true;
    final result = await _markAllAsReadUsecase();
    loading.value = false;

    result.fold(
      (failure) => error.value = _failureMessage(
        failure,
        fallback: 'Erro ao marcar todas como lidas.',
      ),
      (_) => fetchNotifications(),
    );
  }

  String _failureMessage(Failure failure, {required String fallback}) {
    return failure.message?.trim().isNotEmpty == true
        ? failure.message!
        : fallback;
  }

  @override
  void dispose() {
    loading.dispose();
    error.dispose();
    notifications.dispose();
  }
}
