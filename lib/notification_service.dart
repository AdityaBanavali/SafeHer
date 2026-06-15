import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse details) {}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios, macOS: ios),
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  Future<void> showNotification({required int id, required String title, required String body, required String payload}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'fall_detection_channel', 'Fall Alerts', importance: Importance.max, priority: Priority.high);
    await _plugin.show(id, title, body, const NotificationDetails(android: androidDetails), payload: payload);
  }
}