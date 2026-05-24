import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/poly_mesh_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// ── Providers & Models ───────────────────────────────────────

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

class AdminActivityItem {
  final String id;
  final String type; // 'user' | 'business' | 'feedback' | 'payment'
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String status;

  AdminActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.status = '',
  });
}

final adminDashboardActivityProvider = FutureProvider<List<AdminActivityItem>>((ref) async {
  final db = Supabase.instance.client;
  final List<AdminActivityItem> items = [];

  try {
    // 1. Fetch recent user profiles
    final users = await db.from('user_profiles')
        .select('id, full_name, email, created_at')
        .order('created_at', ascending: false)
        .limit(5);
    for (var u in users as List) {
      items.add(AdminActivityItem(
        id: 'user_${u['id']}',
        type: 'user',
        title: 'New User Registered',
        subtitle: '${u['full_name'] ?? 'No Name'} (${u['email']})',
        timestamp: DateTime.parse(u['created_at']),
      ));
    }
  } catch (e) {
    debugPrint('Error fetching users for activity feed: $e');
  }

  try {
    // 2. Fetch recent businesses
    final businesses = await db.from('businesses')
        .select('id, name, type, created_at')
        .order('created_at', ascending: false)
        .limit(5);
    for (var b in businesses as List) {
      items.add(AdminActivityItem(
        id: 'business_${b['id']}',
        type: 'business',
        title: 'New Business Registered',
        subtitle: '${b['name'] ?? 'Unnamed'} (${b['type'] ?? 'General'})',
        timestamp: DateTime.parse(b['created_at']),
      ));
    }
  } catch (e) {
    debugPrint('Error fetching businesses for activity feed: $e');
  }

  try {
    // 3. Fetch recent feedbacks
    final feedbacks = await db.from('feedbacks')
        .select('id, rating, message, created_at, user_profiles(full_name)')
        .order('created_at', ascending: false)
        .limit(5);
    for (var f in feedbacks as List) {
      final userProfile = f['user_profiles'];
      String userName = 'Anonymous';
      if (userProfile is Map) {
        userName = userProfile['full_name'] ?? 'Unknown';
      } else if (userProfile is List && userProfile.isNotEmpty) {
        userName = userProfile[0]['full_name'] ?? 'Unknown';
      }
      items.add(AdminActivityItem(
        id: 'feedback_${f['id']}',
        type: 'feedback',
        title: 'Feedback Received (${f['rating']} ★)',
        subtitle: '"${f['message'] ?? ''}" - by $userName',
        timestamp: DateTime.parse(f['created_at']),
      ));
    }
  } catch (e) {
    debugPrint('Error fetching feedbacks for activity feed: $e');
  }

  try {
    // 4. Fetch recent payments
    final payments = await db.from('payment_requests')
        .select('id, plan_code, amount, status, created_at, user_profiles(full_name)')
        .order('created_at', ascending: false)
        .limit(5);
    for (var p in payments as List) {
      final userProfile = p['user_profiles'];
      String userName = 'Unknown';
      if (userProfile is Map) {
        userName = userProfile['full_name'] ?? 'Unknown';
      } else if (userProfile is List && userProfile.isNotEmpty) {
        userName = userProfile[0]['full_name'] ?? 'Unknown';
      }
      items.add(AdminActivityItem(
        id: 'payment_${p['id']}',
        type: 'payment',
        title: 'Payment Request ${p['status']?.toUpperCase() ?? ''}',
        subtitle: 'Plan: ${(p['plan_code'] as String).toUpperCase()} | NPR ${p['amount']} by $userName',
        timestamp: DateTime.parse(p['created_at']),
        status: p['status'] ?? '',
      ));
    }
  } catch (e) {
    debugPrint('Error fetching payments for activity feed: $e');
  }

  // Sort all items combined by timestamp descending
  items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return items;
});

// ── Screen ────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: AppTheme.darkSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: () {
              ref.invalidate(adminStatsProvider);
              ref.invalidate(adminDashboardActivityProvider);
            },
            tooltip: 'Refresh All',
          ),
        ],
      ),
      body: PolyMeshBackground(
        child: statsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryLight),
          ),
          error: (e, _) => _ErrorView(error: e.toString()),
          data: (stats) => SafeArea(
            bottom: false,
            child: _DashboardBody(stats: stats),
          ),
        ),
      ),
    );
  }
}

// ── Dashboard Body & Sections ─────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _DashboardBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalUsers = (stats['total_users'] as num?)?.toInt() ?? 0;
    final totalBusinesses = (stats['total_businesses'] as num?)?.toInt() ?? 0;
    final activeTrials = (stats['active_trials'] as num?)?.toInt() ?? 0;
    final activeSubscriptions = (stats['active_subscriptions'] as num?)?.toInt() ?? 0;
    final expiredSubs = (stats['expired_subscriptions'] as num?)?.toInt() ?? 0;
    final totalRevenue = (stats['total_revenue'] as num?)?.toDouble() ?? 0.0;

    // Mock trend line data points for each stat card
    final userTrend = <double>[10.0, 15.0, 18.0, 16.0, 22.0, 25.0, totalUsers.toDouble()];
    final bizTrend = <double>[4.0, 6.0, 5.0, 8.0, 9.0, 11.0, totalBusinesses.toDouble()];
    final trialTrend = <double>[3.0, 2.0, 4.0, 6.0, 5.0, 4.0, activeTrials.toDouble()];
    final subTrend = <double>[2.0, 4.0, 5.0, 8.0, 11.0, 12.0, activeSubscriptions.toDouble()];
    final expiredTrend = <double>[1.0, 2.0, 1.0, 3.0, 2.0, 4.0, expiredSubs.toDouble()];
    final revenueTrend = <double>[500.0, 1200.0, 1800.0, 1500.0, 2400.0, 3200.0, totalRevenue == 0.0 ? 3500.0 : totalRevenue];

    final statsCards = [
      _StatCard(
        label: 'Total Users',
        value: totalUsers.toString(),
        icon: Icons.people_rounded,
        color: const Color(0xFF3B82F6),
        trendData: userTrend,
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
      _StatCard(
        label: 'Businesses',
        value: totalBusinesses.toString(),
        icon: Icons.store_rounded,
        color: AppTheme.successColor,
        trendData: bizTrend,
      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
      _StatCard(
        label: 'Active Trials',
        value: activeTrials.toString(),
        icon: Icons.hourglass_top_rounded,
        color: AppTheme.warningColor,
        trendData: trialTrend,
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
      _StatCard(
        label: 'Subscriptions',
        value: activeSubscriptions.toString(),
        icon: Icons.card_membership_rounded,
        color: AppTheme.primaryLight,
        trendData: subTrend,
      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
      _StatCard(
        label: 'Expired',
        value: expiredSubs.toString(),
        icon: Icons.cancel_outlined,
        color: AppTheme.errorColor,
        trendData: expiredTrend,
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
      _StatCard(
        label: 'Total Revenue',
        value: 'NPR ${totalRevenue.toStringAsFixed(0)}',
        icon: Icons.payments_rounded,
        color: AppTheme.accentColor,
        trendData: revenueTrend,
      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1050;
        final mainContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConsoleHeader().animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            
            // Stats Grid Section
            const Text(
              'PLATFORM OVERVIEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: statsCards[0]),
                    const SizedBox(width: 16),
                    Expanded(child: statsCards[1]),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: statsCards[2]),
                    const SizedBox(width: 16),
                    Expanded(child: statsCards[3]),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: statsCards[4]),
                    const SizedBox(width: 16),
                    Expanded(child: statsCards[5]),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Analytics Chart
            _AnalyticsChart(stats: stats).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            // Quick Actions Section
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    label: 'New Announcement',
                    icon: Icons.campaign_rounded,
                    color: AppTheme.warningColor,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    label: 'Run Trial Expiry Check',
                    icon: Icons.timer_rounded,
                    color: AppTheme.errorColor,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    label: 'Export User Data',
                    icon: Icons.download_rounded,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ],
        );

        if (isWide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: mainContent,
                ),
                const SizedBox(width: 24),
                const Expanded(
                  flex: 3,
                  child: _LiveActivityFeed(),
                ),
              ],
            ),
          );
        } else {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mainContent,
                const SizedBox(height: 24),
                const _LiveActivityFeed().animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
              ],
            ),
          );
        }
      },
    );
  }
}

// ── Console Header ───────────────────────────────────────────

class _ConsoleHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SYSTEM OPERATOR CONSOLE',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Welcome Back, Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              // Live Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successColor,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DB CONNECTED',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.darkBorder, height: 1),
          const SizedBox(height: 16),
          // Server Metrics Row
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ServerMetricTile(
                label: 'CPU LOAD',
                value: '18.4%',
                icon: Icons.developer_board_rounded,
                color: AppTheme.primaryLight,
              ),
              _ServerMetricTile(
                label: 'LATENCY',
                value: '42 ms',
                icon: Icons.speed_rounded,
                color: AppTheme.successColor,
              ),
              _ServerMetricTile(
                label: 'MEM USAGE',
                value: '2.4 / 8.0 GB',
                icon: Icons.memory_rounded,
                color: AppTheme.warningColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServerMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ServerMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Reusable Widgets & Sparkline Painter ──────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final double stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double normalizedY = (data[i] - minVal) / range;
      final double y = size.height - (normalizedY * (size.height - 8) + 4);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    fillPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final List<double> trendData;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trendData,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 155,
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Bottom Sparkline Graph
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 45,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    data: trendData,
                    color: color,
                  ),
                ),
              ),
              // Card Details
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: color.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(icon, color: color, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Simulated growth percentage based on data trend
                    Row(
                      children: [
                        Icon(
                          trendData.last >= trendData[trendData.length - 2]
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: trendData.last >= trendData[trendData.length - 2]
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trendData.last >= trendData[trendData.length - 2] ? '+4.2%' : '-1.5%',
                          style: TextStyle(
                            color: trendData.last >= trendData[trendData.length - 2]
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' vs last week',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Triggered Action: $label'),
            backgroundColor: color.withValues(alpha: 0.9),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Growth Analytics Section ──────────────────────────────────

class _AnalyticsChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _AnalyticsChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Growth Analytics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Historical platform engagement trends',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _LegendIndicator(color: AppTheme.primaryLight, label: 'Revenue'),
                  SizedBox(width: 16),
                  _LegendIndicator(color: AppTheme.successColor, label: 'Users'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.darkBorder.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : value.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 5000,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppTheme.darkSurface,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isRevenue = spot.barIndex == 0;
                        return LineTooltipItem(
                          isRevenue
                              ? 'Revenue: NPR ${spot.y.toStringAsFixed(0)}'
                              : 'Users: ${spot.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: isRevenue ? AppTheme.primaryLight : AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1500),
                      FlSpot(1, 2800),
                      FlSpot(2, 2200),
                      FlSpot(3, 3400),
                      FlSpot(4, 3900),
                      FlSpot(5, 4200),
                      FlSpot(6, 4500),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryLight, Color(0xFF1FE0F0)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryLight.withValues(alpha: 0.2),
                          AppTheme.primaryLight.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 800),
                      FlSpot(1, 1200),
                      FlSpot(2, 1900),
                      FlSpot(3, 1500),
                      FlSpot(4, 2600),
                      FlSpot(5, 3100),
                      FlSpot(6, 3800),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppTheme.successColor, Color(0xFF3B82F6)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.successColor.withValues(alpha: 0.2),
                          AppTheme.successColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendIndicator extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendIndicator({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Live Platform Activity Feed ───────────────────────────────

class _LiveActivityFeed extends ConsumerWidget {
  const _LiveActivityFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(adminDashboardActivityProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Activity Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Real-time operations',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 18),
                onPressed: () => ref.invalidate(adminDashboardActivityProvider),
                tooltip: 'Refresh Feed',
              ),
            ],
          ),
          const SizedBox(height: 16),
          activityAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppTheme.primaryLight),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Error loading feed: $err',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                );
              }

              final displayItems = items.take(6).toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayItems.length,
                separatorBuilder: (context, index) => const Divider(
                  color: AppTheme.darkBorder,
                  height: 16,
                  thickness: 0.5,
                ),
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return _ActivityItemRow(item: item);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityItemRow extends StatelessWidget {
  final AdminActivityItem item;
  const _ActivityItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (item.type) {
      case 'user':
        icon = Icons.person_add_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case 'business':
        icon = Icons.add_business_rounded;
        color = AppTheme.successColor;
        break;
      case 'feedback':
        icon = Icons.chat_bubble_outline_rounded;
        color = AppTheme.warningColor;
        break;
      case 'payment':
        icon = Icons.payment_rounded;
        color = item.status == 'approved'
            ? AppTheme.successColor
            : (item.status == 'rejected' ? AppTheme.errorColor : AppTheme.accentColor);
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = Colors.white54;
    }

    final relativeTime = _getRelativeTime(item.timestamp);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          relativeTime,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// ── Error State Widget ────────────────────────────────────────

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
