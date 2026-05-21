import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';

class DashboardStats {
  final double todaySales;
  final double todayExpenses;
  final double totalReceivables;
  final double totalPayables;
  final double todayProfit;
  final int lowStockCount;
  final List<Map<String, dynamic>> recentTransactions;
  final String subscriptionStatus;
  final int? trialDaysLeft;

  const DashboardStats({
    this.todaySales = 0,
    this.todayExpenses = 0,
    this.totalReceivables = 0,
    this.totalPayables = 0,
    this.todayProfit = 0,
    this.lowStockCount = 0,
    this.recentTransactions = const [],
    this.subscriptionStatus = 'active',
    this.trialDaysLeft,
  });
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardStats>(() {
  return DashboardNotifier();
});

class DashboardNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() => _fetch();

  Future<DashboardStats> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId == null) return const DashboardStats();

    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

    try {
      // Today's transactions
      final txRes = await supabase
          .from('transactions')
          .select('type, amount')
          .eq('business_id', businessId)
          .gte('transaction_date', todayStart);

      double todaySales = 0, todayExpenses = 0;
      for (final tx in txRes as List) {
        final amount = (tx['amount'] as num).toDouble();
        if (tx['type'] == AppConstants.txSale) todaySales += amount;
        if (tx['type'] == AppConstants.txExpense ||
            tx['type'] == AppConstants.txPurchase) {
          todayExpenses += amount;
        }
      }

      // Today's general expenses from the expenses table
      final expRes = await supabase
          .from('expenses')
          .select('amount')
          .eq('business_id', businessId)
          .gte('expense_date', todayStart);

      for (final exp in expRes as List) {
        todayExpenses += (exp['amount'] as num).toDouble();
      }

      // Party balances (receivables/payables)
      final partyRes = await supabase
          .from('parties')
          .select('current_balance')
          .eq('business_id', businessId);

      double receivables = 0, payables = 0;
      for (final p in partyRes as List) {
        final bal = (p['current_balance'] as num).toDouble();
        if (bal > 0) receivables += bal;
        if (bal < 0) payables += bal.abs();
      }

      // Low stock count
      final stockRes = await supabase
          .from('products')
          .select('stock_quantity, min_stock_alert')
          .eq('business_id', businessId)
          .eq('is_active', true);

      int lowStock = 0;
      for (final p in stockRes as List) {
        final qty = (p['stock_quantity'] as num).toDouble();
        final min = (p['min_stock_alert'] as num).toDouble();
        if (qty <= min) lowStock++;
      }

      // Recent transactions (last 5)
      final recentRes = await supabase
          .from('transactions')
          .select(
              'id, type, amount, party_name, transaction_date, payment_method')
          .eq('business_id', businessId)
          .order('transaction_date', ascending: false)
          .limit(AppConstants.dashboardRecentTxCount);

      // Subscription status
      final subRes = await supabase
          .from('subscriptions')
          .select('status, trial_end_date')
          .eq('business_id', businessId)
          .maybeSingle();

      String subStatus = AppConstants.statusActive;
      int? trialDaysLeft;
      if (subRes != null) {
        subStatus = subRes['status'] as String? ?? AppConstants.statusActive;
        if (subRes['trial_end_date'] != null) {
          final endDate = DateTime.parse(subRes['trial_end_date'] as String);
          trialDaysLeft = endDate.difference(now).inDays;
        }
      }

      return DashboardStats(
        todaySales: todaySales,
        todayExpenses: todayExpenses,
        totalReceivables: receivables,
        totalPayables: payables,
        todayProfit: todaySales - todayExpenses,
        lowStockCount: lowStock,
        recentTransactions: (recentRes as List).cast<Map<String, dynamic>>(),
        subscriptionStatus: subStatus,
        trialDaysLeft: trialDaysLeft,
      );
    } catch (e) {
      return const DashboardStats();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}
