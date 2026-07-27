import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// In-app notification service.
/// Call [NotificationService.instance.init()] once in main().
/// Then use [show()] from anywhere to fire a local notification.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);

    // Request Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'nowaito_channel',
      'NoWaito Notifications',
      channelDescription: 'Ride status, driver assignment, and safety alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(id, title, body, details, payload: payload);
  }

  // ── Convenience helpers — call these from screens ─────────────────────────

  Future<void> driverAssigned(String driverName, String vehicle, String eta) =>
      show(id: 1, title: '🚗 Driver Assigned', body: '$driverName in a $vehicle · arriving in $eta');

  Future<void> driverArrived() =>
      show(id: 2, title: '📍 Driver Arrived', body: 'Your driver is at the pickup point. Please board now.');

  Future<void> tripStarted() =>
      show(id: 3, title: '▶️ Trip Started', body: 'Your ride has started. Have a safe journey!');

  Future<void> tripComplete(int total) =>
      show(id: 4, title: '✅ Trip Complete', body: '₹$total has been charged. Thank you for riding with NoWaito!');

  Future<void> safetyCheck() =>
      show(id: 5, title: '🛡️ Safety Check', body: 'Did you arrive safely? Tap to confirm.');

  Future<void> rideAssignedToDriver(String pickup, int fare) =>
      show(id: 10, title: '🔔 New Ride Assigned', body: 'Pickup: $pickup · Fare: ₹$fare · Navigate now.');

  Future<void> tripCompletedDriver(int fare) =>
      show(id: 11, title: '💰 Trip Complete', body: '₹$fare will be credited within 15 minutes.');

  Future<void> cancelledByRider() =>
      show(id: 12, title: 'Ride Cancelled', body: 'Rider cancelled the trip. Returning you to the queue.');
}
