import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages FCM push notifications and local notifications for Haven.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'haven_notifications',
    'Haven Notifications',
    description: 'Notifications for device status, commands, and schedules.',
    importance: Importance.high,
  );

  /// Initialize local notification plugin and create Android channel.
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create high-importance Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Request notification permissions from the OS.
  Future<bool> requestPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Show a local notification immediately.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'haven_notifications',
      'Haven Notifications',
      channelDescription: 'Haven Smart Home notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  /// Handle FCM messages received while app is in foreground.
  void handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'Haven',
        body: notification.body ?? '',
        payload: message.data['route'],
      );
    }
  }

  /// Background FCM message handler — must be registered as a top-level function.
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // Firebase is already initialized by the time this runs
    // Log or store the message if needed
  }

  /// Get the current FCM registration token.
  Future<String?> getFcmToken() async {
    return FirebaseMessaging.instance.getToken();
  }

  /// Subscribe device to a FCM topic (e.g., home-specific alerts).
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  /// Unsubscribe device from a FCM topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

  /// Set up listeners for FCM message events.
  void setupMessageListeners({
    void Function(RemoteMessage)? onForeground,
    void Function(RemoteMessage?)? onMessageOpenedApp,
  }) {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      handleForegroundMessage(message);
      onForeground?.call(message);
    });

    // Background message tapped → app opened
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onMessageOpenedApp?.call(message);
    });
  }
}
