import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const AdminShellScreen({super.key, required this.child});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(
        route: AppRoutes.adminDashboard,
        icon: Icons.dashboard_rounded,
        label: 'Dashboard'),
    _NavItem(
        route: AppRoutes.adminUsers,
        icon: Icons.people_rounded,
        label: 'Users'),
    _NavItem(
        route: AppRoutes.adminBusinesses,
        icon: Icons.store_rounded,
        label: 'Businesses'),
    _NavItem(
        route: AppRoutes.adminSubscriptions,
        icon: Icons.card_membership_rounded,
        label: 'Subscriptions'),
    _NavItem(
        route: AppRoutes.adminFeedback,
        icon: Icons.feedback_outlined,
        label: 'Feedback'),
  ];

  // Pending feedback count for the notification badge
  int _pendingFeedback = 0;
  RealtimeChannel? _fbChannel;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
    _fbChannel = Supabase.instance.client
         .channel('shell-feedbacks')
         .onPostgresChanges(
           event: PostgresChangeEvent.all,
           schema: 'public',
           table: 'feedbacks',
           callback: (_) => _loadPendingCount(),
         )
         .subscribe();
  }

  @override
  void dispose() {
    _fbChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadPendingCount() async {
    try {
      final res = await Supabase.instance.client
          .from('feedbacks')
          .select('id')
          .eq('status', 'pending');
      if (mounted) setState(() => _pendingFeedback = (res as List).length);
    } catch (_) {}
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    context.go(_navItems[index].route);
  }

  Future<bool> _showLogoutConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.darkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Confirm Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to log out of the admin portal?',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminAuthProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 900;
    final showLabels = screenWidth >= 360;
    final showUnselected = screenWidth >= 480;

    // Show loader while the async session check is in progress (page refresh).
    // The GoRouter redirect passes through during `initial` — this prevents
    // any flash of the shell content before auth is confirmed.
    if (adminState.status == AdminAuthStatus.initial) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryLight),
              SizedBox(height: 16),
              Text(
                'Verifying session…',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Row(
        children: [
          // ── Sidebar (wide screens) ─────────────────────────
          if (isWide)
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: AppTheme.darkSurface,
                border: Border(
                  right: BorderSide(
                      color: AppTheme.darkBorder, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Portal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Hamro Pasal',
                              style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppTheme.darkBorder),
                  const SizedBox(height: 8),

                  // Nav items
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navItems.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, i) {
                        final item = _navItems[i];
                        final selected = _selectedIndex == i;
                        final isFeedback = item.route == AppRoutes.adminFeedback;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: InkWell(
                            onTap: () => _onNavTap(i),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.primaryColor
                                        .withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: selected
                                    ? Border.all(
                                        color: AppTheme.primaryLight
                                            .withValues(alpha: 0.3),
                                        width: 1)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 20,
                                        color: selected
                                            ? AppTheme.primaryLight
                                            : Colors.white38,
                                      ),
                                      if (isFeedback && _pendingFeedback > 0)
                                        Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.errorColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                _pendingFeedback > 9
                                                    ? '9+'
                                                    : '$_pendingFeedback',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      color: selected
                                          ? AppTheme.primaryLight
                                          : Colors.white60,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom: admin email + logout
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: AppTheme.darkBorder),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.account_circle_outlined,
                                color: Colors.white38, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                adminState.adminEmail ?? 'Admin',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await _showLogoutConfirmDialog();
                              if (!confirm) return;
                              await ref
                                  .read(adminAuthProvider.notifier)
                                  .signOut();
                              if (context.mounted) {
                                context.go(AppRoutes.adminLogin);
                              }
                            },
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(
                                  color: AppTheme.errorColor, width: 0.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Main content ───────────────────────────────────
          Expanded(child: widget.child),
        ],
      ),

      // Bottom nav for narrow screens
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onNavTap,
              backgroundColor: AppTheme.darkSurface,
              selectedItemColor: AppTheme.primaryLight,
              unselectedItemColor: Colors.white38,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: showLabels,
              showUnselectedLabels: showLabels && showUnselected,
              selectedLabelStyle: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 9),
              items: _navItems.map((e) {
                final isFeedback = e.route == AppRoutes.adminFeedback;
                return BottomNavigationBarItem(
                  icon: isFeedback && _pendingFeedback > 0
                      ? Badge(
                          label: Text('$_pendingFeedback'),
                          backgroundColor: AppTheme.errorColor,
                          child: Icon(e.icon),
                        )
                      : Icon(e.icon),
                  label: e.label,
                );
              }).toList(),
            ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;
  const _NavItem(
      {required this.route, required this.icon, required this.label});
}
