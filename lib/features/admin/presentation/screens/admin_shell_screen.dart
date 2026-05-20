import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminAuthProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    // Show loader while the async session check is in progress (page refresh).
    // The GoRouter redirect passes through during `initial` — this prevents
    // any flash of the shell content before auth is confirmed.
    if (adminState.status == AdminAuthStatus.initial) {
      return const Scaffold(
        backgroundColor: Color(0xFF070C18),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFF59E0B)),
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
      backgroundColor: const Color(0xFF070C18),
      body: Row(
        children: [
          // ── Sidebar (wide screens) ─────────────────────────
          if (isWide)
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF0E1525),
                border: Border(
                  right: BorderSide(
                      color: Colors.white.withValues(alpha: 0.07), width: 1),
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
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                            ),
                          ),
                          child: const Icon(Icons.shield_rounded,
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
                                color: Color(0xFFF59E0B),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.07)),
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
                                    ? const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: selected
                                    ? Border.all(
                                        color: const Color(0xFFF59E0B)
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
                                            ? const Color(0xFFF59E0B)
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
                                              color: Color(0xFFEF4444),
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
                                          ? const Color(0xFFF59E0B)
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
                        Divider(color: Colors.white.withValues(alpha: 0.07)),
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
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(
                                  color: Color(0xFFEF4444), width: 0.5),
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
              backgroundColor: const Color(0xFF0E1525),
              selectedItemColor: const Color(0xFFF59E0B),
              unselectedItemColor: Colors.white38,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600),
              items: _navItems.map((e) {
                final isFeedback = e.route == AppRoutes.adminFeedback;
                return BottomNavigationBarItem(
                  icon: isFeedback && _pendingFeedback > 0
                      ? Badge(
                          label: Text('$_pendingFeedback'),
                          backgroundColor: const Color(0xFFEF4444),
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
