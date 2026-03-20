import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:organiq/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/shared/services/push/firebase_bootstrap.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum PushDeviceSyncErrorCode {
  unsupportedPlatform,
  permissionDenied,
  tokenUnavailable,
  registerFailed,
  syncInProgress,
}

class PushDeviceSyncResult {
  const PushDeviceSyncResult._({
    required this.success,
    this.errorCode,
    this.details,
  });

  final bool success;
  final PushDeviceSyncErrorCode? errorCode;
  final String? details;

  factory PushDeviceSyncResult.success() {
    return const PushDeviceSyncResult._(success: true);
  }

  factory PushDeviceSyncResult.failure(
    PushDeviceSyncErrorCode errorCode, {
    String? details,
  }) {
    return PushDeviceSyncResult._(
      success: false,
      errorCode: errorCode,
      details: details,
    );
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static const String _deviceIdStorageKey = 'push_device_id';
  static const List<Duration> _pushTokenRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
  ];

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ValueNotifier<String?> _pushTokenNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _pushTokenLoadingNotifier = ValueNotifier(false);

  INotificationsRepository? _repository;
  bool _initialized = false;
  bool _registering = false;
  bool _permissionsRequested = false;
  bool _firebaseListenersAttached = false;
  Future<void>? _initializing;
  final Map<String, DateTime> _recentForegroundMessages = {};
  String? _deviceName;
  String? _deviceId;
  String? _pendingClickUrl;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  AppLifecycleListener? _lifecycleListener;
  Timer? _pushTokenRetryTimer;
  int _pushTokenRetryAttempt = 0;

  String? get currentPushToken => _pushTokenNotifier.value;
  ValueListenable<String?> get pushTokenListenable => _pushTokenNotifier;
  ValueListenable<bool> get pushTokenLoadingListenable =>
      _pushTokenLoadingNotifier;

  void setRepository(INotificationsRepository repository) {
    _repository = repository;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing != null) {
      await _initializing;
      return;
    }

    _initializing = _initializeInternal();
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initializeInternal() async {
    if (_repository == null) {
      if (kDebugMode) {
        print('PushNotificationService: repository not set.');
      }
      return;
    }

    await _initLocalNotifications();

    if (!FirebaseBootstrap.isSupportedPlatform) {
      _initialized = true;
      return;
    }

    await _requestNotificationPermissions();
    await _loadDeviceInfo();
    _attachFirebaseListeners();
    _attachLifecycleRetry();
    await _syncCurrentPushToken();
    await _handleInitialMessage();

    _initialized = true;
  }

  Future<void> _requestNotificationPermissions() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print(
        'PushNotificationService: notification permission=${settings.authorizationStatus}',
      );
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == null) return;

        try {
          final data = jsonDecode(details.payload!);
          if (data is Map<String, dynamic>) {
            _navigateByData(data);
          }
        } catch (e) {
          if (kDebugMode) {
            print('PushNotificationService: payload parse error=$e');
          }
        }
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'Notificações importantes do Organiq.',
          importance: Importance.max,
        ),
      );
    }

    if (Platform.isIOS) {
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _loadDeviceInfo() async {
    _deviceId = await _secureStorage.read(key: _deviceIdStorageKey);
    if (_deviceId?.isEmpty == true) _deviceId = null;

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      _deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      _deviceId ??= await _createAndPersistDeviceId(seed: 'android');
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      _deviceName = iosInfo.name;
      _deviceId = iosInfo.identifierForVendor ?? _deviceId;
      _deviceId ??= await _createAndPersistDeviceId(seed: 'ios');
      await _secureStorage.write(key: _deviceIdStorageKey, value: _deviceId);
    }
  }

  void _attachFirebaseListeners() {
    if (_firebaseListenersAttached) return;
    _firebaseListenersAttached = true;

    _onMessageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen(_handleMessageOpenedApp);
    _onTokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen((token) {
          _updatePushTokenLocally(token);
          unawaited(
            registerDevice(forceRefresh: true, pushTokenOverride: token),
          );
        });
  }

  void _attachLifecycleRetry() {
    _lifecycleListener ??= AppLifecycleListener(
      onResume: () {
        unawaited(ensurePushToken(forceRefresh: true));
      },
    );
  }

  Future<void> _syncCurrentPushToken() async {
    try {
      final token = await _resolvePushToken();
      _updatePushTokenLocally(token);

      if (token != null) {
        await registerDevice(forceRefresh: true, pushTokenOverride: token);
      } else {
        _schedulePushTokenRetry();
      }
    } catch (e) {
      _schedulePushTokenRetry();
      if (kDebugMode) {
        print('PushNotificationService: getToken error=$e');
      }
    }
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> ensurePushToken({bool forceRefresh = false}) async {
    if (!FirebaseBootstrap.isSupportedPlatform) return;

    if (_deviceId == null) {
      await _loadDeviceInfo();
    }

    if (forceRefresh) {
      try {
        final token = await _resolvePushToken();
        _updatePushTokenLocally(token);
        await registerDevice(forceRefresh: true, pushTokenOverride: token);
        if (token != null && token.isNotEmpty) {
          _resetPushTokenRetry();
        } else {
          _schedulePushTokenRetry();
        }
      } catch (e) {
        _schedulePushTokenRetry();
        if (kDebugMode) {
          print('PushNotificationService: force getToken error=$e');
        }
      }
      return;
    }

    if (_pushTokenNotifier.value == null) {
      await _syncCurrentPushToken();
    }
  }

  Future<PushDeviceSyncResult> syncDeviceToken({
    bool forceRefresh = true,
  }) async {
    if (!FirebaseBootstrap.isSupportedPlatform) {
      return PushDeviceSyncResult.failure(
        PushDeviceSyncErrorCode.unsupportedPlatform,
      );
    }

    if (_deviceId == null) {
      await _loadDeviceInfo();
    }

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return PushDeviceSyncResult.failure(
        PushDeviceSyncErrorCode.permissionDenied,
      );
    }

    String? token = _pushTokenNotifier.value;
    if (forceRefresh || token == null || token.isEmpty) {
      token = await _resolvePushToken();
      if (token == null || token.isEmpty) {
        _schedulePushTokenRetry();
        return PushDeviceSyncResult.failure(
          PushDeviceSyncErrorCode.tokenUnavailable,
        );
      }
      _updatePushTokenLocally(token);
    }

    return _registerDeviceToken(
      forceRefresh: forceRefresh,
      pushTokenOverride: token,
    );
  }

  Future<String?> _resolvePushToken() async {
    if (Platform.isIOS) {
      await _waitForApnsToken();
    }

    final maxAttempts = Platform.isIOS ? 6 : 2;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        return token;
      }

      if (kDebugMode) {
        print(
          'PushNotificationService: getToken returned null attempt=$attempt/$maxAttempts',
        );
      }

      if (attempt < maxAttempts) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }

    return null;
  }

  Future<void> _waitForApnsToken() async {
    const maxAttempts = 10;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        if (kDebugMode) {
          print('PushNotificationService: APNS token available.');
        }
        return;
      }

      if (kDebugMode) {
        print(
          'PushNotificationService: APNS token pending attempt=$attempt/$maxAttempts',
        );
      }

      if (attempt < maxAttempts) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<void> registerDevice({
    bool forceRefresh = false,
    String? pushTokenOverride,
  }) async {
    final syncResult = await _registerDeviceToken(
      forceRefresh: forceRefresh,
      pushTokenOverride: pushTokenOverride,
    );
    if (!syncResult.success && kDebugMode) {
      print(
        'PushNotificationService: register error code=${syncResult.errorCode} details=${syncResult.details}',
      );
    }
  }

  Future<PushDeviceSyncResult> _registerDeviceToken({
    bool forceRefresh = false,
    String? pushTokenOverride,
  }) async {
    if (_registering) {
      return PushDeviceSyncResult.failure(
        PushDeviceSyncErrorCode.syncInProgress,
      );
    }
    if (_repository == null || _deviceId == null) {
      return PushDeviceSyncResult.failure(
        PushDeviceSyncErrorCode.registerFailed,
      );
    }

    final pushToken = pushTokenOverride ?? _pushTokenNotifier.value;
    if (pushToken == null || pushToken.isEmpty) {
      _schedulePushTokenRetry();
      return PushDeviceSyncResult.failure(
        PushDeviceSyncErrorCode.tokenUnavailable,
      );
    }

    _registering = true;
    _pushTokenLoadingNotifier.value = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final result = await _repository!.registerDeviceToken(
        _deviceId!,
        pushToken,
        platform,
        deviceName: _deviceName,
        appVersion: info.version,
      );

      return result.fold(
        (failure) {
          return PushDeviceSyncResult.failure(
            PushDeviceSyncErrorCode.registerFailed,
            details: failure.message,
          );
        },
        (_) {
          _resetPushTokenRetry();
          if (forceRefresh) {
            _updatePushTokenLocally(pushToken);
          }
          return PushDeviceSyncResult.success();
        },
      );
    } finally {
      _registering = false;
      _pushTokenLoadingNotifier.value = false;
    }
  }

  void _updatePushTokenLocally(String? pushToken) {
    if (pushToken?.isEmpty == true) return;
    if (_pushTokenNotifier.value != pushToken) {
      _pushTokenNotifier.value = pushToken;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (_shouldSuppressDuplicateForegroundMessage(message)) {
      if (kDebugMode) {
        print(
          'PushNotificationService: duplicate foreground message suppressed.',
        );
      }
      return;
    }

    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    if (Platform.isIOS) {
      return;
    }

    await _showLocalNotification(
      title ?? 'Organiq',
      body ?? '',
      Map<String, dynamic>.from(message.data),
    );
  }

  bool _shouldSuppressDuplicateForegroundMessage(RemoteMessage message) {
    final now = DateTime.now();
    _recentForegroundMessages.removeWhere(
      (_, seenAt) => now.difference(seenAt) > const Duration(seconds: 10),
    );

    final key = _foregroundMessageDedupKey(message);
    final previous = _recentForegroundMessages[key];
    if (previous != null) {
      return true;
    }

    _recentForegroundMessages[key] = now;
    return false;
  }

  String _foregroundMessageDedupKey(RemoteMessage message) {
    final messageId = message.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      return 'message_id:$messageId';
    }

    final notificationLogId = message.data['notification_log_id'];
    if (notificationLogId is String && notificationLogId.isNotEmpty) {
      return 'notification_log_id:$notificationLogId';
    }

    final title = message.notification?.title ?? message.data['title'] ?? '';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final clickUrl = message.data['click_url'] ?? '';
    return 'fallback:$title|$body|$clickUrl';
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _navigateByData(Map<String, dynamic>.from(message.data));
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void _navigateByData(Map<String, dynamic> data) {
    final rawUrl = data['click_url'];
    if (rawUrl is! String || rawUrl.isEmpty) return;
    _navigateOrQueue(rawUrl);
  }

  void consumePendingNavigation() {
    final pendingClickUrl = _pendingClickUrl;
    if (pendingClickUrl == null || pendingClickUrl.isEmpty) return;

    _pendingClickUrl = null;
    _navigateByUrl(pendingClickUrl);
  }

  void _navigateOrQueue(String url) {
    final currentPath = AppNavigation.path;
    final shouldQueue =
        currentPath == AppRoutes.splash ||
        currentPath == AppRoutes.auth ||
        currentPath == AppRoutes.login ||
        currentPath == AppRoutes.signup;

    if (shouldQueue) {
      _pendingClickUrl = url;
      return;
    }

    _navigateByUrl(url);
  }

  void _navigateByUrl(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    final params = uri.queryParameters;

    AppNavigation.navigate(path, args: params);
  }

  Future<void> unregisterDevice() async {
    if (_deviceId != null && _repository != null) {
      await _repository!.unregisterDeviceToken(_deviceId!);
    }

    await _onMessageSubscription?.cancel();
    await _onMessageOpenedAppSubscription?.cancel();
    await _onTokenRefreshSubscription?.cancel();
    _pushTokenRetryTimer?.cancel();
    _pushTokenRetryTimer = null;
    _onMessageSubscription = null;
    _onMessageOpenedAppSubscription = null;
    _onTokenRefreshSubscription = null;
    _lifecycleListener?.dispose();
    _lifecycleListener = null;

    _initialized = false;
    _initializing = null;
    _registering = false;
    _permissionsRequested = false;
    _firebaseListenersAttached = false;
    _pushTokenRetryAttempt = 0;
    _deviceId = null;
    _deviceName = null;
    _pendingClickUrl = null;
    _pushTokenLoadingNotifier.value = false;
    _pushTokenNotifier.value = null;
    _recentForegroundMessages.clear();
  }

  Future<String> _createAndPersistDeviceId({required String seed}) async {
    final random = Random.secure();
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final entropyA = random.nextInt(1 << 32).toRadixString(16);
    final entropyB = random.nextInt(1 << 32).toRadixString(16);
    final deviceId = 'organiq_${seed}_$ts$entropyA$entropyB';
    await _secureStorage.write(key: _deviceIdStorageKey, value: deviceId);
    return deviceId;
  }

  void _schedulePushTokenRetry() {
    if (_pushTokenRetryAttempt >= _pushTokenRetryDelays.length) {
      return;
    }
    if (_pushTokenRetryTimer?.isActive == true) {
      return;
    }

    final delay = _pushTokenRetryDelays[_pushTokenRetryAttempt];
    _pushTokenRetryAttempt += 1;

    if (kDebugMode) {
      print(
        'PushNotificationService: scheduling token retry attempt=$_pushTokenRetryAttempt delay=${delay.inSeconds}s',
      );
    }

    _pushTokenRetryTimer = Timer(delay, () {
      _pushTokenRetryTimer = null;
      unawaited(ensurePushToken(forceRefresh: true));
    });
  }

  void _resetPushTokenRetry() {
    _pushTokenRetryTimer?.cancel();
    _pushTokenRetryTimer = null;
    _pushTokenRetryAttempt = 0;
  }
}
