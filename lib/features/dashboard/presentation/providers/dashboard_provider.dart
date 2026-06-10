import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_saoji/core/constants/app_constants.dart';

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

    double todaySales = 0;
    double todayExpenses = 0;
    double receivables = 0;
    double payables = 0;
    int lowStock = 0;
    List<Map<String, dynamic>> recentTransactions = [];
    String subStatus = AppConstants.statusActive;
    int? trialDaysLeft;

    // 1. Fetch Today's Transactions
    try {
      final txRes = await supabase
          .from('transactions')
          .select('type, amount')
          .eq('business_id', businessId)
          .gte('transaction_date', todayStart);

      for (final tx in txRes as List) {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        if (tx['type'] == AppConstants.txSale) todaySales += amount;
        if (tx['type'] == AppConstants.txExpense ||
            tx['type'] == AppConstants.txPurchase) {
          todayExpenses += amount;
        }
      }
    } catch (e, st) {
      debugPrint('Dashboard Error (Today\'s Transactions): $e\n$st');
    }

    // 2. Fetch Today's General Expenses
    try {
      final expRes = await supabase
          .from('expenses')
          .select('amount')
          .eq('business_id', businessId)
          .gte('expense_date', todayStart);

      for (final exp in expRes as List) {
        todayExpenses += (exp['amount'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (e, st) {
      debugPrint('Dashboard Error (General Expenses): $e\n$st');
    }

    // 3. Fetch Party Balances (Receivables & Payables)
    try {
      final partyRes = await supabase
          .from('parties')
          .select('current_balance')
          .eq('business_id', businessId);

      for (final p in partyRes as List) {
        final bal = (p['current_balance'] as num?)?.toDouble() ?? 0.0;
        if (bal > 0) receivables += bal;
        if (bal < 0) payables += bal.abs();
      }
    } catch (e, st) {
      debugPrint('Dashboard Error (Party Balances): $e\n$st');
    }

    // 4. Fetch Low Stock Count
    try {
      final stockRes = await supabase
          .from('products')
          .select('stock_quantity, min_stock_alert')
          .eq('business_id', businessId)
          .eq('is_active', true);

      for (final p in stockRes as List) {
        final qty = (p['stock_quantity'] as num?)?.toDouble() ?? 0.0;
        final min = (p['min_stock_alert'] as num?)?.toDouble() ?? 5.0;
        if (qty <= min) lowStock++;
      }
    } catch (e, st) {
      debugPrint('Dashboard Error (Low Stock Count): $e\n$st');
    }

    // 5. Fetch Recent Transactions
    try {
      final recentRes = await supabase
          .from('transactions')
          .select(
              'id, type, amount, party_name, transaction_date, payment_method')
          .eq('business_id', businessId)
          .order('transaction_date', ascending: false)
          .limit(AppConstants.dashboardRecentTxCount);
      recentTransactions = (recentRes as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      debugPrint('Dashboard Error (Recent Transactions): $e\n$st');
    }

    // 6. Fetch Subscription Status
    try {
      final subRes = await supabase
          .from('subscriptions')
          .select('status, trial_end_date')
          .eq('business_id', businessId)
          .maybeSingle();

      if (subRes != null) {
        subStatus = subRes['status'] as String? ?? AppConstants.statusActive;
        if (subRes['trial_end_date'] != null) {
          final endDate = DateTime.parse(subRes['trial_end_date'] as String);
          trialDaysLeft = endDate.difference(now).inDays;
        }
      }
    } catch (e, st) {
      debugPrint('Dashboard Error (Subscription): $e\n$st');
    }

    return DashboardStats(
      todaySales: todaySales,
      todayExpenses: todayExpenses,
      totalReceivables: receivables,
      totalPayables: payables,
      todayProfit: todaySales - todayExpenses,
      lowStockCount: lowStock,
      recentTransactions: recentTransactions,
      subscriptionStatus: subStatus,
      trialDaysLeft: trialDaysLeft,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}
