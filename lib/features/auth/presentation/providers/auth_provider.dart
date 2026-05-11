import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';

// ── Auth State ────────────────────────────────────────────────
enum AuthStatus { initial, authenticated, unauthenticated, needsBusinessSetup }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  const AuthState({required this.status, this.errorMessage});

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.authenticated() => const AuthState(status: AuthStatus.authenticated);
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.needsSetup() => const AuthState(status: AuthStatus.needsBusinessSetup);
  factory AuthState.error(String msg) => AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
}

// ── Auth Provider ─────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    _init();
  }

  final _supabase = Supabase.instance.client;

  Future<void> _init() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      state = AuthState.unauthenticated();
      return;
    }
    final hasBusinessId = await _checkBusinessSetup();
    state = hasBusinessId ? AuthState.authenticated() : AuthState.needsSetup();
  }

  Future<bool> _checkBusinessSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId != null && businessId.isNotEmpty) return true;

    // Fallback: check Supabase
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      final res = await _supabase
          .from('business_members')
          .select('business_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();
      if (res != null) {
        final id = res['business_id'] as String;
        final prefs2 = await SharedPreferences.getInstance();
        await prefs2.setString(AppConstants.kSelectedBusinessId, id);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      final hasBusinessId = await _checkBusinessSetup();
      state = hasBusinessId ? AuthState.authenticated() : AuthState.needsSetup();
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<bool> signUp({required String email, required String password, required String fullName}) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      state = AuthState.needsSetup();
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
      final hasBusinessId = await _checkBusinessSetup();
      state = hasBusinessId ? AuthState.authenticated() : AuthState.needsSetup();
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.kSelectedBusinessId);
    state = AuthState.unauthenticated();
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get isAuthenticated => state.status == AuthStatus.authenticated;
  bool get needsBusinessSetup => state.status == AuthStatus.needsBusinessSetup;
}
