import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../models/subscription.dart';

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<Subscription?>>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<Subscription?>> {
  SubscriptionNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final json = await SupabaseService.instance.getSubscription(userId);
      state = AsyncValue.data(
          json != null ? Subscription.fromJson(json) : null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> activate(SubscriptionPlan plan, {String? paymentMethod, String? txId}) async {
    final userId = SupabaseService.instance.currentUserId!;
    final now = DateTime.now();
    DateTime end;
    switch (plan) {
      case SubscriptionPlan.monthly:
        end = now.add(const Duration(days: 30));
        break;
      case SubscriptionPlan.sixMonth:
        end = now.add(const Duration(days: 180));
        break;
      case SubscriptionPlan.yearly:
        end = now.add(const Duration(days: 365));
        break;
      case SubscriptionPlan.free:
        end = now.add(const Duration(days: 14));
        break;
    }

    final sub = Subscription(
      id: '',
      userId: userId,
      planType: plan,
      startDate: now,
      endDate: end,
      status: plan == SubscriptionPlan.free
          ? SubscriptionStatus.trial
          : SubscriptionStatus.active,
      paymentMethod: paymentMethod,
      transactionId: txId,
      createdAt: now,
    );

    await SupabaseService.instance.upsertSubscription(sub.toJson());
    await load();
  }

  bool hasFeature(String feature) {
    final sub = state.valueOrNull;
    if (sub == null) {
      return false;
    }
    if (!sub.isActive && !sub.isTrial) {
      return false;
    }

    const freeFeatures = ['basic_billing', 'basic_reports'];
    if (sub.isTrial || sub.planType == SubscriptionPlan.free) {
      return freeFeatures.contains(feature);
    }
    return true;
  }
}
