import 'package:flutter/material.dart';
import 'package:inbota/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:inbota/modules/notifications/domain/usecases/get_notification_prefs_usecase.dart';
import 'package:inbota/modules/notifications/domain/usecases/send_test_email_digest_usecase.dart';
import 'package:inbota/modules/notifications/domain/usecases/send_test_notification_usecase.dart';
import 'package:inbota/modules/notifications/domain/usecases/update_notification_prefs_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';

class SettingsNotificationsController implements IBController {
  final GetNotificationPrefsUsecase _getPrefsUsecase;
  final UpdateNotificationPrefsUsecase _updatePrefsUsecase;
  final SendTestNotificationUsecase _sendTestUsecase;
  final SendTestEmailDigestUsecase _sendTestEmailUsecase;

  SettingsNotificationsController(
    this._getPrefsUsecase,
    this._updatePrefsUsecase,
    this._sendTestUsecase,
    this._sendTestEmailUsecase,
  );

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<bool> sendingTest = ValueNotifier(false);
  final ValueNotifier<bool> sendingEmailTest = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<NotificationPreferencesModel?> prefs = ValueNotifier(null);

  Future<void> fetchPreferences() async {
    loading.value = true;
    error.value = null;

    final result = await _getPrefsUsecase();

    result.fold(
      (failure) => error.value = _failureMessage(failure, fallback: 'Erro ao carregar preferências.'),
      (data) => prefs.value = data,
    );

    loading.value = false;
  }

  Future<void> updatePreferences(NotificationPreferencesModel newPrefs) async {
    // Optimistic update
    final oldPrefs = prefs.value;
    prefs.value = newPrefs;

    final result = await _updatePrefsUsecase(newPrefs);

    result.fold(
      (failure) {
        prefs.value = oldPrefs; // Rollback
        error.value = _failureMessage(failure, fallback: 'Erro ao atualizar preferências.');
      },
      (data) => prefs.value = data,
    );
  }

  Future<bool> sendTestNotification() async {
    sendingTest.value = true;
    error.value = null;
    final result = await _sendTestUsecase();
    sendingTest.value = false;

    return result.fold(
      (failure) {
        error.value = _failureMessage(failure, fallback: 'Erro ao enviar notificação de teste.');
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> sendTestEmailDigest() async {
    sendingEmailTest.value = true;
    error.value = null;
    final result = await _sendTestEmailUsecase();
    sendingEmailTest.value = false;

    return result.fold(
      (failure) {
        error.value = _failureMessage(failure, fallback: 'Erro ao enviar e-mail de teste.');
        return false;
      },
      (_) => true,
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
    sendingTest.dispose();
    sendingEmailTest.dispose();
    error.dispose();
    prefs.dispose();
  }
}
