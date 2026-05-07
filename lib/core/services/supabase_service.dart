import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  // ─── Auth ────────────────────────────────────────────────────────────────────

  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => currentUser?.id;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    // Sign up without sending verification email
    // Email verification is handled separately via OTP on first login
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'email_verified_custom': false},
    );
    return res;
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) =>
      client.auth.signInWithPassword(email: email, password: password);

  Future<void> signInWithOtp({
    required String email,
  }) =>
      client.auth.signInWithOtp(email: email);

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) =>
      client.auth.verifyOTP(email: email, token: token, type: OtpType.magiclink);

  /// Send OTP for email verification (not login)
  Future<void> sendVerificationOtp({
    required String email,
  }) =>
      client.auth.signInWithOtp(email: email, shouldCreateUser: false);

  /// Verify the email OTP code
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) =>
      client.auth.verifyOTP(email: email, token: token, type: OtpType.email);

  Future<bool> signInWithGoogle() =>
      client.auth.signInWithOAuth(OAuthProvider.google,
          redirectTo: 'io.supabase.hamropasal://login-callback');

  Future<void> signOut() => client.auth.signOut();

  Future<void> resetPassword(String email) =>
      client.auth.resetPasswordForEmail(email);

  // ─── Profile ─────────────────────────────────────────────────────────────────

  // User Profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final res = await client
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return res;
  }

  Future<void> upsertUserProfile(Map<String, dynamic> data) async {
    await client.from('user_profiles').upsert(data, onConflict: 'user_id');
  }

  // Business Profile
  Future<Map<String, dynamic>?> getBusinessProfile(String userId) async {
    final res = await client
        .from('business_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return res;
  }

  Future<void> upsertBusinessProfile(Map<String, dynamic> data) async {
    await client.from('business_profiles').upsert(data, onConflict: 'user_id');
  }

  // Personal Profile
  Future<Map<String, dynamic>?> getPersonalProfile(String userId) async {
    final res = await client
        .from('personal_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return res;
  }

  Future<void> upsertPersonalProfile(Map<String, dynamic> data) async {
    await client.from('personal_profiles').upsert(data, onConflict: 'user_id');
  }

  // Active Profile
  Future<Map<String, dynamic>?> getActiveProfile(String userId) async {
    final res = await client
        .from('active_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return res;
  }

  Future<void> upsertActiveProfile(Map<String, dynamic> data) async {
    await client.from('active_profiles').upsert(data, onConflict: 'user_id');
  }

  // ─── Subscription ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getSubscription(String userId) async {
    final res = await client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return res;
  }

  Future<void> upsertSubscription(Map<String, dynamic> data) async {
    await client.from('subscriptions').upsert(data);
  }

  // ─── Products ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProducts(String userId) async {
    final res = await client
        .from('products')
        .select()
        .eq('user_id', userId)
        .order('name');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> insertProduct(Map<String, dynamic> data) async {
    final res =
        await client.from('products').insert(data).select().single();
    return res;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await client.from('products').update(data).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
  }

  Future<void> decrementStock(String productId, int qty) async {
    await client.rpc('decrement_stock',
        params: {'product_id': productId, 'qty': qty});
  }

  // ─── Sales ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> insertSale(
      Map<String, dynamic> saleData, List<Map<String, dynamic>> items) async {
    final sale =
        await client.from('sales').insert(saleData).select().single();
    final saleId = sale['id'] as String;
    final itemsWithSaleId =
        items.map((e) => {...e, 'sale_id': saleId}).toList();
    await client.from('sale_items').insert(itemsWithSaleId);
    return sale;
  }

  Future<List<Map<String, dynamic>>> getSales(String userId,
      {DateTime? from, DateTime? to}) async {
    var query = client
        .from('sales')
        .select('*, sale_items(*)')
        .eq('user_id', userId);

    if (from != null) {
      query = query.gte('ad_date', from.toIso8601String().split('T')[0]);
    }
    if (to != null) {
      query = query.lte('ad_date', to.toIso8601String().split('T')[0]);
    }
    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Customers ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCustomers(String userId) async {
    final res = await client
        .from('customers')
        .select()
        .eq('user_id', userId)
        .order('name');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> insertCustomer(
      Map<String, dynamic> data) async {
    final res =
        await client.from('customers').insert(data).select().single();
    return res;
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    await client.from('customers').update(data).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getLedger(String customerId) async {
    final res = await client
        .from('ledger_transactions')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> insertLedgerTransaction(Map<String, dynamic> data) async {
    await client.from('ledger_transactions').insert(data);
  }

  // ─── Expenses ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getExpenses(String userId,
      {String? month}) async {
    var query = client
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .order('ad_date', ascending: false);
    final res = await query;
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> insertExpense(Map<String, dynamic> data) async {
    await client.from('expenses').insert(data);
  }

  Future<void> deleteExpense(String id) async {
    await client.from('expenses').delete().eq('id', id);
  }

  // ─── Suppliers ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSuppliers(String userId) async {
    final res = await client
        .from('suppliers')
        .select()
        .eq('user_id', userId)
        .order('name');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> insertSupplier(
      Map<String, dynamic> data) async {
    final res =
        await client.from('suppliers').insert(data).select().single();
    return res;
  }

  Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    await client.from('suppliers').update(data).eq('id', id);
  }
}
