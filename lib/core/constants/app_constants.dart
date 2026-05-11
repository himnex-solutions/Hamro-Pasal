class AppConstants {
  AppConstants._();

  // ── Currency ───────────────────────────────────────────────
  static const String currency = 'NPR';
  static const String currencySymbol = 'Rs.';

  // ── Date Formats ───────────────────────────────────────────
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String shortDateFormat = 'dd/MM/yy';

  // ── Trial ──────────────────────────────────────────────────
  static const int trialDays = 14;

  // ── SharedPreferences Keys ────────────────────────────────
  static const String kSelectedBusinessId = 'selected_business_id';
  static const String kOnboardingDone = 'onboarding_done';
  static const String kThemeMode = 'theme_mode';
  static const String kLastSyncTime = 'last_sync_time';

  // ── Subscription Statuses ─────────────────────────────────
  static const String statusTrialActive = 'trial_active';
  static const String statusTrialExpired = 'trial_expired';
  static const String statusActive = 'active';
  static const String statusExpired = 'expired';
  static const String statusCancelled = 'cancelled';
  static const String statusPendingPayment = 'pending_payment';

  // ── Transaction Types ─────────────────────────────────────
  static const String txSale = 'sale';
  static const String txPurchase = 'purchase';
  static const String txExpense = 'expense';
  static const String txIncome = 'income';

  // ── Payment Methods ───────────────────────────────────────
  static const String paymentCash = 'cash';
  static const String paymentBank = 'bank';
  static const String paymentCredit = 'credit';
  static const String paymentPartial = 'partial';
  static const String paymentKhalti = 'khalti';
  static const String paymentEsewa = 'esewa';

  // ── Party Types ───────────────────────────────────────────
  static const String partyCustomer = 'customer';
  static const String partySupplier = 'supplier';
  static const String partyBoth = 'both';

  // ── Business Types ────────────────────────────────────────
  static const List<String> businessTypes = [
    'Retail Shop',
    'Wholesale Business',
    'Restaurant / Hotel',
    'Medical / Pharmacy',
    'Electronics Shop',
    'Clothing Store',
    'Hardware / Construction',
    'Grocery Store',
    'Service Business',
    'Online Business',
    'Other',
  ];

  // ── Staff Roles ───────────────────────────────────────────
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleCashier = 'cashier';
  static const String roleAccountant = 'accountant';

  // ── Expense Categories ────────────────────────────────────
  static const List<String> expenseCategories = [
    'Rent',
    'Salary',
    'Electricity',
    'Transport',
    'Purchase cost',
    'Internet',
    'Water',
    'Office Supplies',
    'Marketing',
    'Maintenance',
    'Other',
  ];

  // ── Plans ─────────────────────────────────────────────────
  static const String planMonthly = 'monthly';
  static const String planYearly = 'yearly';
  static const int planMonthlyPrice = 499;
  static const int planYearlyPrice = 4499;

  // ── Pagination ────────────────────────────────────────────
  static const int pageSize = 50;
  static const int dashboardRecentTxCount = 5;
  static const int reportTopProductCount = 5;
}
