import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();
  static const String _deviceIdStorageKey = 'push_device_id';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ValueNotifier<String?> _topicNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _topicLoadingNotifier = ValueNotifier(false);

  INotificationsRepository? _repository;
  WebSocketChannel? _channel;
  bool _initialized = false;
  bool _registering = false;
  bool _permissionsRequested = false;
  String? _deviceName;
  String? _deviceId;
  Timer? _reconnectTimer;

  String? get currentTopic => _topicNotifier.value;
  ValueListenable<String?> get topicListenable => _topicNotifier;
  ValueListenable<bool> get topicLoadingListenable => _topicLoadingNotifier;

  void setRepository(INotificationsRepository repository) {
    _repository = repository;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (_repository == null) {
      if (kDebugMode) print('PushNotificationService: repository not set.');
      return;
    }

    // 1. Init local notifications
    await _initLocalNotifications();

    // 2. Ask OS notification permission when needed
    await _requestNotificationPermissions();

    // 3. Load device info
    await _loadDeviceInfo();

    // 4. Register on backend to get the topic
    await registerDevice();

    _initialized = true;
  }

  Future<void> _requestNotificationPermissions() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidPlugin?.requestNotificationsPermission();
      if (kDebugMode) {
        print(
          'PushNotificationService: Android notification permission=$granted',
        );
      }
      return;
    }

    if (Platform.isIOS) {
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        print('PushNotificationService: iOS notification permission=$granted');
      }
      return;
    }

    if (Platform.isMacOS) {
      final macosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      final granted = await macosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        print(
          'PushNotificationService: macOS notification permission=$granted',
        );
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!);
            if (data is Map<String, dynamic>) {
              final clickUrl = data['click_url'] as String?;
              if (clickUrl != null) {
                _navigateByUrl(clickUrl);
              }
            }
          } catch (e) {
            if (kDebugMode) print('Error parsing notification payload: $e');
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
          description: 'Notificações importantes do Inbota.',
          importance: Importance.max,
        ),
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

  Future<void> ensureTopic({bool forceRefresh = false}) async {
    if (!forceRefresh && _topicNotifier.value != null) return;
    if (_deviceId == null) {
      await _loadDeviceInfo();
    }
    await registerDevice(forceRefresh: forceRefresh);
  }

  Future<void> registerDevice({bool forceRefresh = false}) async {
    if (_registering) return;
    if (!forceRefresh && _topicNotifier.value != null) return;
    if (_repository == null) return;
    if (_deviceId == null) return;

    _registering = true;
    _topicLoadingNotifier.value = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final result = await _repository!.registerDeviceToken(
        _deviceId!,
        platform,
        deviceName: _deviceName,
        appVersion: info.version,
      );

      result.fold((failure) {
        if (kDebugMode) print('Error registering device: ${failure.message}');
      }, updateTopicFromServer);
    } finally {
      _registering = false;
      _topicLoadingNotifier.value = false;
    }
  }

  void updateTopicFromServer(String topic) {
    if (_topicNotifier.value != topic) {
      _topicNotifier.value = topic;
      _connectWebSocket();
    }
  }

  void _connectWebSocket() {
    final topic = _topicNotifier.value;
    if (topic == null) return;

    _reconnectTimer?.cancel();
    _channel?.sink.close();
    final wsUrl = Uri.parse('wss://ntfy.sh/$topic/ws');

    try {
      if (kDebugMode) {
        print('PushNotificationService: connecting ws topic=$topic');
      }
      _channel = WebSocketChannel.connect(wsUrl);
      _channel!.stream.listen(
        (message) => _handleWsMessage(message),
        onDone: () {
          if (kDebugMode) print('PushNotificationService: ws done');
          _scheduleReconnect();
        },
        onError: (error) {
          if (kDebugMode) print('PushNotificationService: ws error=$error');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      if (kDebugMode) print('PushNotificationService: ws connect error=$e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      _connectWebSocket();
    });
  }

  void _handleWsMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (data['event'] == 'message') {
        final title = data['title'] ?? 'Inbota';
        final body = data['message'] ?? '';

        // ntfy envia metadados no campo 'attachment' ou em campos customizados se configurado,
        // mas aqui estamos usando o payload que o backend enviou.
        // Se o backend enviou click_url no corpo da mensagem ou metadados:
        final clickUrl = data['click_url'] ?? data['attachment']?['url'];

        _showLocalNotification(title, body, {'click_url': clickUrl});
      } else if (data['event'] == 'open') {
        if (kDebugMode) {
          print('PushNotificationService: ws open topic=${data['topic']}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error parsing ntfy message: $e');
    }
  }

  void _showLocalNotification(
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

  void _navigateByUrl(String url) {
    // Agora o app é burro: ele apenas recebe uma URL/Caminho e navega.
    // Ex: /reminders?id=123
    final uri = Uri.parse(url);
    final path = uri.path;
    final params = uri.queryParameters;

    AppNavigation.navigate(path, args: params);
  }

  Future<void> unregisterDevice() async {
    if (_deviceId != null && _repository != null) {
      await _repository!.unregisterDeviceToken(_deviceId!);
    }
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _initialized = false;
    _registering = false;
    _deviceId = null;
    _deviceName = null;
    _topicLoadingNotifier.value = false;
    _topicNotifier.value = null;
  }

  Future<String> _createAndPersistDeviceId({required String seed}) async {
    final random = Random.secure();
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final entropyA = random.nextInt(1 << 32).toRadixString(16);
    final entropyB = random.nextInt(1 << 32).toRadixString(16);
    final deviceId = 'inbota_${seed}_$ts$entropyA$entropyB';
    await _secureStorage.write(key: _deviceIdStorageKey, value: deviceId);
    return deviceId;
  }
}
