class SupabaseConstants {
  SupabaseConstants._();


  static const String supabaseUrl = 'https://dgevkedwjmyggclnjbal.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_lL4kMneQ3Arv81QmJ2z5EA_aTYsYqzZ';

  // ── Table Names ───────────────────────────────────────────
  static const String tableUserProfiles = 'user_profiles';
  static const String tableBusinesses = 'businesses';
  static const String tableBusinessMembers = 'business_members';
  static const String tableSubscriptions = 'subscriptions';
  static const String tableSubscriptionPlans = 'subscription_plans';
  static const String tablePayments = 'payments';
  static const String tableParties = 'parties';
  static const String tableProducts = 'products';
  static const String tableProductCategories = 'product_categories';
  static const String tableTransactions = 'transactions';
  static const String tableTransactionItems = 'transaction_items';
  static const String tableInvoices = 'invoices';
  static const String tableInvoiceItems = 'invoice_items';
  static const String tableExpenses = 'expenses';
  static const String tableLedgerEntries = 'ledger_entries';
  static const String tableBankAccounts = 'bank_accounts';
  static const String tableStockMovements = 'stock_movements';
  static const String tableActivityLogs = 'activity_logs';
  static const String tableSyncQueue = 'sync_queue';

  // ── Storage Buckets ───────────────────────────────────────
  static const String businessLogosBucket = 'business-logos';
  static const String productImagesBucket = 'product-images';
  static const String receiptImagesBucket = 'receipt-images';

  // ── RPC Functions ─────────────────────────────────────────
  static const String rpcUpdateProductStock = 'update_product_stock';
  static const String rpcCheckTrialExpiry = 'check_trial_expiry';

  // ── OAuth ─────────────────────────────────────────────────
  static const String googleRedirectUrl = 'io.supabase.smartsaoji://login-callback/';
}
