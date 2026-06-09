import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Admin Auth State ──────────────────────────────────────────
enum AdminAuthStatus { initial, authenticated, unauthenticated, error }

class AdminAuthState {
  final AdminAuthStatus status;
  final String? errorMessage;
  final String? adminEmail;
  final String? adminFullName;
  const AdminAuthState({
    required this.status,
    this.errorMessage,
    this.adminEmail,
    this.adminFullName,
  });

  factory AdminAuthState.initial() =>
      const AdminAuthState(status: AdminAuthStatus.initial);
  factory AdminAuthState.authenticated(String email, String? fullName) =>
      AdminAuthState(
        status: AdminAuthStatus.authenticated,
        adminEmail: email,
        adminFullName: fullName,
      );
  factory AdminAuthState.unauthenticated() =>
      const AdminAuthState(status: AdminAuthStatus.unauthenticated);
  factory AdminAuthState.error(String msg) =>
      AdminAuthState(status: AdminAuthStatus.error, errorMessage: msg);
}

// ── Admin Auth Notifier ───────────────────────────────────────
final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  return AdminAuthNotifier();
});

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  AdminAuthNotifier() : super(AdminAuthState.initial()) {
    _checkExistingSession();
  }

  final _supabase = Supabase.instance.client;

  Future<void> _checkExistingSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      state = AdminAuthState.unauthenticated();
      return;
    }
    await _verifyAdminRole();
  }

  Future<bool> _verifyAdminRole() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        state = AdminAuthState.unauthenticated();
        return false;
      }
      final profile = await _supabase
          .from('user_profiles')
          .select('is_admin, email, full_name')
          .eq('id', userId)
          .single();
      if (profile['is_admin'] == true) {
        state = AdminAuthState.authenticated(
          profile['email'] as String,
          profile['full_name'] as String?,
        );
        return true;
      } else {
        await _supabase.auth.signOut();
        state = AdminAuthState.error('Access denied. Not an admin account.');
        return false;
      }
    } catch (e) {
      state = AdminAuthState.error('Failed to verify admin role: $e');
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = AdminAuthState.initial();
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return await _verifyAdminRole();
    } on AuthException catch (e) {
      state = AdminAuthState.error(e.message);
      return false;
    } catch (e) {
      state = AdminAuthState.error(e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = AdminAuthState.unauthenticated();
  }

  bool get isAuthenticated => state.status == AdminAuthStatus.authenticated;
}
