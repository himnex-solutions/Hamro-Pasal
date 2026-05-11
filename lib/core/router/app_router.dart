import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hamro_pasal/features/auth/presentation/screens/splash_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/screens/login_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/screens/signup_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/screens/business_setup_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/providers/auth_provider.dart';

import 'package:hamro_pasal/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:hamro_pasal/features/parties/presentation/screens/parties_screen.dart';
import 'package:hamro_pasal/features/parties/presentation/screens/add_party_screen.dart';
import 'package:hamro_pasal/features/parties/presentation/screens/party_detail_screen.dart';
import 'package:hamro_pasal/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:hamro_pasal/features/inventory/presentation/screens/add_product_screen.dart';
import 'package:hamro_pasal/features/inventory/presentation/screens/product_detail_screen.dart';
import 'package:hamro_pasal/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:hamro_pasal/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:hamro_pasal/features/transactions/presentation/screens/transaction_detail_screen.dart';
import 'package:hamro_pasal/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:hamro_pasal/features/expenses/presentation/screens/expenses_screen.dart';

import 'package:hamro_pasal/features/reports/presentation/screens/reports_screen.dart';
import 'package:hamro_pasal/features/staff/presentation/screens/staff_screen.dart';
import 'package:hamro_pasal/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:hamro_pasal/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:hamro_pasal/features/subscription/presentation/screens/trial_expired_screen.dart';
import 'package:hamro_pasal/features/settings/presentation/screens/settings_screen.dart';
import 'package:hamro_pasal/core/shell/main_shell_screen.dart';

// ── Route Name Constants ──────────────────────────────────────
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String businessSetup = '/business-setup';

  static const String home = '/home';
  static const String dashboard = '/home/dashboard';
  static const String parties = '/home/parties';
  static const String addParty = '/home/parties/add';
  static const String inventory = '/home/inventory';
  static const String addProduct = '/home/inventory/add';
  static const String transactions = '/home/transactions';
  static const String addTransaction = '/home/transactions/add';
  static const String invoices = '/home/invoices';
  static const String createInvoice = '/home/invoices/create';
  static const String expenses = '/home/expenses';
  static const String addExpense = '/home/expenses/add';
  static const String reports = '/home/reports';
  static const String staff = '/home/staff';
  static const String accounts = '/home/accounts';

  static const String subscription = '/subscription';
  static const String trialExpired = '/trial-expired';
  static const String settings = '/settings';
}

// ── Router Provider ───────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final location = state.uri.path;
      final isAuthRoute = [
        AppRoutes.login, AppRoutes.signup,
        AppRoutes.forgotPassword, AppRoutes.splash,
      ].contains(location);

      if (session == null && !isAuthRoute) return AppRoutes.login;
      if (session != null && isAuthRoute && location != AppRoutes.splash) return null;
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.businessSetup, builder: (_, __) => const BusinessSetupScreen()),
      GoRoute(path: AppRoutes.trialExpired, builder: (_, __) => const TrialExpiredScreen()),
      GoRoute(path: AppRoutes.subscription, builder: (_, __) => const SubscriptionScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),

      // Shell routes (with bottom nav / rail / sidebar)
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),

          // Parties
          GoRoute(
            path: AppRoutes.parties,
            builder: (_, __) => const PartiesScreen(),
            routes: [
              GoRoute(path: 'add', builder: (_, __) => const AddPartyScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => PartyDetailScreen(partyId: state.pathParameters['id']!),
              ),
            ],
          ),

          // Inventory
          GoRoute(
            path: AppRoutes.inventory,
            builder: (_, __) => const InventoryScreen(),
            routes: [
              GoRoute(path: 'add', builder: (_, __) => const AddProductScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
              ),
            ],
          ),

          // Transactions
          GoRoute(
            path: AppRoutes.transactions,
            builder: (_, __) => const TransactionsScreen(),
            routes: [
              GoRoute(path: 'add', builder: (_, __) => const AddTransactionScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => TransactionDetailScreen(transactionId: state.pathParameters['id']!),
              ),
            ],
          ),

          // Invoices
          GoRoute(
            path: AppRoutes.invoices,
            builder: (_, __) => const InvoicesScreen(),
            routes: [
              GoRoute(path: 'create', builder: (_, __) => const CreateInvoiceScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
              ),
            ],
          ),

          // Expenses
          GoRoute(
            path: AppRoutes.expenses,
            builder: (_, __) => const ExpensesScreen(),
            routes: [
              GoRoute(path: 'add', builder: (_, __) => const AddExpenseScreen()),
            ],
          ),

          // Other shell routes
          GoRoute(path: AppRoutes.reports, builder: (_, __) => const ReportsScreen()),
          GoRoute(path: AppRoutes.staff, builder: (_, __) => const StaffScreen()),
          GoRoute(path: AppRoutes.accounts, builder: (_, __) => const AccountsScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});
