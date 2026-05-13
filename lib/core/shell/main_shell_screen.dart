import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hamro_pasal/core/l10n/app_strings.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/services/sync_service.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const MainShellScreen({super.key, required this.child});

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

// ── Mobile: Premium Bottom Navigation ──────────────────────────
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: destinations.asMap().entries.map((e) {
                final isSelected = e.key == selectedIndex;
                return Expanded(
                  child: _BottomNavItem(
                    item: e.value,
                    isSelected: isSelected,
                    onTap: () => onDestinationSelected(e.key),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  const _BottomNavItem({required this.item, required this.isSelected, required this.onTap});

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    if (widget.isSelected) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_BottomNavItem old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _ctrl.forward();
    } else if (!widget.isSelected && old.isSelected) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.isSelected ? 42 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              widget.isSelected ? widget.item.activeIcon : widget.item.icon,
              color: widget.isSelected ? AppTheme.primaryColor : AppTheme.lightTextHint,
              size: 22,
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.normal,
                color: widget.isSelected ? AppTheme.primaryColor : AppTheme.lightTextHint,
              ),
              child: Text(widget.item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tablet: Navigation Rail ───────────────────────────────────
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.selected,
              minWidth: 72,
              selectedIconTheme: const IconThemeData(color: AppTheme.primaryColor),
              selectedLabelTextStyle: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              destinations: destinations.map((d) => NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.activeIcon),
                label: Text(d.label),
              )).toList(),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Desktop: Premium Sidebar ──────────────────────────────────
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
          _PremiumSidebar(
            selectedIndex: selectedIndex,
            destinations: destinations,
            sidebarExtras: sidebarExtras,
            onDestinationSelected: onDestinationSelected,
            onExtraSelected: onExtraSelected,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _PremiumSidebar extends ConsumerWidget {
  final int selectedIndex;
  final List<_NavItem> destinations;
  final List<_NavItem> sidebarExtras;
  final void Function(int) onDestinationSelected;
  final void Function(int) onExtraSelected;
  const _PremiumSidebar({
    required this.selectedIndex, required this.destinations,
    required this.sidebarExtras, required this.onDestinationSelected,
    required this.onExtraSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectivity = ref.watch(connectivityProvider);

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.12),
                  AppTheme.primaryColor.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.10),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF60A5FA), AppTheme.primaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Hamro Pasal',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                connectivity.when(
                  data: (s) => _ConnectivityBadge(s),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // MAIN section
          const _SectionLabel('MAIN'),
          ...destinations.asMap().entries.map((e) => _SidebarTile(
            item: e.value,
            isSelected: e.key == selectedIndex,
            onTap: () => onDestinationSelected(e.key),
          ).animate(delay: Duration(milliseconds: e.key * 40)).fadeIn().slideX(begin: -0.05, end: 0)),

          const SizedBox(height: 12),

          // MORE section
          const _SectionLabel('MORE'),
          ...sidebarExtras.asMap().entries.map((e) => _SidebarTile(
            item: e.value,
            isSelected: false,
            onTap: () => onExtraSelected(e.key),
          ).animate(delay: Duration(milliseconds: 200 + e.key * 40)).fadeIn().slideX(begin: -0.05, end: 0)),

          const Spacer(),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),

          // Upgrade tile
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
            child: _UpgradeTile(onTap: () => context.push(AppRoutes.subscription)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 16, 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppTheme.lightTextHint,
        letterSpacing: 1.5,
      ),
    ),
  );
}

class _SidebarTile extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  const _SidebarTile({required this.item, required this.isSelected, required this.onTap});

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = AppTheme.primaryColor;
    final textColor = widget.isSelected
        ? activeColor
        : _hovered
            ? (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)
            : AppTheme.lightTextSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? activeColor.withValues(alpha: 0.12)
                  : _hovered
                      ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03))
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: widget.isSelected
                  ? Border.all(color: activeColor.withValues(alpha: 0.2), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                // Selected indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: widget.isSelected ? 3 : 0,
                  height: 20,
                  margin: EdgeInsets.only(right: widget.isSelected ? 10 : 0),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                  color: textColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpgradeTile extends StatefulWidget {
  final VoidCallback onTap;
  const _UpgradeTile({required this.onTap});
  @override
  State<_UpgradeTile> createState() => _UpgradeTileState();
}

class _UpgradeTileState extends State<_UpgradeTile> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                  : [const Color(0xFFFBBF24).withValues(alpha: 0.15), const Color(0xFFF59E0B).withValues(alpha: 0.10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: _hovered ? 0.8 : 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: _hovered ? Colors.white : const Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Upgrade Plan',
                style: TextStyle(
                  color: _hovered ? Colors.white : const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOnline
            ? AppTheme.successColor.withValues(alpha: 0.12)
            : AppTheme.warningColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? AppTheme.successColor.withValues(alpha: 0.25)
              : AppTheme.warningColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.successColor : AppTheme.warningColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isOnline ? AppTheme.successColor : AppTheme.warningColor).withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              color: isOnline ? AppTheme.successColor : AppTheme.warningColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
