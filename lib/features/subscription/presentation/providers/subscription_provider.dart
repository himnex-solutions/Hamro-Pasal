import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_saoji/core/constants/app_constants.dart';
import 'package:smart_saoji/features/subscription/data/models/subscription_model.dart';

// ── Real-time subscription provider ──────────────────────────────────────────
// Uses Supabase Realtime so the user's subscription status updates instantly
// when the admin extends trial/subscription — no manual refresh needed.
final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, Subscription?>(
        SubscriptionNotifier.new);

class SubscriptionNotifier extends AsyncNotifier<Subscription?> {
  RealtimeChannel? _channel;
  String? _businessId;

  @override
  Future<Subscription?> build() async {
    // Clean up any previous channel when provider rebuilds
    await _channel?.unsubscribe();
    _channel = null;

    final prefs = await SharedPreferences.getInstance();
    _businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (_businessId == null) return null;

    // Initial fetch
    final result = await _fetch();

    // Subscribe to realtime changes on this business's subscription row
    _channel = Supabase.instance.client
        .channel('subscription_user_$_businessId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'subscriptions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: _businessId!,
          ),
          callback: (payload) async {
            // Re-fetch and update state whenever admin makes a change
            state = await AsyncValue.guard(_fetch);
          },
        )
        .subscribe();

    // Cancel the channel when the provider is disposed
    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    return result;
  }

  Future<Subscription?> _fetch() async {
    if (_businessId == null) return null;
    try {
      final res = await Supabase.instance.client
          .from('subscriptions')
          .select()
          .eq('business_id', _businessId!)
          .maybeSingle();
      if (res == null) return null;
      return Subscription.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  bool get hasAccess => state.valueOrNull?.hasAccess ?? true;
  bool get isTrialActive => state.valueOrNull?.isTrialActive ?? false;
  int get trialDaysLeft => state.valueOrNull?.trialDaysLeft ?? 0;
}

final subscriptionPlansProvider =
    FutureProvider<List<SubscriptionPlan>>((ref) async {
  final res = await Supabase.instance.client
      .from('subscription_plans')
      .select()
      .eq('is_active', true)
      .order('price');
  return (res as List)
      .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
      .toList();
});
