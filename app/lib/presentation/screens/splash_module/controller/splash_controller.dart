import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:organiq/modules/auth/domain/usecases/get_me_usecase.dart';
import 'package:organiq/modules/splash/domain/usecases/check_health_usecase.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/analytics/app_monitoring_service.dart';
import 'package:organiq/shared/services/analytics/screen_log_service.dart';
import 'package:organiq/shared/services/app_config/app_config_service.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/timezone/user_timezone_service.dart';
import 'package:organiq/shared/state/oq_state.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashController implements OQController {
  SplashController(
    this._checkHealthUsecase,
    this._tokenStore,
    this._getMeUsecase,
    this._monitoringService,
    this._screenLogService,
    this._appConfigService,
    this._cache,
  );

  final CheckHealthUsecase _checkHealthUsecase;
  final AuthTokenStore _tokenStore;
  final GetMeUsecase _getMeUsecase;
  final AppMonitoringService _monitoringService;
  final ScreenLogService _screenLogService;
  final IAppConfigService _appConfigService;
  final ICacheService _cache;

  final ValueNotifier<bool> loading = ValueNotifier(true);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<AppAIConfig?> updateConfig = ValueNotifier(null);
  final ValueNotifier<bool> isMandatoryUpdate = ValueNotifier(false);

  Future<bool?> check() async {
    _screenLogService.logFlowStep(
      flowName: 'bootstrap',
      flowStep: 'session_check_started',
      action: 'check_session',
      result: 'started',
      origin: 'splash_controller',
    );
    loading.value = true;
    error.value = null;

    try {
      final result = await _checkHealthUsecase.call();
      final healthy = result.fold((failure) {
        _screenLogService.logFlowStep(
          flowName: 'bootstrap',
          flowStep: 'health_check_failed',
          action: 'check_session',
          result: 'failure',
          origin: 'splash_controller',
        );
        error.value = _failureMessage(
          failure,
          fallback: 'Servidor indisponivel. Verifique a rede local.',
        );
        return false;
      }, (_) => true);

      if (!healthy) return null;

      // Check Version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final config = await _appConfigService.getAIConfig(appVersion: currentVersion);

      if (config.mustUpdate) {
        updateConfig.value = config;
        isMandatoryUpdate.value = true;
        return null; // Stop and show mandatory update
      }

      if (config.shouldUpdate) {
        updateConfig.value = config;
        isMandatoryUpdate.value = false;
        // Suggested update will be shown on the next screen or as a non-blocking bottomsheet
      }

      final token = await _tokenStore.readToken();
      if (token == null || token.isEmpty) {
        UserTimezoneService.instance.clear();
        await _monitoringService.clearUser();
        _screenLogService.logFlowStep(
          flowName: 'bootstrap',
          flowStep: 'session_check_finished',
          action: 'check_session',
          result: 'anonymous',
          origin: 'splash_controller',
        );
        return false;
      }

      final meResult = await _getMeUsecase.call();
      final hasSession = meResult.fold((_) => false, (user) {
        UserTimezoneService.instance.setTimezone(user.timezone);
        unawaited(_monitoringService.identifyUser(userId: user.id));
        return true;
      });
      if (!hasSession) {
        UserTimezoneService.instance.clear();
        await Future.wait([
          _tokenStore.clearToken(),
          _cache.clear(),
        ]);
        await _monitoringService.clearUser();
        _screenLogService.logFlowStep(
          flowName: 'bootstrap',
          flowStep: 'session_check_finished',
          action: 'check_session',
          result: 'failure',
          origin: 'splash_controller',
        );
      } else {
        _screenLogService.logFlowStep(
          flowName: 'bootstrap',
          flowStep: 'session_check_finished',
          action: 'check_session',
          result: 'authenticated',
          origin: 'splash_controller',
        );
      }
      return hasSession;
    } finally {
      loading.value = false;
    }
  }

  @override
  void dispose() {
    loading.dispose();
    error.dispose();
    updateConfig.dispose();
    isMandatoryUpdate.dispose();
  }

  String _failureMessage(Failure failure, {required String fallback}) {
    return failure.message?.trim().isNotEmpty == true
        ? failure.message!
        : fallback;
  }
}

