import 'package:flutter/material.dart';
import 'package:organiq/modules/auth/domain/usecases/get_me_usecase.dart';
import 'package:organiq/modules/notifications/data/models/notification_preferences_model.dart';
import 'package:organiq/modules/notifications/domain/usecases/get_notification_prefs_usecase.dart';
import 'package:organiq/modules/notifications/domain/usecases/send_test_email_digest_usecase.dart';
import 'package:organiq/modules/notifications/domain/usecases/send_test_notification_usecase.dart';
import 'package:organiq/modules/notifications/domain/usecases/update_notification_prefs_usecase.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/app_config/app_config_service.dart';
import 'package:organiq/shared/state/oq_state.dart';

class SettingsNotificationsController implements OQController {
  final GetNotificationPrefsUsecase _getPrefsUsecase;
  final UpdateNotificationPrefsUsecase _updatePrefsUsecase;
  final SendTestNotificationUsecase _sendTestUsecase;
  final SendTestEmailDigestUsecase _sendTestEmailUsecase;
  final IAppConfigService _appConfigService;
  final GetMeUsecase _getMeUsecase;

  SettingsNotificationsController(
    this._getPrefsUsecase,
    this._updatePrefsUsecase,
    this._sendTestUsecase,
    this._sendTestEmailUsecase,
    this._appConfigService,
    this._getMeUsecase,
  );

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<bool> sendingTest = ValueNotifier(false);
  final ValueNotifier<bool> sendingEmailTest = ValueNotifier(false);
  final ValueNotifier<bool> loadingDailySummaryToken = ValueNotifier(false);
  final ValueNotifier<String?> dailySummaryToken = ValueNotifier(null);
  final ValueNotifier<String?> dailySummaryUrl = ValueNotifier(null);
  final ValueNotifier<bool> showAdminNotificationSections = ValueNotifier(
    false,
  );
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<NotificationPreferencesModel?> prefs = ValueNotifier(
    null,
  );

  Future<void> load() async {
    await fetchPreferences();
    await _loadAdminNotificationSectionsAccess();
    if (showAdminNotificationSections.value) {
      await fetchDailySummaryToken();
    }
  }

  Future<void> fetchPreferences() async {
    loading.value = true;
    error.value = null;

    final result = await _getPrefsUsecase();

    result.fold(
      (failure) => error.value = _failureMessage(
        failure,
        fallback: 'Erro ao carregar preferências.',
      ),
      (data) => prefs.value = data,
    );

    loading.value = false;
  }

  Future<void> fetchDailySummaryToken() async {
    loadingDailySummaryToken.value = true;

    final result = await _getPrefsUsecase.repository.getDailySummaryToken();
    result.fold(
      (failure) {
        error.value = _failureMessage(
          failure,
          fallback: 'Erro ao carregar token.',
        );
      },
      (data) {
        dailySummaryToken.value = data['token'];
        dailySummaryUrl.value = data['url'];
      },
    );

    loadingDailySummaryToken.value = false;
  }

  Future<void> _loadAdminNotificationSectionsAccess() async {
    try {
      final config = await _appConfigService.getAIConfig();
      final allowedEmails = config.settingsNotificationsAdminEmails;
      if (allowedEmails.isEmpty) {
        showAdminNotificationSections.value = false;
        return;
      }

      final meResult = await _getMeUsecase.call();
      final email = meResult.fold<String?>((_) => null, (user) => user.email);
      final normalizedEmail = email?.trim().toLowerCase() ?? '';

      if (normalizedEmail.isEmpty) {
        showAdminNotificationSections.value = false;
        return;
      }

      showAdminNotificationSections.value = allowedEmails.contains(
        normalizedEmail,
      );
    } catch (_) {
      showAdminNotificationSections.value = false;
    }
  }

  Future<void> rotateDailySummaryToken() async {
    loadingDailySummaryToken.value = true;

    final result = await _getPrefsUsecase.repository.rotateDailySummaryToken();
    result.fold(
      (failure) {
        error.value = _failureMessage(
          failure,
          fallback: 'Erro ao rotacionar token.',
        );
      },
      (data) {
        dailySummaryToken.value = data['token'];
        dailySummaryUrl.value = data['url'];
      },
    );

    loadingDailySummaryToken.value = false;
  }

  Future<void> updatePreferences(NotificationPreferencesModel newPrefs) async {
    // Optimistic update
    final oldPrefs = prefs.value;
    prefs.value = newPrefs;

    final result = await _updatePrefsUsecase(newPrefs);

    result.fold((failure) {
      prefs.value = oldPrefs; // Rollback
      error.value = _failureMessage(
        failure,
        fallback: 'Erro ao atualizar preferências.',
      );
    }, (data) => prefs.value = data);
  }

  Future<bool> sendTestNotification() async {
    sendingTest.value = true;
    error.value = null;
    final result = await _sendTestUsecase();
    sendingTest.value = false;

    return result.fold((failure) {
      error.value = _failureMessage(
        failure,
        fallback: 'Erro ao enviar notificação de teste.',
      );
      return false;
    }, (_) => true);
  }

  Future<bool> sendTestEmailDigest() async {
    sendingEmailTest.value = true;
    error.value = null;
    final result = await _sendTestEmailUsecase();
    sendingEmailTest.value = false;

    return result.fold((failure) {
      error.value = _failureMessage(
        failure,
        fallback: 'Erro ao enviar e-mail de teste.',
      );
      return false;
    }, (_) => true);
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
    loadingDailySummaryToken.dispose();
    dailySummaryToken.dispose();
    dailySummaryUrl.dispose();
    showAdminNotificationSections.dispose();
    error.dispose();
    prefs.dispose();
  }
}
