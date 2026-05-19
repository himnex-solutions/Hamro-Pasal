import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/l10n/app_strings.dart';
import 'package:hamro_pasal/core/providers/profile_mode_provider.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/poly_mesh_background.dart';
import 'package:hamro_pasal/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:hamro_pasal/features/dashboard/presentation/screens/personal_dashboard_screen.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(profileModeProvider);
    if (mode == ProfileMode.personal) return const PersonalDashboardScreen();

    return ref.watch(dashboardProvider).when(
          loading: () => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.fourRotatingDots(
                      color: AppTheme.primaryColor, size: 48),
                  const SizedBox(height: 16),
                  Text('Loading dashboard…',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
          ),
          error: (e, _) => Scaffold(
            body: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Could not load data',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Check your connection and try again',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[400])),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(dashboardProvider.notifier).refresh(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Try again'),
                    ),
                  ]),
            ),
          ),
          data: (stats) => Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
              child: CustomScrollView(
                slivers: [
                  _DashAppBar(stats: stats),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        _buildBody(context, ref, stats),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }

  List<Widget> _buildBody(
      BuildContext ctx, WidgetRef ref, DashboardStats stats) {
    final l = ctx.l10n;
    final fmt = NumberFormat('#,##,##0');

    return [
      // Banners
      if (stats.subscriptionStatus == AppConstants.statusTrialActive)
        _PremiumTrialBanner(
          daysLeft: stats.trialDaysLeft ?? 14,
          onUpgrade: () => ctx.push(AppRoutes.subscription),
        ).animate().fadeIn().slideY(begin: -0.1),
      if (stats.subscriptionStatus == AppConstants.statusTrialExpired)
        _AlertBanner(
          icon: Icons.warning_amber_rounded,
          message: 'Your trial has expired',
          color: AppTheme.errorColor,
          action: 'Subscribe Now',
          onAction: () => ctx.push(AppRoutes.trialExpired),
        ).animate().fadeIn(),

      const SizedBox(height: 20),

      // Section header
      _SectionHeader(title: l.overviewToday),
      const SizedBox(height: 12),

      // KPI Cards — 2-column staggered grid
      AnimationLimiter(
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 380),
            childAnimationBuilder: (w) => SlideAnimation(
              verticalOffset: 24,
              child: FadeInAnimation(child: w),
            ),
            children: [
              _KpiCard(
                label: l.todaySales,
                value: 'Rs. ${fmt.format(stats.todaySales)}',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF10B981),
                sparkData: _mockSparkData(stats.todaySales),
              ),
              _KpiCard(
                label: l.todayExpenses,
                value: 'Rs. ${fmt.format(stats.todayExpenses)}',
                icon: Icons.trending_down_rounded,
                color: const Color(0xFFEF4444),
                sparkData: _mockSparkData(stats.todayExpenses),
              ),
              _KpiCard(
                label: l.receivables,
                value: 'Rs. ${fmt.format(stats.totalReceivables)}',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF3B82F6),
                sparkData: _mockSparkData(stats.totalReceivables),
              ),
              _KpiCard(
                label: l.payables,
                value: 'Rs. ${fmt.format(stats.totalPayables)}',
                icon: Icons.payments_outlined,
                color: const Color(0xFFF59E0B),
                sparkData: _mockSparkData(stats.totalPayables),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 20),

      // Net Profit bar
      _NetProfitCard(profit: stats.todayProfit).animate(delay: 250.ms).fadeIn(),

      const SizedBox(height: 24),

      // Quick Actions
      _SectionHeader(title: l.quickActions),
      const SizedBox(height: 12),
      _QuickActionsGrid(l: l).animate(delay: 300.ms).fadeIn(),

      // Low stock
      if (stats.lowStockCount > 0) ...[
        const SizedBox(height: 16),
        _AlertBanner(
          icon: Icons.inventory_2_outlined,
          message: '${stats.lowStockCount} products low on stock',
          color: const Color(0xFFF59E0B),
          action: 'View',
          onAction: () => ctx.push(AppRoutes.inventory),
        ).animate(delay: 350.ms).fadeIn(),
      ],

      const SizedBox(height: 24),

      // Recent Transactions
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SectionHeader(title: l.recentTransactions),
          TextButton(
            onPressed: () => ctx.push(AppRoutes.transactions),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(children: [
              Text('View all'),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 16),
            ]),
          ),
        ],
      ).animate(delay: 400.ms).fadeIn(),

      const SizedBox(height: 10),

      if (stats.recentTransactions.isEmpty)
        _EmptyTransactions()
      else
        AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 300),
              childAnimationBuilder: (w) => SlideAnimation(
                horizontalOffset: 20,
                child: FadeInAnimation(child: w),
              ),
              children: stats.recentTransactions.map((tx) {
                final type = tx['type'] as String;
                final amount = (tx['amount'] as num).toDouble();
                final isIncome = type == AppConstants.txSale ||
                    type == AppConstants.txIncome;
                final date = DateTime.parse(tx['transaction_date'] as String);
                return _TxTile(
                  name: tx['party_name'] as String? ?? _typeLabel(type),
                  subtitle:
                      '${_typeLabel(type)} · ${DateFormat('dd MMM, h:mm a').format(date)}',
                  amount:
                      '${isIncome ? '+' : '-'} Rs. ${NumberFormat('#,##,##0').format(amount)}',
                  isIncome: isIncome,
                );
              }).toList(),
            ),
          ),
        ),
    ];
  }

  // Generate believable sparkline data from a single value
  List<FlSpot> _mockSparkData(double value) {
    if (value == 0) return List.generate(6, (i) => FlSpot(i.toDouble(), 0));
    final base = value * 0.7;
    final ratios = [0.6, 0.8, 0.55, 0.9, 0.75, 1.0];
    return List.generate(6, (i) => FlSpot(i.toDouble(), base * ratios[i]));
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'sale':
        return 'Sale';
      case 'purchase':
        return 'Purchase';
      case 'expense':
        return 'Expense';
      case 'income':
        return 'Income';
      default:
        return type.toUpperCase();
    }
  }
}

// ── App Bar ───────────────────────────────────────────────────
class _DashAppBar extends ConsumerWidget {
  final DashboardStats stats;
  const _DashAppBar({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final l = context.l10n;
    final greeting = hour < 12
        ? l.goodMorning
        : hour < 17
            ? l.goodAfternoon
            : l.goodEvening;

    return SliverAppBar(
      expandedHeight: 132,
      floating: true,
      pinned: false,
      backgroundColor: const Color(0xFF0F172A),
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          tooltip: 'Tools',
          onPressed: () => context.push(AppRoutes.tools),
          icon: const Icon(Icons.build_outlined,
              size: 20, color: Colors.white70),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined,
              size: 20, color: Colors.white70),
        ),
        IconButton(
          tooltip: 'Upgrade',
          onPressed: () => context.push(AppRoutes.subscription),
          icon: const Icon(Icons.workspace_premium_outlined,
              size: 20, color: Colors.white70),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: PolyMeshBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$greeting 👋',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            DateFormat('EEEE, d MMMM').format(DateTime.now()),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3)),
                      ),
                      // Mode badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('Business',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── KPI Card with Sparkline ───────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final List<FlSpot> sparkData;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sparkData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.white,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardTheme.color ?? Colors.white,
            (Theme.of(context).cardTheme.color ?? Colors.white).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + trend indicator row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              // Mini sparkline chart
              SizedBox(
                width: 56,
                height: 28,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: sparkData,
                        isCurved: true,
                        color: color,
                        barWidth: 1.8,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withValues(alpha: 0.25),
                              color.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Value
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                  letterSpacing: -0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          // Label
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : const Color(0xFF9CA3AF)),
              maxLines: 1),
        ],
      ),
    );
  }
}

// ── Net Profit Card ───────────────────────────────────────────
class _NetProfitCard extends StatelessWidget {
  final double profit;
  const _NetProfitCard({required this.profit});

  @override
  Widget build(BuildContext context) {
    final isPositive = profit >= 0;
    final color =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final fmt = NumberFormat('#,##,##0.00');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.white,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardTheme.color ?? Colors.white,
            (Theme.of(context).cardTheme.color ?? Colors.white).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: color,
                size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Net Profit Today',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : const Color(0xFF6B7280))),
              const SizedBox(height: 3),
              Text('${isPositive ? '+' : '-'} Rs. ${fmt.format(profit.abs())}',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPositive ? 'Profit' : 'Loss',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Grid ────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final dynamic l;
  const _QuickActionsGrid({required this.l});

  @override
  Widget build(BuildContext context) {
    final actions = [
      const _QA('New Sale', Icons.point_of_sale_rounded, Color(0xFF10B981),
          AppRoutes.addTransaction),
      const _QA('Purchase', Icons.shopping_bag_outlined, Color(0xFF3B82F6),
          AppRoutes.addTransaction),
      const _QA('Party', Icons.person_add_alt_1_outlined, AppTheme.primaryColor,
          AppRoutes.addParty),
      const _QA('Product', Icons.inventory_2_outlined, Color(0xFF8B5CF6),
          AppRoutes.addProduct),
      const _QA('Expense', Icons.receipt_long_outlined, Color(0xFFEF4444),
          AppRoutes.addExpense),
      const _QA('Reports', Icons.bar_chart_rounded, Color(0xFFF59E0B),
          AppRoutes.reports),
      const _QA('Tools', Icons.build_outlined, Color(0xFF0D7E8A),
          AppRoutes.tools),
      const _QA('Invoices', Icons.description_outlined, Color(0xFF14B8A6),
          AppRoutes.invoices),
      const _QA('Settings', Icons.settings_outlined, Color(0xFF64748B),
          AppRoutes.settings),
    ];

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions.map((a) => _QACard(action: a)).toList(),
    );
  }
}

class _QACard extends StatefulWidget {
  final _QA action;
  const _QACard({required this.action});
  @override
  State<_QACard> createState() => _QACardState();
}

class _QACardState extends State<_QACard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.push(a.route);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkBorder
                    : Colors.white,
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: a.color.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardTheme.color ?? Colors.white,
                (Theme.of(context).cardTheme.color ?? Colors.white).withValues(alpha: 0.6),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a.icon, color: a.color, size: 21),
              ),
              const SizedBox(height: 8),
              Text(a.label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : const Color(0xFF374151)),
                  textAlign: TextAlign.center,
                  maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _QA {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QA(this.label, this.icon, this.color, this.route);
}

// ── Transaction Tile ──────────────────────────────────────────
class _TxTile extends StatelessWidget {
  final String name, subtitle, amount;
  final bool isIncome;
  const _TxTile(
      {required this.name,
      required this.subtitle,
      required this.amount,
      required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.white,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
                isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: color,
                size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : const Color(0xFF111827)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(subtitle,
                  style:
                      TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : const Color(0xFF9CA3AF)),
                  maxLines: 1),
            ]),
          ),
          Text(amount,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── Empty transactions ────────────────────────────────────────
class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
        ),
        child: Center(
          child: Column(children: [
            Icon(Icons.receipt_long_outlined,
                size: 36, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('No transactions today',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}

// ── Alert Banner ──────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final String message, action;
  final Color color;
  final VoidCallback onAction;

  const _AlertBanner({
    required this.icon,
    required this.message,
    required this.action,
    required this.color,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color))),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            child: Text(action),
          ),
        ]),
      );
}

// ── Section Header ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : const Color(0xFF111827),
          letterSpacing: -0.2));
}

// ── Premium Trial Banner ──────────────────────────────────────
class _PremiumTrialBanner extends StatelessWidget {
  final int daysLeft;
  final VoidCallback onUpgrade;

  const _PremiumTrialBanner({
    required this.daysLeft,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const totalDays = 14;
    final progress = (totalDays - daysLeft) / totalDays;
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    // Palette matching the teal theme
    const primaryColor = AppTheme.primaryColor;
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF0F4050) : Colors.white);

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor,
            primaryColor.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Subtle Watermark Decor
          Positioned(
            top: -5,
            right: 40,
            child: Icon(
              Icons.percent_rounded,
              size: 70,
              color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.05),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title, Badge, Days Left
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Free trial',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 45% OFF Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.discount_rounded, size: 10, color: primaryColor),
                            SizedBox(width: 4),
                            Text(
                              '45% OFF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$daysLeft days left',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              
              // Bottom Row: Progress bar + Upgrade Button
              Row(
                children: [
                  // Progress bar
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: clampedProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Compact Upgrade Button
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: onUpgrade,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero, // Prevents layout assertion errors
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: primaryColor.withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        'Upgrade',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
