import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:organiq/shared/services/analytics/app_monitoring_service.dart';

import '../../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await FirebaseBootstrap.ensureInitialized();
    await AppMonitoringService.instance.initialize();
    await AppMonitoringService.instance.logEvent(
      'push_background_received',
      parameters: <String, Object?>{
        'has_message_id': message.messageId?.isNotEmpty == true,
      },
    );
  } catch (error, stackTrace) {
    await AppMonitoringService.instance.recordError(
      error,
      stackTrace,
      reason: 'firebase_background_message_handler_failed',
    );

    if (kDebugMode) {
      debugPrint('FCM background handler error: $error');
    }
  }
}

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> initialize() async {
    if (!isSupportedPlatform) return;

    await ensureInitialized();
    await AppMonitoringService.instance.initialize();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _initialized = true;
  }
}
