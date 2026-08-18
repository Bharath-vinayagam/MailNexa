import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging service for handling push notifications.
class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[FCM] Permission granted');
    }

    // Configure Local Notifications channel
    const androidChannel = AndroidNotificationChannel(
      'high_priority',
      'High Priority Email Alerts',
      description: 'Notifications for high priority placement emails and deadlines',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initSettingsAndroid = AndroidInitializationSettings('@drawable/launch_background');
    const initSettingsIOS = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: initSettingsAndroid, iOS: initSettingsIOS),
    );

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[FCM Token] $token');
    }

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              androidChannel.id,
              androidChannel.name,
              channelDescription: androidChannel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  static Future<String?> getToken() => _messaging.getToken();

  /// Displays an instant local alert notification.
  static Future<void> showNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_priority',
      'High Priority Email Alerts',
      channelDescription: 'Notifications for high priority placement emails and deadlines',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }
}
