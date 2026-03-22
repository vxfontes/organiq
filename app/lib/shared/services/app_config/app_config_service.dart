import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class AppAIConfig {
  const AppAIConfig({
    required this.createAiEnabled,
    required this.suggestionAiEnabled,
    required this.settingsNotificationsAdminEmails,
  });

  final bool createAiEnabled;
  final bool suggestionAiEnabled;
  final List<String> settingsNotificationsAdminEmails;
}

abstract class IAppConfigService {
  Future<AppAIConfig> getAIConfig();
}

class AppConfigService implements IAppConfigService {
  AppConfigService(this._httpClient);

  static const AppAIConfig _defaultAIConfig = AppAIConfig(
    createAiEnabled: true,
    suggestionAiEnabled: true,
    settingsNotificationsAdminEmails: <String>[],
  );

  final IHttpClient _httpClient;

  @override
  Future<AppAIConfig> getAIConfig() async {
    final payload = await _getConfigPayload(AppPath.appConfigAI);
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
    );
  }

  Future<Map<String, dynamic>?> _getConfigPayload(String path) async {
    try {
      final response = await _httpClient.get(path);
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
