import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  static Future<void> showDemoReminder() async {
    if (kIsWeb) return;
    const android = AndroidNotificationDetails(
      'medid_reminders',
      'Medication reminders',
      channelDescription: 'Local placeholder reminders before FCM setup.',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      1001,
      'MedID Connect',
      'Medication reminder placeholder is ready.',
      const NotificationDetails(android: android),
    );
  }
}
