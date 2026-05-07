class AppConstants {
  AppConstants._();

  // ── Supabase ──────────────────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // ── App Info ──────────────────────────────────────────────────
  static const String appName = 'Hamro Pasal';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Smart Business for Nepal';

  // ── Subscription Plans ────────────────────────────────────────
  static const int freeTrial = 14; // days
  static const double monthlyPrice = 250.0;
  static const double sixMonthPrice = 1299.0;
  static const double yearlyPrice = 2299.0;

  // ── Free Plan Limits ──────────────────────────────────────────
  static const int freeProductLimit = 50;
  static const int freeCustomerLimit = 20;
  static const int freeBillLimit = 100;

  // ── Hive Boxes ────────────────────────────────────────────────
  static const String settingsBox = 'settings_box';
  static const String offlineSalesBox = 'offline_sales_box';
  static const String offlineProductsBox = 'offline_products_box';
  static const String themeBox = 'theme_box';

  // ── Shared Prefs Keys ─────────────────────────────────────────
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyOnboarded = 'onboarded';

  // ── Route Names ───────────────────────────────────────────────
  static const String routeSplash = '/';
  static const String routeSelectProfile = '/select-profile';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeBusinessSignup = '/business-signup';
  static const String routePersonalSignup = '/personal-signup';
  static const String routeEmailOtp = '/email-otp';
  static const String routeEmailVerification = '/email-verification';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeResetPassword = '/reset-password';
  static const String routeProfileSetup = '/profile-setup';
  static const String routeSubscription = '/subscription';
  static const String routeDashboard = '/dashboard';
  static const String routePersonalDashboard = '/personal-dashboard';
  static const String routeProfileSwitcher = '/profile-switcher';
  static const String routeUpdatePersonalProfile = '/update-personal-profile';
  static const String routePOS = '/pos';
  static const String routeInventory = '/inventory';
  static const String routeAddProduct = '/inventory/add';
  static const String routeEditProduct = '/inventory/edit';
  static const String routeCustomers = '/customers';
  static const String routeCustomerDetail = '/customers/detail';
  static const String routeReports = '/reports';
  static const String routeExpenses = '/expenses';
  static const String routeSuppliers = '/suppliers';
  static const String routeSettings = '/settings';
  static const String routeReceipt = '/receipt';

  // ── Nepali Months ─────────────────────────────────────────────
  static const List<String> nepaliMonths = [
    'बैशाख', 'जेठ', 'असार', 'श्रावण', 'भदौ', 'असोज',
    'कार्तिक', 'मंसिर', 'पुष', 'माघ', 'फाल्गुन', 'चैत्र',
  ];

  // ── Payment Methods ───────────────────────────────────────────
  static const String paymentCash = 'cash';
  static const String paymentKhalti = 'khalti';
  static const String paymentEsewa = 'esewa';
  static const String paymentCredit = 'credit';
  static const String paymentQR = 'qr';
}
