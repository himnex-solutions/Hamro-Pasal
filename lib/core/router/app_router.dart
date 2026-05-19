import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hamro_pasal/features/auth/presentation/screens/splash_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/screens/login_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/screens/signup_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/screens/business_setup_screen.dart';
import 'package:hamro_pasal/features/auth/presentation/screens/onboarding_screen.dart';



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
import 'package:hamro_pasal/features/invoices/presentation/screens/create_invoice_screen.dart';
import 'package:hamro_pasal/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:hamro_pasal/features/expenses/presentation/screens/expenses_screen.dart';

import 'package:hamro_pasal/features/reports/presentation/screens/reports_screen.dart';
import 'package:hamro_pasal/features/staff/presentation/screens/staff_screen.dart';
import 'package:hamro_pasal/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:hamro_pasal/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:hamro_pasal/features/subscription/presentation/screens/trial_expired_screen.dart';
import 'package:hamro_pasal/features/settings/presentation/screens/settings_screen.dart';
import 'package:hamro_pasal/features/tools/presentation/screens/tools_screen.dart';
import 'package:hamro_pasal/features/tools/presentation/screens/calculator_screen.dart';
import 'package:hamro_pasal/features/tools/presentation/screens/emi_calculator_screen.dart';
import 'package:hamro_pasal/core/shell/main_shell_screen.dart';
import 'package:hamro_pasal/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:hamro_pasal/features/admin/presentation/screens/admin_login_screen.dart';
import 'package:hamro_pasal/features/admin/presentation/screens/admin_shell_screen.dart';
import 'package:hamro_pasal/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:hamro_pasal/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:hamro_pasal/features/admin/presentation/screens/admin_businesses_screen.dart';
import 'package:hamro_pasal/features/admin/presentation/screens/admin_subscriptions_screen.dart';

// ── Route Name Constants ──────────────────────────────────────
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
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
  static const String tools = '/home/tools';
  static const String calculator = '/home/tools/calculator';
  static const String emiCalculator = '/home/tools/emi';

  static const String subscription = '/subscription';
  static const String trialExpired = '/trial-expired';
  static const String settings = '/settings';

  // ── Admin routes ───────────────────────────────────────
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminBusinesses = '/admin/businesses';
  static const String adminSubscriptions = '/admin/subscriptions';
}

// ── Admin auth listenable ─────────────────────────────────────
// Lets GoRouter re-evaluate redirects whenever adminAuthProvider changes
// (e.g. after the async _checkExistingSession() resolves on page refresh).
class _AdminAuthListenable extends ChangeNotifier {
  _AdminAuthListenable(Ref ref) {
    ref.listen<AdminAuthState>(adminAuthProvider, (_, __) {
      notifyListeners();
    });
  }
}

// ── Router Provider ───────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  // NOTE: Do NOT watch authProvider here.
  // Watching it would recreate the GoRouter on every auth state change,
  // which resets the navigator stack and prevents OTP/setup screens from
  // being pushed. All routing after auth events is handled explicitly
  // in each screen via context.push / context.go.

  // Re-run redirects when admin auth state changes (fixes refresh bug)
  final adminListenable = _AdminAuthListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: adminListenable,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final location = state.uri.path;

      // Routes that never require a session
      const publicRoutes = [
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
        AppRoutes.splash,
        AppRoutes.otpVerification,
        AppRoutes.onboarding,
        AppRoutes.adminLogin, // Admin login is public — guard is inside the admin ShellRoute
      ];

      final isPublic = publicRoutes.contains(location);

      // No session & trying to access a protected route → go to login
      if (session == null && !isPublic) return AppRoutes.login;

      return null;
    },
    routes: [
      // ── Public / Auth routes ──────────────────────────────
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, __) => const ForgotPasswordScreen()),

      // OTP verification — receives email via GoRouter `extra`
      GoRoute(
        path: AppRoutes.otpVerification,
        builder: (_, state) {
          final email = state.extra as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),

      GoRoute(
          path: AppRoutes.businessSetup,
          builder: (_, __) => const BusinessSetupScreen()),
      GoRoute(
          path: AppRoutes.trialExpired,
          builder: (_, __) => const TrialExpiredScreen()),
      GoRoute(
          path: AppRoutes.subscription,
          builder: (_, __) => const SubscriptionScreen()),
      GoRoute(
          path: AppRoutes.settings,
          builder: (_, __) => const SettingsScreen()),

      // ── Shell routes (bottom nav / rail / sidebar) ────────
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
                builder: (_, state) => PartyDetailScreen(
                    partyId: state.pathParameters['id']!),
              ),
            ],
          ),

          // Inventory
          GoRoute(
            path: AppRoutes.inventory,
            builder: (_, __) => const InventoryScreen(),
            routes: [
              GoRoute(
                  path: 'add', builder: (_, __) => const AddProductScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => ProductDetailScreen(
                    productId: state.pathParameters['id']!),
              ),
            ],
          ),

          // Transactions
          GoRoute(
            path: AppRoutes.transactions,
            builder: (_, __) => const TransactionsScreen(),
            routes: [
              GoRoute(
                  path: 'add',
                  builder: (_, __) => const AddTransactionScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => TransactionDetailScreen(
                    transactionId: state.pathParameters['id']!),
              ),
            ],
          ),

          // Invoices
          GoRoute(
            path: AppRoutes.invoices,
            builder: (_, __) => const InvoicesScreen(),
            routes: [
              GoRoute(
                  path: 'create',
                  builder: (_, __) => const CreateInvoiceScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => InvoiceDetailScreen(
                    invoiceId: state.pathParameters['id']!),
              ),
            ],
          ),

          // Expenses
          GoRoute(
            path: AppRoutes.expenses,
            builder: (_, __) => const ExpensesScreen(),
            routes: [
              GoRoute(
                  path: 'add', builder: (_, __) => const AddExpenseScreen()),
            ],
          ),

          // Other shell routes
          GoRoute(
              path: AppRoutes.reports,
              builder: (_, __) => const ReportsScreen()),
          GoRoute(
              path: AppRoutes.staff, builder: (_, __) => const StaffScreen()),
          GoRoute(
              path: AppRoutes.accounts,
              builder: (_, __) => const AccountsScreen()),

          // Tools hub + sub-pages
          GoRoute(
            path: AppRoutes.tools,
            builder: (_, __) => const ToolsScreen(),
            routes: [
              GoRoute(
                path: 'calculator',
                builder: (_, __) => const CalculatorScreen(),
              ),
              GoRoute(
                path: 'emi',
                builder: (_, __) => const EmiCalculatorScreen(),
              ),
            ],
          ),
        ],
      ),

    // ── Admin routes ────────────────────────────────────────
    GoRoute(
      path: AppRoutes.adminLogin,
      builder: (_, __) => const AdminLoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShellScreen(child: child),
      redirect: (context, state) {
        final adminStatus = ref.read(adminAuthProvider).status;

        // Still verifying session (async check on page refresh) → wait.
        // refreshListenable will re-trigger this redirect once resolved.
        if (adminStatus == AdminAuthStatus.initial) return null;

        // No Supabase session → definitely logged out
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return AppRoutes.adminLogin;

        // Session exists but not an admin (error / access denied)
        if (adminStatus != AdminAuthStatus.authenticated) {
          return AppRoutes.adminLogin;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.adminDashboard,
          builder: (_, __) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminUsers,
          builder: (_, __) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminBusinesses,
          builder: (_, __) => const AdminBusinessesScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminSubscriptions,
          builder: (_, __) => const AdminSubscriptionsScreen(),
        ),
      ],
    ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});
