import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';



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

  factory InAppNotification.fromSupabase(Map<String, dynamic> json) => InAppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['message'] as String,
        timestamp: DateTime.parse(json['created_at'] as String),
        type: json['type'] as String? ?? 'info',
        isRead: json['is_read'] as bool? ?? false,
      );
}

// ── In-App Notification Center Notifier ────────────────────────
final inAppNotificationsProvider =
    StateNotifierProvider<InAppNotificationsNotifier, List<InAppNotification>>((ref) {
  return InAppNotificationsNotifier();
});

class InAppNotificationsNotifier extends StateNotifier<List<InAppNotification>> {
  RealtimeChannel? _channel;

  InAppNotificationsNotifier() : super([]) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      state = [];
      return;
    }

    try {
      final res = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      state = (res as List).map((e) => InAppNotification.fromSupabase(e)).toList();
    } catch (_) {}

    _setupRealtimeSubscription(userId);
  }

  void _setupRealtimeSubscription(String userId) {
    _channel?.unsubscribe();
    final client = Supabase.instance.client;
    _channel = client
        .channel('user_notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final eventType = payload.eventType;
            final record = payload.newRecord;
            final oldRecord = payload.oldRecord;

            if (eventType == PostgresChangeEvent.insert && record.isNotEmpty) {
              final newNotif = InAppNotification.fromSupabase(record);
              if (!state.any((n) => n.id == newNotif.id)) {
                state = [newNotif, ...state];
                NotificationService.showLocalNotification(
                  newNotif.title,
                  newNotif.body,
                  newNotif.type,
                );
              }
            } else if (eventType == PostgresChangeEvent.update && record.isNotEmpty) {
              final updatedNotif = InAppNotification.fromSupabase(record);
              state = state.map((n) => n.id == updatedNotif.id ? updatedNotif : n).toList();
            } else if (eventType == PostgresChangeEvent.delete && oldRecord.isNotEmpty) {
              final deletedId = oldRecord['id'] as String;
              state = state.where((n) => n.id != deletedId).toList();
            }
          },
        );
    _channel?.subscribe();
  }

  Future<void> markAsRead(String id) async {
    try {
      final client = Supabase.instance.client;
      await client.from('notifications').update({'is_read': true}).eq('id', id);
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
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await client.from('notifications').update({'is_read': true}).eq('user_id', userId).eq('is_read', false);
      state = state.map((n) => InAppNotification(
            id: n.id,
            title: n.title,
            body: n.body,
            timestamp: n.timestamp,
            type: n.type,
            isRead: true,
          )).toList();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await client.from('notifications').delete().eq('user_id', userId);
      state = [];
    } catch (_) {}
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// ── System & Local Notification Service ────────────────────────
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

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

    // Initialize Firebase Cloud Messaging (FCM)
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        await Firebase.initializeApp();
        final messaging = FirebaseMessaging.instance;
        
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            showLocalNotification(
              notification.title ?? 'Notification',
              notification.body ?? '',
              message.data['type'] ?? 'info',
            );
          }
        });
      }
    } catch (e) {
      debugPrint('FCM Initialization failed or skipped: $e');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Background message callback
  }

  static Future<void> registerFcmToken() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          final deviceType = defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios';
          await client.from('user_devices').upsert({
            'user_id': userId,
            'fcm_token': fcmToken,
            'device_type': deviceType,
          }, onConflict: 'fcm_token');
          debugPrint('FCM Token registered: $fcmToken');
        }
      }
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  static Future<void> showLocalNotification(String title, String body, String type) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'realtime_notifications',
        'Realtime Notifications',
        channelDescription: 'Realtime updates for database notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _plugin.show(id, title, body, details);
  }

  static Future<void> _saveNotification(String title, String body, String type) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await client.from('notifications').insert({
          'user_id': userId,
          'title': title,
          'message': body,
          'type': type,
        });
      }
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

    final dateStr = '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year} at ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}';
    await _saveNotification(
      '📅 Reminder Scheduled',
      'You will be reminded to collect/pay Rs. ${amount.toInt()} for $targetParty on $dateStr.',
      'info',
    );

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
