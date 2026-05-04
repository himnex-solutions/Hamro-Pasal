import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

final _fmt = NumberFormat('#,##0.00', 'en_US');

// ─── Dashboard Providers ──────────────────────────────────────────────────────

final dashboardStatsProvider = FutureProvider<_DashboardStats>((ref) async {
  final userId = SupabaseService.instance.currentUserId;
  if (userId == null) return _DashboardStats.empty();
  final svc = SupabaseService.instance;

  // Parallel fetch for speed
  final results = await Future.wait([
    svc.getSales(userId, from: DateTime.now()),
    svc.getSales(userId,
        from: DateTime(DateTime.now().year, DateTime.now().month, 1)),
    svc.getProducts(userId),
    svc.getCustomers(userId),
  ]);

  final todaySales = results[0] as List<Map<String, dynamic>>;
  final monthSales = results[1] as List<Map<String, dynamic>>;
  final products = results[2] as List<Map<String, dynamic>>;
  final customers = results[3] as List<Map<String, dynamic>>;

  final todayRevenue = todaySales.fold<double>(
      0, (sum, s) => sum + (s['total'] as num? ?? 0).toDouble());
  final monthRevenue = monthSales.fold<double>(
      0, (sum, s) => sum + (s['total'] as num? ?? 0).toDouble());
  final lowStockItems = products
      .where((p) =>
          (p['stock_quantity'] as int? ?? 0) <= (p['low_stock_limit'] as int? ?? 5))
      .length;
  final totalDue = customers.fold<double>(
      0, (sum, c) => sum + (c['total_due'] as num? ?? 0).toDouble());

  return _DashboardStats(
    todayRevenue: todayRevenue,
    todayBills: todaySales.length,
    monthRevenue: monthRevenue,
    monthBills: monthSales.length,
    totalProducts: products.length,
    lowStockCount: lowStockItems,
    totalCustomers: customers.length,
    totalDue: totalDue,
  );
});

class _DashboardStats {
  final double todayRevenue;
  final int todayBills;
  final double monthRevenue;
  final int monthBills;
  final int totalProducts;
  final int lowStockCount;
  final int totalCustomers;
  final double totalDue;

  _DashboardStats({
    required this.todayRevenue,
    required this.todayBills,
    required this.monthRevenue,
    required this.monthBills,
    required this.totalProducts,
    required this.lowStockCount,
    required this.totalCustomers,
    required this.totalDue,
  });

  factory _DashboardStats.empty() => _DashboardStats(
    todayRevenue: 0, todayBills: 0, monthRevenue: 0, monthBills: 0,
    totalProducts: 0, lowStockCount: 0, totalCustomers: 0, totalDue: 0,
  );
}

// ─── Dashboard Screen ─────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile?.pasalName ?? 'Hamro Pasal'),
            Text(DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                (profile?.pasalName.isNotEmpty == true
                        ? profile!.pasalName[0].toUpperCase()
                        : 'H'),
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions
              _QuickActions(),
              const SizedBox(height: 24),

              // Stats Header
              Text("Today's Overview",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              // Stats Grid
              stats.when(
                loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )),
                error: (e, _) => _ErrorWidget(
                  onRetry: () => ref.invalidate(dashboardStatsProvider),
                ),
                data: (s) => _StatsGrid(stats: s),
              ),
              const SizedBox(height: 24),

              // Menu Grid
              Text('Quick Menu',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _MenuGrid(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.routePOS),
        icon: const Icon(Icons.point_of_sale_rounded),
        label: const Text('New Sale'),
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1338B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white)),
          const SizedBox(height: 14),
          Row(
            children: [
              _QuickBtn(
                  icon: Icons.receipt_long_rounded,
                  label: 'New Bill',
                  color: Colors.white,
                  onTap: () => context.push(AppConstants.routePOS)),
              _QuickBtn(
                  icon: Icons.add_box_rounded,
                  label: 'Add Item',
                  color: Colors.white,
                  onTap: () => context.go('/inventory/add')),
              _QuickBtn(
                  icon: Icons.person_add_rounded,
                  label: 'Customer',
                  color: Colors.white,
                  onTap: () => context.go(AppConstants.routeCustomers)),
              _QuickBtn(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports',
                  color: Colors.white,
                  onTap: () => context.go(AppConstants.routeReports)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final _DashboardStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          title: "Today's Sales",
          value: 'NPR ${_fmt.format(stats.todayRevenue)}',
          subtitle: '${stats.todayBills} bills',
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
        ),
        _StatCard(
          title: 'Monthly Revenue',
          value: 'NPR ${_fmt.format(stats.monthRevenue)}',
          subtitle: '${stats.monthBills} bills',
          icon: Icons.calendar_month_rounded,
          color: AppColors.primary,
        ),
        _StatCard(
          title: 'Products',
          value: stats.totalProducts.toString(),
          subtitle: '${stats.lowStockCount} low stock ⚠️',
          icon: Icons.inventory_2_rounded,
          color: AppColors.inventoryColor,
        ),
        _StatCard(
          title: 'Total Udhaar',
          value: 'NPR ${_fmt.format(stats.totalDue)}',
          subtitle: '${stats.totalCustomers} customers',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Menu Grid ────────────────────────────────────────────────────────────────

class _MenuGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _MenuItem(
          icon: Icons.point_of_sale_rounded,
          label: 'POS Billing',
          color: AppColors.posColor,
          route: AppConstants.routePOS),
      _MenuItem(
          icon: Icons.inventory_2_rounded,
          label: 'Inventory',
          color: AppColors.inventoryColor,
          route: AppConstants.routeInventory),
      _MenuItem(
          icon: Icons.people_rounded,
          label: 'Customers',
          color: AppColors.customersColor,
          route: AppConstants.routeCustomers),
      _MenuItem(
          icon: Icons.bar_chart_rounded,
          label: 'Reports',
          color: AppColors.reportsColor,
          route: AppConstants.routeReports),
      _MenuItem(
          icon: Icons.receipt_rounded,
          label: 'Expenses',
          color: AppColors.expensesColor,
          route: AppConstants.routeExpenses),
      _MenuItem(
          icon: Icons.local_shipping_rounded,
          label: 'Suppliers',
          color: AppColors.suppliersColor,
          route: AppConstants.routeSuppliers),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _MenuTile(item: items[i]),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.route});
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => item.route == AppConstants.routePOS
          ? context.push(item.route)
          : context.go(item.route),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(item.label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Error Widget ─────────────────────────────────────────────────────────────

class _ErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 36),
          const SizedBox(height: 12),
          Text('No internet connection',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppColors.error)),
          const SizedBox(height: 4),
          Text('Check your network and try again',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
