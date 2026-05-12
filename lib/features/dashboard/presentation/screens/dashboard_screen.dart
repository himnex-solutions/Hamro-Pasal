import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/providers/profile_mode_provider.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:hamro_pasal/features/dashboard/presentation/screens/personal_dashboard_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(profileModeProvider);

    // Switch between personal and business dashboard
    if (mode == ProfileMode.personal) {
      return const PersonalDashboardScreen();
    }

    final dashAsync = ref.watch(dashboardProvider);

    return Scaffold(
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text('Failed to load dashboard', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              _DashboardAppBar(stats: stats),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Trial banner
                    if (stats.subscriptionStatus == AppConstants.statusTrialActive &&
                        (stats.trialDaysLeft ?? 14) <= 7)
                      _TrialBanner(daysLeft: stats.trialDaysLeft ?? 0)
                          .animate().fadeIn().slideY(begin: -0.1, end: 0),

                    if (stats.subscriptionStatus == AppConstants.statusTrialExpired)
                      _ExpiredBanner().animate().fadeIn(),

                    const SizedBox(height: 4),

                    // Stats grid
                    Text('Today\'s Overview',
                        style: Theme.of(context).textTheme.titleLarge)
                        .animate().fadeIn(),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StatCard('Today\'s Sales', stats.todaySales,
                            AppTheme.successColor, Icons.trending_up_rounded, 0),
                        _StatCard('Today\'s Expenses', stats.todayExpenses,
                            AppTheme.errorColor, Icons.trending_down_rounded, 1),
                        _StatCard('Receivables', stats.totalReceivables,
                            AppTheme.infoColor, Icons.account_balance_wallet_outlined, 2),
                        _StatCard('Payables', stats.totalPayables,
                            AppTheme.warningColor, Icons.payments_outlined, 3),
                      ],
                    ).animate(delay: 50.ms).fadeIn(),

                    const SizedBox(height: 16),

                    // Profit card
                    _ProfitCard(profit: stats.todayProfit)
                        .animate(delay: 150.ms).fadeIn().slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 20),

                    // Quick actions
                    Text('Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge)
                        .animate(delay: 200.ms).fadeIn(),
                    const SizedBox(height: 12),
                    _QuickActions().animate(delay: 250.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // Low stock alert
                    if (stats.lowStockCount > 0)
                      _LowStockBanner(count: stats.lowStockCount)
                          .animate(delay: 300.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // Recent transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Transactions',
                            style: Theme.of(context).textTheme.titleLarge),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.transactions),
                          child: const Text('View All'),
                        ),
                      ],
                    ).animate(delay: 350.ms).fadeIn(),
                    const SizedBox(height: 8),
                    if (stats.recentTransactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text('No transactions yet',
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      )
                    else
                      ...stats.recentTransactions.asMap().entries.map((entry) {
                        final tx = entry.value;
                        final type = tx['type'] as String;
                        final amount = (tx['amount'] as num).toDouble();
                        final isIncome = type == AppConstants.txSale || type == AppConstants.txIncome;
                        final color = isIncome ? AppTheme.successColor : AppTheme.errorColor;
                        final date = DateTime.parse(tx['transaction_date'] as String);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                color: color, size: 20,
                              ),
                            ),
                            title: Text(tx['party_name'] as String? ?? type.toUpperCase(),
                                style: Theme.of(context).textTheme.titleMedium),
                            subtitle: Text(DateFormat('dd MMM, hh:mm a').format(date),
                                style: Theme.of(context).textTheme.bodySmall),
                            trailing: Text(
                              '${isIncome ? '+' : '-'}${AppConstants.currencySymbol} ${NumberFormat('#,##,##0').format(amount)}',
                              style: TextStyle(color: color, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ).animate(delay: Duration(milliseconds: 400 + entry.key * 50)).fadeIn();
                      }),

                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardAppBar extends ConsumerWidget {
  final DashboardStats stats;
  const _DashboardAppBar({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = _getGreeting();
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(greeting,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  // Active mode pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.store_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Business Mode',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.subscription),
          icon: const Icon(Icons.workspace_premium_outlined, color: Colors.white),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final int delayMultiplier;
  const _StatCard(this.title, this.amount, this.color, this.icon, this.delayMultiplier);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 22),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppConstants.currencySymbol} ${NumberFormat('#,##,##0').format(amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(title, style: Theme.of(context).textTheme.bodySmall, maxLines: 1),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfitCard extends StatelessWidget {
  final double profit;
  const _ProfitCard({required this.profit});

  @override
  Widget build(BuildContext context) {
    final isPositive = profit >= 0;
    final color = isPositive ? AppTheme.successColor : AppTheme.errorColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Net Profit", style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                '${isPositive ? '' : '-'}${AppConstants.currencySymbol} ${NumberFormat('#,##,##0.00').format(profit.abs())}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          Icon(isPositive ? Icons.emoji_events_outlined : Icons.sentiment_dissatisfied_outlined,
              color: color, size: 36),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      const _QA('New Sale', Icons.point_of_sale_rounded, AppTheme.successColor, AppRoutes.addTransaction),
      const _QA('Add Purchase', Icons.shopping_bag_outlined, AppTheme.infoColor, AppRoutes.addTransaction),
      const _QA('Add Party', Icons.person_add_outlined, AppTheme.primaryColor, AppRoutes.addParty),
      const _QA('Add Product', Icons.add_box_outlined, AppTheme.accentColor, AppRoutes.addProduct),
      const _QA('Add Expense', Icons.wallet_outlined, AppTheme.errorColor, AppRoutes.addExpense),
      const _QA('Reports', Icons.bar_chart_rounded, AppTheme.warningColor, AppRoutes.reports),
    ];
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10, mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions.asMap().entries.map((entry) {
        final a = entry.value;
        return InkWell(
          onTap: () => context.push(a.route),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: a.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: a.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a.icon, color: a.color, size: 28),
                const SizedBox(height: 6),
                Text(a.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: a.color, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center, maxLines: 2),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QA {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QA(this.label, this.icon, this.color, this.route);
}

class _TrialBanner extends StatelessWidget {
  final int daysLeft;
  const _TrialBanner({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.accentDark, AppTheme.accentColor]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$daysLeft days left in your free trial!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.subscription),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }
}

class _ExpiredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_off_outlined, color: AppTheme.errorColor, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Your free trial has expired.',
                style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.trialExpired),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Subscribe Now'),
          ),
        ],
      ),
    );
  }
}

class _LowStockBanner extends StatelessWidget {
  final int count;
  const _LowStockBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: AppTheme.warningColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$count product${count > 1 ? 's' : ''} running low on stock.',
                style: const TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.inventory),
            style: TextButton.styleFrom(foregroundColor: AppTheme.warningColor),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}
