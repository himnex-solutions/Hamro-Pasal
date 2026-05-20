import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hamro_pasal/core/services/notification_service.dart';
import 'package:intl/intl.dart';


class SubscriptionState {
  final String planCode;
  final DateTime? expiryDate;
  final String status;
  final Set<String> allowedFeatures;
  final int maxStaff;
  final int maxBusinesses;

  const SubscriptionState({
    required this.planCode,
    this.expiryDate,
    required this.status,
    required this.allowedFeatures,
    required this.maxStaff,
    required this.maxBusinesses,
  });

  factory SubscriptionState.basic() {
    return const SubscriptionState(
      planCode: 'basic',
      expiryDate: null,
      status: 'active',
      allowedFeatures: {},
      maxStaff: 0,
      maxBusinesses: 1,
    );
  }

  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    return SubscriptionState(
      planCode: json['plan_code'] as String? ?? 'basic',
      expiryDate: json['expiry_date'] != null ? DateTime.tryParse(json['expiry_date'] as String) : null,
      status: json['status'] as String? ?? 'active',
      allowedFeatures: Set<String>.from(json['allowed_features'] as List<dynamic>? ?? []),
      maxStaff: json['max_staff'] as int? ?? 0,
      maxBusinesses: json['max_businesses'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_code': planCode,
      'expiry_date': expiryDate?.toIso8601String(),
      'status': status,
      'allowed_features': allowedFeatures.toList(),
      'max_staff': maxStaff,
      'max_businesses': maxBusinesses,
    };
  }

  bool get isActive => status == 'active' && (expiryDate == null || expiryDate!.isAfter(DateTime.now()));

  bool checkFeatureAccess(String featureName) {
    if (planCode == 'basic') {
      return false;
    }
    if (!isActive) {
      return false;
    }
    return allowedFeatures.contains(featureName);
  }
}

final subscriptionManagerProvider = StateNotifierProvider<SubscriptionManager, SubscriptionState>((ref) {
  return SubscriptionManager();
});

class SubscriptionManager extends StateNotifier<SubscriptionState> {
  SubscriptionManager() : super(SubscriptionState.basic()) {
    _init();
  }

  static const String _kSubscriptionCacheKey = 'cached_user_subscription';
  final _supabase = Supabase.instance.client;

  Future<void> _init() async {
    // 1. Load from offline cache
    await _loadFromCache();

    // 2. Fetch fresh data if authenticated, and listen for realtime updates
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await syncSubscription();
      _setupRealtimeSubscription(session.user.id);
      _setupRealtimePaymentRequests(session.user.id);
      _checkExpiryAndReminders();
    }

    // 3. Listen to auth changes to re-fetch/clean up
    _supabase.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        await syncSubscription();
        _setupRealtimeSubscription(user.id);
        _setupRealtimePaymentRequests(user.id);
        _checkExpiryAndReminders();
      } else {
        // Clear on logout
        state = SubscriptionState.basic();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kSubscriptionCacheKey);
        _paymentChannel?.unsubscribe();
      }
    });
  }

  RealtimeChannel? _channel;
  RealtimeChannel? _paymentChannel;

  void _setupRealtimeSubscription(String userId) {
    _channel?.unsubscribe();
    _channel = _supabase
        .channel('user_subscription_channel_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_subscriptions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            await syncSubscription();
          },
        )
        .subscribe();
  }

  void _setupRealtimePaymentRequests(String userId) {
    _paymentChannel?.unsubscribe();
    _paymentChannel = _supabase
        .channel('user_payment_requests_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'payment_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            final newRec = payload.newRecord;
            final status = newRec['status'] as String?;
            final plan = (newRec['plan_code'] as String? ?? '').toUpperCase();
            
            if (status == 'approved') {
              await NotificationService.showSubscriptionApprovedAlert(plan);
              await syncSubscription();
            } else if (status == 'rejected') {
              final reason = newRec['rejection_reason'] as String? ?? 'No reason provided';
              await NotificationService.showSubscriptionRejectedAlert(plan, reason);
            }
          },
        )
        .subscribe();
  }

  Future<void> _checkExpiryAndReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Expiry check
      if (state.expiryDate != null && state.isActive) {
        final daysLeft = state.expiryDate!.difference(DateTime.now()).inDays;
        if (daysLeft >= 0 && daysLeft <= 7) {
          final lastAlertStr = prefs.getString('last_expiry_alert_date');
          final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          if (lastAlertStr != todayStr) {
            await NotificationService.showSubscriptionExpiryAlert(daysLeft);
            await prefs.setString('last_expiry_alert_date', todayStr);
          }
        }
      }
      
      // Upgrade reminder check (for Basic users)
      if (state.planCode == 'basic') {
        final lastReminder = prefs.getInt('last_upgrade_reminder_timestamp') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        // Show reminder at most once every 7 days (7 * 24 * 60 * 60 * 1000 ms)
        if (now - lastReminder > 7 * 24 * 60 * 60 * 1000) {
          await NotificationService.showUpgradeReminderAlert();
          await prefs.setInt('last_upgrade_reminder_timestamp', now);
        }
      }
    } catch (_) {}
  }


  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_kSubscriptionCacheKey);
      if (cachedStr != null) {
        final decoded = jsonDecode(cachedStr) as Map<String, dynamic>;
        state = SubscriptionState.fromJson(decoded);
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(SubscriptionState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSubscriptionCacheKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  /// Syncs active subscription and limits from Supabase
  Future<void> syncSubscription() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. Fetch user subscription details
      final subRes = await _supabase
          .from('user_subscriptions')
          .select('plan_code, expiry_date, status')
          .eq('user_id', userId)
          .maybeSingle();

      if (subRes == null) {
        // Default to basic if no subscription found
        state = SubscriptionState.basic();
        await _saveToCache(state);
        return;
      }

      final planCode = subRes['plan_code'] as String? ?? 'basic';
      final expiryStr = subRes['expiry_date'] as String?;
      final expiryDate = expiryStr != null ? DateTime.parse(expiryStr) : null;
      final status = subRes['status'] as String? ?? 'active';

      // 2. Fetch feature permissions, staff and business limits for this plan
      final permissions = await _supabase.from('feature_permissions').select('feature_name, is_allowed').eq('plan_code', planCode);
      final staffLimit = await _supabase.from('staff_limits').select('max_staff').eq('plan_code', planCode).maybeSingle();
      final bizLimit = await _supabase.from('business_limits').select('max_businesses').eq('plan_code', planCode).maybeSingle();


      final allowedFeatures = permissions
          .where((p) => p['is_allowed'] as bool == true)
          .map((p) => p['feature_name'] as String)
          .toSet();

      final maxStaff = staffLimit?['max_staff'] as int? ?? 0;
      final maxBusinesses = bizLimit?['max_businesses'] as int? ?? 1;

      final newState = SubscriptionState(
        planCode: planCode,
        expiryDate: expiryDate,
        status: status,
        allowedFeatures: allowedFeatures,
        maxStaff: maxStaff,
        maxBusinesses: maxBusinesses,
      );

      state = newState;
      await _saveToCache(newState);
    } catch (_) {
      // Fallback to offline cache if sync fails
      await _loadFromCache();
    }
  }

  // ── Central Feature Access Control API ──
  
  /// Checks if the given feature is allowed in the current plan.
  /// If the subscription is expired or suspended, always returns false for premium features.
  bool checkFeatureAccess(String featureName) {
    if (state.planCode == 'basic') {
      return false; // Basic plan has no premium features
    }
    
    // Check if the plan status is active and not expired
    if (!state.isActive) {
      return false;
    }
    
    return state.allowedFeatures.contains(featureName);
  }

  String get currentSubscriptionPlan => state.planCode;
  DateTime? get expiryDate => state.expiryDate;
  String get subscriptionStatus => state.status;
  int get allowedBusinessCount => state.maxBusinesses;
  int get allowedStaffCount => state.maxStaff;
}
