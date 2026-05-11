import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/features/subscription/data/models/subscription_model.dart';

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, Subscription?>(() {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends AsyncNotifier<Subscription?> {
  @override
  Future<Subscription?> build() => _fetch();

  Future<Subscription?> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId == null) return null;

    try {
      final res = await Supabase.instance.client
          .from('subscriptions')
          .select()
          .eq('business_id', businessId)
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

  bool get hasAccess {
    return state.valueOrNull?.hasAccess ?? true;
  }

  bool get isTrialActive {
    return state.valueOrNull?.isTrialActive ?? false;
  }

  int get trialDaysLeft {
    return state.valueOrNull?.trialDaysLeft ?? 0;
  }
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
