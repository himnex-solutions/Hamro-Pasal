import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/subscription/screens/subscription_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/pos/screens/pos_screen.dart';
import '../../features/pos/screens/receipt_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/inventory/screens/add_edit_product_screen.dart';
import '../../features/customers/screens/customer_list_screen.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/expenses/screens/expense_screen.dart';
import '../../features/suppliers/screens/supplier_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/auth/screens/select_profile_screen.dart';
import '../../features/auth/screens/business_signup_screen.dart';
import '../../features/auth/screens/personal_signup_screen.dart';
import '../../features/auth/screens/email_otp_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/providers/profile_provider.dart';
import '../../features/dashboard/screens/personal_dashboard_screen.dart';
import '../../features/profile/screens/profile_switcher_screen.dart';
import '../../features/profile/screens/update_personal_profile_screen.dart';
import '../constants/app_constants.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Keep this provider alive — GoRouter must never be recreated mid-session
  ref.keepAlive();

  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(
      SupabaseService.instance.authStateChanges,
    ),
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final loc = state.matchedLocation;

      final isAuthPage = loc == AppConstants.routeLogin ||
          loc == AppConstants.routeSignup ||
          loc == AppConstants.routeSelectProfile ||
          loc == AppConstants.routeBusinessSignup ||
          loc == AppConstants.routePersonalSignup ||
          loc == AppConstants.routeEmailOtp ||
          loc == AppConstants.routeEmailVerification ||
          loc == AppConstants.routeForgotPassword ||
          loc == AppConstants.routeResetPassword;

      if (!isLoggedIn && !isAuthPage && loc != AppConstants.routeSplash) {
        return AppConstants.routeSelectProfile;
      }

      // Don't redirect away from email verification
      if (isLoggedIn && loc == AppConstants.routeEmailVerification) {
        return null;
      }

      if (isLoggedIn && isAuthPage) {
        return AppConstants.routeSplash;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSelectProfile,
        name: 'select-profile',
        builder: (context, state) => const SelectProfileScreen(),
      ),
      GoRoute(
        path: AppConstants.routeBusinessSignup,
        name: 'business-signup',
        builder: (context, state) => const BusinessSignupScreen(),
      ),
      GoRoute(
        path: AppConstants.routePersonalSignup,
        name: 'personal-signup',
        builder: (context, state) => const PersonalSignupScreen(),
      ),
      GoRoute(
        path: AppConstants.routeEmailOtp,
        name: 'email-otp',
        builder: (context, state) => const EmailOtpScreen(),
      ),
      GoRoute(
        path: AppConstants.routeEmailVerification,
        name: 'email-verification',
        builder: (context, state) => EmailVerificationScreen(
          email: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: AppConstants.routeForgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppConstants.routeResetPassword,
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProfileSwitcher,
        name: 'profile-switcher',
        builder: (context, state) => const ProfileSwitcherScreen(),
      ),
      GoRoute(
        path: AppConstants.routeUpdatePersonalProfile,
        name: 'update-personal-profile',
        builder: (context, state) => const UpdatePersonalProfileScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSignup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProfileSetup,
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSubscription,
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppConstants.routeDashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppConstants.routePersonalDashboard,
            name: 'personal-dashboard',
            builder: (context, state) => const PersonalDashboardScreen(),
          ),
          GoRoute(
            path: AppConstants.routeInventory,
            name: 'inventory',
            builder: (context, state) => const InventoryScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-product',
                builder: (context, state) =>
                    const AddEditProductScreen(product: null),
              ),
              GoRoute(
                path: 'edit',
                name: 'edit-product',
                builder: (context, state) => AddEditProductScreen(
                  product: state.extra as Map<String, dynamic>?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppConstants.routeCustomers,
            name: 'customers',
            builder: (context, state) => const CustomerListScreen(),
            routes: [
              GoRoute(
                path: 'detail',
                name: 'customer-detail',
                builder: (context, state) => CustomerDetailScreen(
                  customerId: state.extra as String,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppConstants.routeReports,
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppConstants.routeExpenses,
            name: 'expenses',
            builder: (context, state) => const ExpenseScreen(),
          ),
          GoRoute(
            path: AppConstants.routeSuppliers,
            name: 'suppliers',
            builder: (context, state) => const SupplierScreen(),
          ),
          GoRoute(
            path: AppConstants.routeSettings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppConstants.routePOS,
        name: 'pos',
        builder: (context, state) => const POSScreen(),
      ),
      GoRoute(
        path: AppConstants.routeReceipt,
        name: 'receipt',
        builder: (context, state) => ReceiptScreen(
          saleData: state.extra as Map<String, dynamic>,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  final List<_NavItem> _businessNavItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', path: '/dashboard'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Inventory', path: '/inventory'),
    _NavItem(icon: Icons.people_rounded, label: 'Customers', path: '/customers'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports', path: '/reports'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings', path: '/settings'),
  ];

  final List<_NavItem> _personalNavItems = const [
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Home', path: '/personal-dashboard'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Expenses', path: '/expenses'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings', path: '/settings'),
  ];

  void _onNavTap(BuildContext context, int i, List<_NavItem> navItems) {
    setState(() => _selectedIndex = i);
    context.go(navItems[i].path);
    
    // Invalidate providers to ensure data is fresh
    if (navItems[i].path == AppConstants.routeDashboard) {
      ref.invalidate(dashboardStatsProvider);
    } else if (navItems[i].path == AppConstants.routeCustomers) {
      ref.invalidate(customersProvider);
    } else if (navItems[i].path == AppConstants.routeInventory) {
      ref.invalidate(inventoryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider).valueOrNull;
    final isBusiness = activeProfile?.activeProfileType != 'personal';
    final navItems = isBusiness ? _businessNavItems : _personalNavItems;

    // Keep selectedIndex in sync with actual route
    final location = GoRouterState.of(context).matchedLocation;
    final idx = navItems.indexWhere((n) => location.startsWith(n.path));
    if (idx != -1 && idx != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedIndex = idx);
        }
      });
    }

    final isWide = MediaQuery.of(context).size.width > 768;

    final scaffold = isWide
        ? Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) => _onNavTap(context, i, navItems),
                  labelType: NavigationRailLabelType.all,
                  destinations: navItems
                      .map((e) => NavigationRailDestination(
                            icon: Icon(e.icon),
                            label: Text(e.label),
                          ))
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: widget.child),
              ],
            ),
          )
        : Scaffold(
            body: widget.child,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) => _onNavTap(context, i, navItems),
              type: BottomNavigationBarType.fixed,
              items: navItems
                  .map((e) => BottomNavigationBarItem(
                        icon: Icon(e.icon),
                        label: e.label,
                      ))
                  .toList(),
            ),
          );

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go(navItems[0].path);
          setState(() => _selectedIndex = 0);
        }
      },
      child: scaffold,
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}

/// Makes GoRouter listen to a Stream (Supabase auth changes) and re-evaluate
/// the redirect function whenever a new auth event is emitted.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
