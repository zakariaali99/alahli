import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

class PushService {
  static final PushService _instance = PushService._internal();
  factory PushService() => _instance;
  PushService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  GoRouter? _router;

  static const String _channelId = 'alahli_admin_channel';
  static const String _channelName = 'تنبيهات الإدارة';
  static const String _channelDesc = 'تنبيهات الطلبات الجديدة والاشتراكات المنتهية';

  void setRouter(GoRouter router) {
    _router = router;
  }

  Future<void> initialize() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          _handleNotificationClick(details.payload!);
        }
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(_extractPayload(message));
    });

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(_extractPayload(initialMessage));
    }

    _fcm.onTokenRefresh.listen((String token) {
      _onTokenRefresh?.call(token);
    });
  }

  void Function(String token)? _onTokenRefresh;
  void setOnTokenRefresh(void Function(String token) callback) {
    _onTokenRefresh = callback;
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: _extractPayload(message),
    );
  }

  String _extractPayload(RemoteMessage message) {
    return jsonEncode(message.data);
  }

  void _handleNotificationClick(String payload) {
    if (_router == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'new_registration':
          _router?.go('/dashboard/approvals');
          break;
        case 'new_subscription':
          _router?.go('/dashboard/approvals');
          break;
        case 'subscription_expired':
          _router?.go('/dashboard/subscriptions');
          break;
        default:
          _router?.go('/dashboard');
      }
    } catch (_) {
      _router?.go('/dashboard');
    }
  }

  Future<String?> getFCMToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }
}
