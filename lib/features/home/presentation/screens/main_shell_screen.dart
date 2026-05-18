import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hamro_pasal/core/router/app_router.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';

class MainShellScreen extends ConsumerWidget {
  final Widget child;
  final String location;

  const MainShellScreen({
    super.key,
    required this.child,
    required this.location,
  });

  static const _navItems = [
    _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
        route: AppRoutes.dashboard),
    _NavItem(
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        label: 'Parties',
        route: AppRoutes.parties),
    _NavItem(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        label: 'Inventory',
        route: AppRoutes.inventory),
    _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Transactions',
        route: AppRoutes.transactions),
    _NavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: 'Reports',
        route: AppRoutes.reports),
  ];

  static const _sidebarItems = [
    _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
        route: AppRoutes.dashboard),
    _NavItem(
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        label: 'Parties',
        route: AppRoutes.parties),
    _NavItem(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        label: 'Inventory',
        route: AppRoutes.inventory),
    _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Transactions',
        route: AppRoutes.transactions),
    _NavItem(
        icon: Icons.description_outlined,
        activeIcon: Icons.description_rounded,
        label: 'Invoices',
        route: AppRoutes.invoices),
    _NavItem(
        icon: Icons.wallet_outlined,
        activeIcon: Icons.wallet_rounded,
        label: 'Expenses',
        route: AppRoutes.expenses),
    _NavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: 'Reports',
        route: AppRoutes.reports),
    _NavItem(
        icon: Icons.group_outlined,
        activeIcon: Icons.group_rounded,
        label: 'Staff',
        route: AppRoutes.staff),
    _NavItem(
        icon: Icons.account_balance_outlined,
        activeIcon: Icons.account_balance_rounded,
        label: 'Accounts',
        route: AppRoutes.accounts),
    _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Settings',
        route: AppRoutes.settings),
  ];

  int _selectedIndex() {
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  int _sidebarSelectedIndex() {
    for (int i = 0; i < _sidebarItems.length; i++) {
      if (location.startsWith(_sidebarItems[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (isDesktop) return _buildDesktopLayout(context);
    if (isTablet) return _buildTabletLayout(context);
    return _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(),
        onTap: (i) => context.go(_navItems[i].route),
        items: _navItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addTransaction),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _sidebarSelectedIndex(),
            onDestinationSelected: (i) => context.go(_sidebarItems[i].route),
            labelType: NavigationRailLabelType.selected,
            backgroundColor: AppTheme.lightSurface,
            selectedIconTheme:
                const IconThemeData(color: AppTheme.primaryColor),
            selectedLabelTextStyle: const TextStyle(
                color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
            destinations: _sidebarItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: Text(item.label),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final selectedIdx = _sidebarSelectedIndex();
    return Scaffold(
      body: Row(
        children: [
          // Full sidebar
          Container(
            width: 240,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Sidebar header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('HP',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hamro Pasal',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('Business Suite',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // Nav items
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: _sidebarItems.length,
                    itemBuilder: (context, i) {
                      final item = _sidebarItems[i];
                      final isSelected = i == selectedIdx;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          selected: isSelected,
                          selectedTileColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          leading: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 22,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.lightTextSecondary,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                          onTap: () => context.go(item.route),
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                        ),
                      );
                    },
                  ),
                ),
                // Subscription status at bottom
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium,
                            color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Free Trial',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              )),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.subscription),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Upgrade',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
