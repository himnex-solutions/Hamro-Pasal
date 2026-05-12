import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';

// ── Personal Stats Model ─────────────────────────────────────
class PersonalStats {
  final String fullName;
  final String email;
  final String phone;
  final String businessName;
  final String businessType;
  final String subscriptionStatus;
  final int? trialDaysLeft;
  final double totalBusinessSales;
  final double totalBusinessExpenses;
  final int totalParties;
  final int totalProducts;

  const PersonalStats({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.businessName = '',
    this.businessType = '',
    this.subscriptionStatus = 'trial_active',
    this.trialDaysLeft,
    this.totalBusinessSales = 0,
    this.totalBusinessExpenses = 0,
    this.totalParties = 0,
    this.totalProducts = 0,
  });
}

// ── Provider ─────────────────────────────────────────────────
final personalDashboardProvider =
    AsyncNotifierProvider<PersonalDashboardNotifier, PersonalStats>(() {
  return PersonalDashboardNotifier();
});

class PersonalDashboardNotifier extends AsyncNotifier<PersonalStats> {
  @override
  Future<PersonalStats> build() => _fetch();

  Future<PersonalStats> _fetch() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const PersonalStats();

    try {
      // Fetch user profile
      final profile = await supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Fetch business (first business the user owns/belongs to)
      final memberRow = await supabase
          .from('business_members')
          .select('business_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      String businessName = '';
      String businessType = '';
      String subStatus = AppConstants.statusTrialActive;
      int? trialDaysLeft;
      double totalSales = 0, totalExpenses = 0;
      int totalParties = 0, totalProducts = 0;

      final businessId = memberRow?['business_id'] as String?;
      if (businessId != null) {
        final biz = await supabase
            .from('businesses')
            .select('name, type')
            .eq('id', businessId)
            .maybeSingle();
        businessName = biz?['name'] as String? ?? '';
        businessType = biz?['type'] as String? ?? '';

        // Subscription
        final sub = await supabase
            .from('subscriptions')
            .select('status, trial_end_date')
            .eq('business_id', businessId)
            .maybeSingle();
        if (sub != null) {
          subStatus = sub['status'] as String;
          if (sub['trial_end_date'] != null) {
            final end = DateTime.parse(sub['trial_end_date'] as String);
            trialDaysLeft = end.difference(DateTime.now()).inDays;
          }
        }

        // Lifetime sales & expenses
        final txRes = await supabase
            .from('transactions')
            .select('type, amount')
            .eq('business_id', businessId);
        for (final tx in txRes as List) {
          final amount = (tx['amount'] as num).toDouble();
          if (tx['type'] == AppConstants.txSale) totalSales += amount;
          if (tx['type'] == AppConstants.txExpense) totalExpenses += amount;
        }

        // Counts
        final parties = await supabase
            .from('parties')
            .select('id')
            .eq('business_id', businessId);
        totalParties = (parties as List).length;

        final products = await supabase
            .from('products')
            .select('id')
            .eq('business_id', businessId)
            .eq('is_active', true);
        totalProducts = (products as List).length;
      }

      return PersonalStats(
        fullName: profile?['full_name'] as String? ?? '',
        email: profile?['email'] as String? ??
            supabase.auth.currentUser?.email ?? '',
        phone: profile?['phone'] as String? ?? '',
        businessName: businessName,
        businessType: businessType,
        subscriptionStatus: subStatus,
        trialDaysLeft: trialDaysLeft,
        totalBusinessSales: totalSales,
        totalBusinessExpenses: totalExpenses,
        totalParties: totalParties,
        totalProducts: totalProducts,
      );
    } catch (_) {
      return const PersonalStats();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

// ── Personal Dashboard Screen ─────────────────────────────────
class PersonalDashboardScreen extends ConsumerWidget {
  const PersonalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(personalDashboardProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text('Failed to load profile',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  ref.read(personalDashboardProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (stats) => RefreshIndicator(
        onRefresh: () =>
            ref.read(personalDashboardProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            _PersonalAppBar(stats: stats, ref: ref),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Profile card
                  _ProfileCard(stats: stats),
                  const SizedBox(height: 20),

                  // Business summary header
                  if (stats.businessName.isNotEmpty) ...[
                    Text('Business Overview',
                            style: Theme.of(context).textTheme.titleLarge)
                        .animate(delay: 100.ms)
                        .fadeIn(),
                    const SizedBox(height: 12),

                    // Business card
                    _BusinessSummaryCard(stats: stats),
                    const SizedBox(height: 20),

                    // Lifetime stats grid
                    Text('Lifetime Stats',
                            style: Theme.of(context).textTheme.titleLarge)
                        .animate(delay: 200.ms)
                        .fadeIn(),
                    const SizedBox(height: 12),
                    _LifetimeStatsGrid(stats: stats),
                    const SizedBox(height: 20),

                    // Subscription card
                    _SubscriptionCard(stats: stats),
                  ] else ...[
                    _NoBusinessCard(),
                  ],

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────
class _PersonalAppBar extends StatelessWidget {
  final PersonalStats stats;
  final WidgetRef ref;
  const _PersonalAppBar({required this.stats, required this.ref});

  @override
  Widget build(BuildContext context) {
    final initial = stats.fullName.isNotEmpty
        ? stats.fullName.trim()[0].toUpperCase()
        : '?';
    return SliverAppBar(
      expandedHeight: 150,
      floating: true,
      pinned: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C3483), Color(0xFF9B59B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stats.fullName.isEmpty ? 'My Profile' : stats.fullName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            Text(
                              stats.email,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Mode pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Personal Mode',
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
      ],
    );
  }
}

// ── Profile Card ─────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final PersonalStats stats;
  const _ProfileCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9B59B6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Personal Information',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: stats.fullName.isEmpty ? 'Not set' : stats.fullName),
            const Divider(height: 20),
            _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: stats.email.isEmpty ? 'Not set' : stats.email),
            const Divider(height: 20),
            _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: stats.phone.isEmpty ? 'Not set' : stats.phone),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.lightTextSecondary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppTheme.lightTextHint)),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

// ── Business Summary Card ─────────────────────────────────────
class _BusinessSummaryCard extends StatelessWidget {
  final PersonalStats stats;
  const _BusinessSummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stats.businessName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(stats.businessType,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

// ── Lifetime Stats Grid ───────────────────────────────────────
class _LifetimeStatsGrid extends StatelessWidget {
  final PersonalStats stats;
  const _LifetimeStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0');
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatTile('Total Sales',
            '${AppConstants.currencySymbol} ${fmt.format(stats.totalBusinessSales)}',
            AppTheme.successColor, Icons.trending_up_rounded),
        _StatTile('Total Expenses',
            '${AppConstants.currencySymbol} ${fmt.format(stats.totalBusinessExpenses)}',
            AppTheme.errorColor, Icons.trending_down_rounded),
        _StatTile('Total Parties', '${stats.totalParties}',
            AppTheme.infoColor, Icons.people_outline),
        _StatTile('Products', '${stats.totalProducts}',
            AppTheme.accentColor, Icons.inventory_2_outlined),
      ],
    ).animate(delay: 200.ms).fadeIn();
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatTile(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            color: color, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subscription Card ─────────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  final PersonalStats stats;
  const _SubscriptionCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isTrial =
        stats.subscriptionStatus == AppConstants.statusTrialActive;
    final isExpired =
        stats.subscriptionStatus == AppConstants.statusTrialExpired ||
            stats.subscriptionStatus == AppConstants.statusExpired;
    final color = isExpired
        ? AppTheme.errorColor
        : isTrial
            ? AppTheme.accentDark
            : AppTheme.successColor;
    final label = isExpired
        ? 'Subscription Expired'
        : isTrial
            ? 'Free Trial Active${stats.trialDaysLeft != null ? ' — ${stats.trialDaysLeft}d left' : ''}'
            : 'Subscribed ✓';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isExpired
                ? Icons.timer_off_outlined
                : isTrial
                    ? Icons.rocket_launch_outlined
                    : Icons.workspace_premium_outlined,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600)),
          ),
          if (isExpired || isTrial)
            TextButton(
              onPressed: () => context.push(AppRoutes.subscription),
              style: TextButton.styleFrom(foregroundColor: color),
              child: const Text('Manage'),
            ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn();
  }
}

// ── No Business Card ─────────────────────────────────────────
class _NoBusinessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.lightTextHint.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.store_outlined,
              size: 48, color: AppTheme.lightTextHint),
          const SizedBox(height: 12),
          Text('No Business Linked',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Set up a business to see detailed stats here.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    ).animate().fadeIn();
  }
}
