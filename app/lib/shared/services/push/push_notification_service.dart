import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:inbota/modules/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/shared/services/push/notification_payload.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  INotificationsRepository? _repository;
  bool _initialized = false;

  void setRepository(INotificationsRepository repository) {
    _repository = repository;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }

      // 2. Init local notifications for foreground
      await _initLocalNotifications();

      // 3. Listeners
      _setupListeners();

      // 4. Handle initial message if app was killed
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        onTap(NotificationPayload.fromMap(initialMessage.data));
      }

      _initialized = true;
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
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
              onTap(NotificationPayload.fromMap(data));
            }
          } catch (e) {
            if (kDebugMode) print('Error parsing notification payload: $e');
          }
        }
      },
    );
  }

  void _setupListeners() {
    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
      }
      _showLocalNotification(message);
    });

    // Background tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
      }
      onTap(NotificationPayload.fromMap(message.data));
    });

    // Token refresh
    _fcm.onTokenRefresh.listen((token) {
      _registerTokenOnBackend(token);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void onTap(NotificationPayload payload) {
    if (payload.id != null) {
      _repository?.markAsRead(payload.id!);
    }

    switch (payload.type) {
      case NotificationType.reminder:
        AppNavigation.navigate(AppRoutes.rootReminders, args: {'id': payload.referenceId});
        break;
      case NotificationType.event:
        AppNavigation.navigate(AppRoutes.rootEvents, args: {'id': payload.referenceId});
        break;
      case NotificationType.task:
        AppNavigation.navigate(AppRoutes.rootHome, args: {'id': payload.referenceId});
        break;
      case NotificationType.routine:
        AppNavigation.navigate(AppRoutes.rootSchedule);
        break;
      default:
        break;
    }
  }

  Future<String?> getToken() async {
    if (Platform.isIOS) {
      // No iOS, às vezes o token APNS demora um pouco para ser registrado.
      // Vamos tentar aguardar um pouco se necessário.
      String? apnsToken;
      int retries = 0;
      while (apnsToken == null && retries < 3) {
        apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(seconds: 2));
          retries++;
        }
      }

      if (apnsToken == null && kDebugMode) {
        print('Warning: APNS token is still null after retries. FCM token might fail.');
      }
    }

    try {
      return await _fcm.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  Future<void> registerToken() async {
    String? token = await getToken();
    if (token != null) {
      await _registerTokenOnBackend(token);
    }
  }

  Future<void> _registerTokenOnBackend(String token) async {
    if (_repository != null) {
      String platform = Platform.isIOS ? 'ios' : 'android';
      await _repository!.registerDeviceToken(
        token,
        platform,
        appVersion: '0.0.4',
      );
    }
  }

  Future<void> unregisterToken() async {
    String? token = await getToken();
    if (token != null && _repository != null) {
      await _repository!.unregisterDeviceToken(token);
    }
    await _fcm.deleteToken();
  }
}
