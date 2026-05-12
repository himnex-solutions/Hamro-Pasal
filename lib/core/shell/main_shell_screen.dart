import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamro_pasal/core/l10n/app_strings.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/services/sync_service.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const MainShellScreen({super.key, required this.child});

  // Routes are stable constants — labels come from l10n in build()
  static const _routes = [
    AppRoutes.dashboard, AppRoutes.transactions, AppRoutes.parties,
    AppRoutes.inventory, AppRoutes.expenses,
  ];
  static const _icons = [
    Icons.dashboard_outlined, Icons.receipt_long_outlined, Icons.people_outline,
    Icons.inventory_2_outlined, Icons.wallet_outlined,
  ];
  static const _activeIcons = [
    Icons.dashboard_rounded, Icons.receipt_long_rounded, Icons.people_rounded,
    Icons.inventory_2_rounded, Icons.wallet_rounded,
  ];
  static const _extraRoutes = [
    AppRoutes.invoices, AppRoutes.reports, AppRoutes.accounts,
    AppRoutes.staff, AppRoutes.settings,
  ];
  static const _extraIcons = [
    Icons.description_outlined, Icons.bar_chart_outlined,
    Icons.account_balance_outlined, Icons.group_outlined, Icons.settings_outlined,
  ];
  static const _extraActiveIcons = [
    Icons.description_rounded, Icons.bar_chart_rounded,
    Icons.account_balance_rounded, Icons.group_rounded, Icons.settings_rounded,
  ];

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    // Send heartbeat immediately then every 5 minutes to keep session alive
    _sendHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _sendHeartbeat(),
    );
  }

  void _sendHeartbeat() {
    ref.read(authProvider.notifier).heartbeat();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  int _locationIndex(String location) {
    for (int i = 0; i < MainShellScreen._routes.length; i++) {
      if (location.startsWith(MainShellScreen._routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _locationIndex(location);
    final screenWidth = MediaQuery.of(context).size.width;

    // Build localized nav items
    final labels = [l.dashboard, l.transactions, l.parties, l.inventory, l.expenses];
    final extraLabels = [l.invoices, l.reports, l.accounts, l.staff, l.settings];

    final destinations = List.generate(MainShellScreen._routes.length, (i) => _NavItem(
      MainShellScreen._routes[i],
      MainShellScreen._icons[i],
      MainShellScreen._activeIcons[i],
      labels[i],
    ));
    final sidebarExtras = List.generate(MainShellScreen._extraRoutes.length, (i) => _NavItem(
      MainShellScreen._extraRoutes[i],
      MainShellScreen._extraIcons[i],
      MainShellScreen._extraActiveIcons[i],
      extraLabels[i],
    ));

    if (screenWidth >= 1200) {
      return _DesktopShell(
        selectedIndex: selectedIndex,
        destinations: destinations,
        sidebarExtras: sidebarExtras,
        onDestinationSelected: (i) => context.go(destinations[i].route),
        onExtraSelected: (i) => context.push(sidebarExtras[i].route),
        child: widget.child,
      );
    } else if (screenWidth >= 600) {
      return _TabletShell(
        selectedIndex: selectedIndex,
        destinations: destinations,
        onDestinationSelected: (i) => context.go(destinations[i].route),
        child: widget.child,
      );
    } else {
      return _MobileShell(
        selectedIndex: selectedIndex,
        destinations: destinations,
        onDestinationSelected: (i) => context.go(destinations[i].route),
        child: widget.child,
      );
    }
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.route, this.icon, this.activeIcon, this.label);
}

// ── Mobile: Bottom Navigation ────────────────────────────────
class _MobileShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> destinations;
  final void Function(int) onDestinationSelected;
  const _MobileShell({
    required this.child, required this.selectedIndex,
    required this.destinations, required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 72,
        destinations: destinations.map((d) => NavigationDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.activeIcon),
          label: d.label,
        )).toList(),
      ),
    );
  }
}

// ── Tablet: Navigation Rail ──────────────────────────────────
class _TabletShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> destinations;
  final void Function(int) onDestinationSelected;
  const _TabletShell({
    required this.child, required this.selectedIndex,
    required this.destinations, required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.selected,
            minWidth: 72,
            destinations: destinations.map((d) => NavigationRailDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.activeIcon),
              label: Text(d.label),
            )).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Desktop: Full Sidebar ────────────────────────────────────
class _DesktopShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> destinations;
  final List<_NavItem> sidebarExtras;
  final void Function(int) onDestinationSelected;
  final void Function(int) onExtraSelected;
  const _DesktopShell({
    required this.child, required this.selectedIndex,
    required this.destinations, required this.sidebarExtras,
    required this.onDestinationSelected, required this.onExtraSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: selectedIndex,
            destinations: destinations,
            sidebarExtras: sidebarExtras,
            onDestinationSelected: onDestinationSelected,
            onExtraSelected: onExtraSelected,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final int selectedIndex;
  final List<_NavItem> destinations;
  final List<_NavItem> sidebarExtras;
  final void Function(int) onDestinationSelected;
  final void Function(int) onExtraSelected;
  const _Sidebar({
    required this.selectedIndex, required this.destinations,
    required this.sidebarExtras, required this.onDestinationSelected,
    required this.onExtraSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.store_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Hamro Pasal',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryColor, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                connectivity.when(
                  data: (s) => _ConnectivityBadge(s),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('MAIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppTheme.lightTextHint, letterSpacing: 1.2)),
          ),
          ...destinations.asMap().entries.map((e) {
            return _SidebarTile(
              item: e.value,
              isSelected: e.key == selectedIndex,
              onTap: () => onDestinationSelected(e.key),
            );
          }),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('MORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppTheme.lightTextHint, letterSpacing: 1.2)),
          ),
          ...sidebarExtras.asMap().entries.map((e) {
            return _SidebarTile(
              item: e.value,
              isSelected: false,
              onTap: () => onExtraSelected(e.key),
            );
          }),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _SidebarTile(
              item: const _NavItem(AppRoutes.subscription, Icons.workspace_premium_outlined,
                  Icons.workspace_premium_rounded, 'Upgrade'),
              isSelected: false,
              onTap: () => context.push(AppRoutes.subscription),
              accent: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accent;
  const _SidebarTile({required this.item, required this.isSelected, required this.onTap, this.accent});

  @override
  Widget build(BuildContext context) {
    final color = accent ?? (isSelected ? AppTheme.primaryColor : AppTheme.lightTextSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(isSelected ? item.activeIcon : item.icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(item.label, style: TextStyle(color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectivityBadge extends StatelessWidget {
  final ConnectivityStatus status;
  const _ConnectivityBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final isOnline = status == ConnectivityStatus.online;
    return Row(
      children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(
                color: isOnline ? AppTheme.successColor : AppTheme.warningColor,
                shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(isOnline ? 'Online' : 'Offline',
            style: TextStyle(fontSize: 11,
                color: isOnline ? AppTheme.successColor : AppTheme.warningColor,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
