import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
  }

  static Future<void> showLowStockAlert(String productName) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'low_stock', 'Low Stock Alerts',
        channelDescription: 'Alerts when product stock is low',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      1,
      '⚠️ Low Stock Alert',
      '$productName is running low on stock',
      details,
    );
  }

  static Future<void> showTrialReminderAlert(int daysLeft) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'trial_reminder', 'Trial Reminders',
        channelDescription: 'Reminders about free trial expiry',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      2,
      '🚀 Free Trial Ending Soon',
      '$daysLeft days left in your free trial. Subscribe to keep your data.',
      details,
    );
  }

  static Future<void> showSyncFailedAlert() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sync_status', 'Sync Status',
        channelDescription: 'Sync status notifications',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      3,
      'Sync Warning',
      'Some offline data failed to sync. Will retry when connected.',
      details,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
