import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:organiq/shared/utils/infos_device.dart';

class AppSessionService {
  AppSessionService();

  final Random _random = Random.secure();

  String? _sessionId;
  String? _appVersion;
  Future<void>? _startFuture;

  Future<void> start() {
    return _startFuture ??= _startInternal();
  }

  Future<void> _startInternal() async {
    _sessionId ??= _generateSessionId();
    _appVersion ??= await _loadAppVersion();
  }

  Future<void> refreshSession() async {
    _sessionId = _generateSessionId();
    await start();
  }

  String get sessionId => _sessionId ??= _generateSessionId();

  String get platform {
    if (kIsWeb) return 'web';
    if (InfosDevice.isAndroid) return 'android';
    if (InfosDevice.isIOS) return 'ios';
    if (InfosDevice.isMacOS) return 'macos';
    if (InfosDevice.isWindows) return 'windows';
    if (InfosDevice.isLinux) return 'linux';
    return defaultTargetPlatform.name;
  }

  String get appVersion => _appVersion ?? 'unknown';

  String _generateSessionId() {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final nonce = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return 'sess_$timestamp$nonce';
  }

  Future<String> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = info.buildNumber.trim();
      if (build.isEmpty) return info.version;
      return '${info.version}+$build';
    } catch (_) {
      return 'unknown';
    }
  }
}
