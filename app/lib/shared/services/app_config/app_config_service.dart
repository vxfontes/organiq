import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class AppAIConfig {
  const AppAIConfig({
    required this.createAiEnabled,
    required this.suggestionAiEnabled,
    required this.settingsNotificationsAdminEmails,
    required this.minMandatoryVersion,
    required this.latestSuggestedVersion,
    required this.storeAndroidUrl,
    required this.storeIosUrl,
    required this.mustUpdate,
    required this.shouldUpdate,
  });

  final bool createAiEnabled;
  final bool suggestionAiEnabled;
  final List<String> settingsNotificationsAdminEmails;
  final String minMandatoryVersion;
  final String latestSuggestedVersion;
  final String storeAndroidUrl;
  final String storeIosUrl;
  final bool mustUpdate;
  final bool shouldUpdate;
}

abstract class IAppConfigService {
  Future<AppAIConfig> getAIConfig({String? appVersion});
}

class AppConfigService implements IAppConfigService {
  AppConfigService(this._httpClient);

  static const AppAIConfig _defaultAIConfig = AppAIConfig(
    createAiEnabled: true,
    suggestionAiEnabled: true,
    settingsNotificationsAdminEmails: <String>[],
    minMandatoryVersion: '0.0.0',
    latestSuggestedVersion: '0.0.0',
    storeAndroidUrl: '',
    storeIosUrl: '',
    mustUpdate: false,
    shouldUpdate: false,
  );

  final IHttpClient _httpClient;

  @override
  Future<AppAIConfig> getAIConfig({String? appVersion}) async {
    final payload = await _getConfigPayload(
      AppPath.appConfigAI,
      appVersion: appVersion,
    );
    if (payload == null) {
      return _defaultAIConfig;
    }

    return AppAIConfig(
      createAiEnabled: _parseBool(payload['createAiEnabled'], fallback: true),
      suggestionAiEnabled: _parseBool(
        payload['suggestionAiEnabled'],
        fallback: true,
      ),
      settingsNotificationsAdminEmails: _parseEmailList(
        payload['settingsNotificationsAdminEmails'],
      ),
      minMandatoryVersion: payload['minMandatoryVersion']?.toString() ?? '0.0.0',
      latestSuggestedVersion:
          payload['latestSuggestedVersion']?.toString() ?? '0.0.0',
      storeAndroidUrl: payload['storeAndroidUrl']?.toString() ?? '',
      storeIosUrl: payload['storeIosUrl']?.toString() ?? '',
      mustUpdate: _parseBool(payload['mustUpdate'], fallback: false),
      shouldUpdate: _parseBool(payload['shouldUpdate'], fallback: false),
    );
  }

  Future<Map<String, dynamic>?> _getConfigPayload(
    String path, {
    String? appVersion,
  }) async {
    try {
      final response = await _httpClient.get(
        path,
        extra: {
          'auth': false,
          if (appVersion != null) 'headers': {'X-App-Version': appVersion},
        },
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        return null;
      }
      return _asMap(response.data);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  bool _parseBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value?.toString().trim().toLowerCase();
    switch (normalized) {
      case '1':
      case 'true':
      case 'yes':
      case 'y':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'n':
      case 'off':
        return false;
      default:
        return fallback;
    }
  }

  List<String> _parseEmailList(dynamic value) {
    final rawList = switch (value) {
      List<dynamic>() => value,
      _ => const <dynamic>[],
    };

    final seen = <String>{};
    final out = <String>[];
    for (final item in rawList) {
      final email = item.toString().trim().toLowerCase();
      if (email.isEmpty || !email.contains('@')) continue;
      if (!seen.add(email)) continue;
      out.add(email);
    }
    return out;
  }
}
