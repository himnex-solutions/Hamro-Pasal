import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// ── In-App Notification Model ─────────────────────────────────
class InAppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'success', 'warning', 'info', 'error'
  final bool isRead;

  const InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'isRead': isRead,
      };

  factory InAppNotification.fromJson(Map<String, dynamic> json) => InAppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: json['type'] as String? ?? 'info',
        isRead: json['isRead'] as bool? ?? false,
      );
}

// ── In-App Notification Center Notifier ────────────────────────
final inAppNotificationsProvider =
    StateNotifierProvider<InAppNotificationsNotifier, List<InAppNotification>>((ref) {
  return InAppNotificationsNotifier();
});

class InAppNotificationsNotifier extends StateNotifier<List<InAppNotification>> {
  InAppNotificationsNotifier() : super([]) {
    loadNotifications();
  }

  static const String kKey = 'in_app_notifications_list';

  Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(kKey);
      if (data != null) {
        final List decoded = jsonDecode(data);
        state = decoded.map((e) => InAppNotification.fromJson(e)).toList();
      } else {
        state = [];
      }
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    state = state.map((n) => n.id == id
        ? InAppNotification(
            id: n.id,
            title: n.title,
            body: n.body,
            timestamp: n.timestamp,
            type: n.type,
            isRead: true,
          )
        : n).toList();
    await _save();
  }

  Future<void> markAllAsRead() async {
    state = state.map((n) => InAppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          timestamp: n.timestamp,
          type: n.type,
          isRead: true,
        )).toList();
    await _save();
  }

  Future<void> clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kKey);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kKey, jsonEncode(state.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
}

// ── System & Local Notification Service ────────────────────────
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const String _kKey = InAppNotificationsNotifier.kKey;

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
  }

  // Helper to persist notifications locally for In-App Notification Center
  static Future<void> _saveNotification(String title, String body, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_kKey);
      List<InAppNotification> current = [];
      if (data != null) {
        final List decoded = jsonDecode(data);
        current = decoded.map((e) => InAppNotification.fromJson(e)).toList();
      }
      final newNotif = InAppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: type,
      );
      // Keep last 50 notifications to optimize storage
      final updated = [newNotif, ...current];
      if (updated.length > 50) {
        updated.removeRange(50, updated.length);
      }
      await prefs.setString(_kKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> showLowStockAlert(String productName) async {
    const title = '⚠️ Low Stock Alert';
    final body = '$productName is running low on stock';
    
    await _saveNotification(title, body, 'warning');

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'low_stock',
        'Low Stock Alerts',
        channelDescription: 'Alerts when product stock is low',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(1, title, body, details);
  }

  static Future<void> showTrialReminderAlert(int daysLeft) async {
    const title = 'Free Trial Ending Soon';
    final body = '$daysLeft day(s) left in your free trial!';

    await _saveNotification(title, body, 'info');

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'trial_reminder',
        'Trial Reminders',
        channelDescription: 'Reminders about free trial expiry',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(2, title, body, details);
  }

  static Future<void> showSyncFailedAlert() async {
    const title = 'Sync Warning';
    const body = 'Some offline data failed to sync. Will retry when connected.';

    await _saveNotification(title, body, 'error');

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sync_status',
        'Sync Status',
        channelDescription: 'Sync status notifications',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(3, title, body, details);
  }

  static Future<void> showSubscriptionApprovedAlert(String plan) async {
    const title = '🎉 Subscription Approved!';
    final body = '$plan Plan is now active. Welcome aboard! 🎉';

    await _saveNotification(title, body, 'success');

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'subscription_alerts',
        'Subscription Alerts',
        channelDescription: 'Alerts when subscription changes',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(4, title, body, details);
  }

  static Future<void> showSubscriptionRejectedAlert(String plan, String reason) async {
    const title = '❌ Upgrade Request Rejected';
    final body = '$plan payment rejected. Tap to resubmit.';

    await _saveNotification(title, body, 'error');

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'subscription_alerts',
        'Subscription Alerts',
        channelDescription: 'Alerts when subscription changes',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(5, title, body, details);
  }

  static Future<void> showSubscriptionExpiryAlert(int daysLeft) async {
    const title = '⚠️ Subscription Expiring Soon';
    final body = 'Expires in $daysLeft day(s). Renew to continue.';

    await _saveNotification(title, body, 'warning');

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'subscription_expiry',
        'Subscription Expirations',
        channelDescription: 'Alerts before subscription expires',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(6, title, body, details);
  }

  static Future<void> showUpgradeReminderAlert() async {
    const title = '🚀 Grow Your Business';
    const body = 'Unlock barcode scanner, printer & more. Upgrade now!';

    await _saveNotification(title, body, 'info');

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'upgrade_reminders',
        'Upgrade Reminders',
        channelDescription: 'Reminders to upgrade to premium plans',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(7, title, body, details);
  }

  static Future<void> showCreditReminderAlert({
    required String type,
    required String? partyName,
    required double amount,
  }) async {
    final isIncome = type == 'sale' || type == 'income';
    final title = isIncome ? '💰 Collect Payment' : '💸 Pay Credit';
    final targetParty = (partyName != null && partyName.trim().isNotEmpty) ? partyName : 'Customer/Supplier';
    final body = isIncome
        ? 'Reminder: Collect Rs. ${amount.toInt()} from $targetParty soon.'
        : 'Reminder: Pay Rs. ${amount.toInt()} to $targetParty soon.';

    await _saveNotification(title, body, 'warning');

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'credit_alerts',
        'Credit Reminders',
        channelDescription: 'Alerts when transaction is done on credit',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(8, title, body, details);
  }

  static Future<void> scheduleCreditReminder({
    required String type,
    required String? partyName,
    required double amount,
    required DateTime scheduledDate,
  }) async {
    final isIncome = type == 'sale' || type == 'income';
    final title = isIncome ? '⏰ Collect Payment' : '⏰ Pay Credit';
    final targetParty = (partyName != null && partyName.trim().isNotEmpty) ? partyName : 'Customer/Supplier';
    final body = isIncome
        ? 'Reminder: Collect Rs. ${amount.toInt()} from $targetParty today.'
        : 'Reminder: Pay Rs. ${amount.toInt()} to $targetParty today.';

    // Create in-app notification immediately
    final dateStr = '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year} at ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}';
    await _saveNotification(
      '📅 Reminder Scheduled',
      'You will be reminded to collect/pay Rs. ${amount.toInt()} for $targetParty on $dateStr.',
      'info',
    );

    // Schedule local notification
    final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'scheduled_credit_alerts',
        'Scheduled Credit Reminders',
        channelDescription: 'Scheduled alerts when transaction is done on credit',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    // Clean unique integer ID for notifications
    final intNotifId = (scheduledDate.millisecondsSinceEpoch ~/ 1000) & 0x7FFFFFFF;

    await _plugin.zonedSchedule(
      intNotifId,
      title,
      body,
      tzScheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
