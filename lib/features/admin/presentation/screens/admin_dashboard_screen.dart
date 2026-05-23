import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Provider ──────────────────────────────────────────────────
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = Supabase.instance.client;
  final result = await db.rpc('admin_get_stats');
  if (result == null) return {};
  if (result is Map<String, dynamic>) return result;
  // Supabase may return the JSON as a Map inside a list
  if (result is List && result.isNotEmpty) {
    final first = result.first;
    if (first is Map<String, dynamic>) return first;
  }
  return {};
});

// ── Screen ────────────────────────────────────────────────────
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: () => ref.invalidate(adminStatsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryLight),
        ),
        error: (e, _) => _ErrorView(error: e.toString()),
        data: (stats) => _DashboardBody(stats: stats),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _DashboardBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalUsers = stats['total_users'] ?? 0;
    final totalBusinesses = stats['total_businesses'] ?? 0;
    final activeTrials = stats['active_trials'] ?? 0;
    final activeSubscriptions = stats['active_subscriptions'] ?? 0;
    final expiredSubs = stats['expired_subscriptions'] ?? 0;
    final totalRevenue = (stats['total_revenue'] ?? 0.0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats grid ─────────────────────────────────
          const Text(
            'Platform Overview',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                label: 'Total Users',
                value: totalUsers.toString(),
                icon: Icons.people_rounded,
                color: const Color(0xFF3B82F6),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
              _StatCard(
                label: 'Businesses',
                value: totalBusinesses.toString(),
                icon: Icons.store_rounded,
                color: AppTheme.successColor,
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
              _StatCard(
                label: 'Active Trials',
                value: activeTrials.toString(),
                icon: Icons.hourglass_top_rounded,
                color: AppTheme.warningColor,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              _StatCard(
                label: 'Subscriptions',
                value: activeSubscriptions.toString(),
                icon: Icons.card_membership_rounded,
                color: AppTheme.primaryLight,
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
              _StatCard(
                label: 'Expired',
                value: expiredSubs.toString(),
                icon: Icons.cancel_outlined,
                color: AppTheme.errorColor,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              _StatCard(
                label: 'Total Revenue',
                value: 'NPR ${totalRevenue.toStringAsFixed(0)}',
                icon: Icons.payments_rounded,
                color: AppTheme.accentColor,
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
            ],
          ),

          const SizedBox(height: 32),

          // ── Quick actions ────────────────────────────────
          const Text(
            'Quick Actions',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickAction(
                label: 'New Announcement',
                icon: Icons.campaign_rounded,
                color: AppTheme.warningColor,
              ),
              _QuickAction(
                label: 'Run Trial Expiry Check',
                icon: Icons.timer_rounded,
                color: AppTheme.errorColor,
              ),
              _QuickAction(
                label: 'Export User Data',
                icon: Icons.download_rounded,
                color: Color(0xFF3B82F6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.errorColor, size: 48),
          const SizedBox(height: 12),
          Text(
            'Failed to load stats:\n$error',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
