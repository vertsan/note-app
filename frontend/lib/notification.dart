import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin localNoti =
    FlutterLocalNotificationsPlugin();

Future<void> setupLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const macosInit = DarwinInitializationSettings();

  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
    macOS: macosInit,
  );

  await localNoti.initialize(settings: initSettings);

  if (Platform.isIOS) {
    await localNoti
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}

Future<void> showForegroundNotification(RemoteMessage message) async {
  final notification = message.notification;
  final title = notification?.title ?? message.data['title'] as String?;
  final body = notification?.body ?? message.data['body'] as String?;
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    return;
  }

  const androidDetails = AndroidNotificationDetails(
    'fcm_default_channel',
    'FCM Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBanner: true,
    presentList: true,
    presentSound: true,
    presentBadge: true,
  );

  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
    macOS: iosDetails,
  );

  final id = notification?.hashCode ?? message.messageId?.hashCode ?? 0;
  await localNoti.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: details,
  );
}

Future<void> showSimpleNotification(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'local_channel',
    'Local Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBanner: true,
    presentList: true,
    presentSound: true,
    presentBadge: true,
  );

  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
    macOS: iosDetails,
  );

  await localNoti.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title,
    body: body,
    notificationDetails: details,
  );
}

/// On iOS, APNs registration is async; FCM must not call [FirebaseMessaging.getToken] until
/// [FirebaseMessaging.getAPNSToken] is non-null (see firebase_messaging apns-token-not-set).
Future<void> _waitForIosApnsToken() async {
  if (!Platform.isIOS) return;
  const maxAttempts = 40;
  const delay = Duration(milliseconds: 250);
  for (var i = 0; i < maxAttempts; i++) {
    final apns = await FirebaseMessaging.instance.getAPNSToken();
    if (apns != null) return;
    await Future<void>.delayed(delay);
  }
  debugPrint(
    'FCM: APNs token still null after wait. Use a physical device, enable Push in Xcode, '
    'and ensure the app id has Push Notifications + APNs key in Firebase Console.',
  );
}

Future<void> setupFCM() async {
  // iOS permission + Android 13+ permission prompt (where applicable)
  try {
    await FirebaseMessaging.instance.requestPermission();
  } catch (e) {
    debugPrint('FCM permission request failed: $e');
  }

  if (Platform.isIOS) {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  await _waitForIosApnsToken();

  FirebaseMessaging.instance.onTokenRefresh.listen(
    (t) => debugPrint('FCM Token (refresh): $t'),
  );

  // Get device token (useful for testing)
  try {
    final token = await FirebaseMessaging.instance.getToken();
    print('\n====================================');
    print('FCM DEVICE TOKEN FOR TESTING:');
    print(token);
    print('====================================\n');
  } catch (e) {
    debugPrint('FCM getToken failed: $e');
  }

  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint(
      'FCM onMessage: id=${message.messageId} '
      'notification=${message.notification?.title} dataKeys=${message.data.keys.toList()}',
    );
    showForegroundNotification(message);
  });

  // When user taps notification and opens app (from background)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("Opened from notification: ${message.data}");
  });

  // If app was terminated and opened via notification
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint("Launched by notification: ${initialMessage.data}");
  }
}

/// Registered from [main] via [FirebaseMessaging.onBackgroundMessage] before [runApp].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM background message: ${message.messageId}');
}
