import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings: settings);
  }

  Future<bool> requestPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await androidPlugin?.requestNotificationsPermission() ?? true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'eAutoShop obavijesti',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
