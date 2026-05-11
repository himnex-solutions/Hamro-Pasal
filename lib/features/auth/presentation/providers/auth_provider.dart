import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';

// ── Auth Status ───────────────────────────────────────────────
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  needsOtpVerification,
  needsBusinessSetup,
}

// ── Auth State ────────────────────────────────────────────────
class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? pendingEmail; // email awaiting OTP verification

  const AuthState({
    required this.status,
    this.errorMessage,
    this.pendingEmail,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.authenticated() =>
      const AuthState(status: AuthStatus.authenticated);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.needsOtp(String email) =>
      AuthState(status: AuthStatus.needsOtpVerification, pendingEmail: email);
  factory AuthState.needsSetup() =>
      const AuthState(status: AuthStatus.needsBusinessSetup);
  factory AuthState.error(String msg) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
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

  // ─── Initialization ──────────────────────────────────────────
  Future<void> _init() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      state = AuthState.unauthenticated();
      return;
    }
    // Returning user: check business setup (OTP already done)
    final hasBusinessId = await _checkBusinessSetup();
    state = hasBusinessId ? AuthState.authenticated() : AuthState.needsSetup();
  }

  // ─── Business Setup Check ────────────────────────────────────
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
        await prefs.setString(AppConstants.kSelectedBusinessId, id);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ─── Sign Up ─────────────────────────────────────────────────
  /// Creates the account and redirects user to login (does NOT sign in).
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      // Always sign out immediately so the user must log in manually.
      await _supabase.auth.signOut();
      state = AuthState.unauthenticated();
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  // ─── Sign In ─────────────────────────────────────────────────
  /// Signs in with password. If first-time user (OTP not yet verified),
  /// attempts to send an OTP. If email sending fails (e.g. SMTP not
  /// configured on the Supabase project), skips OTP and proceeds directly.
  Future<bool> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      final userId = _supabase.auth.currentUser?.id ?? '';
      final verifiedKey = '${AppConstants.kEmailVerified}_$userId';
      final alreadyVerified = prefs.getBool(verifiedKey) ?? false;

      if (!alreadyVerified) {
        // First-time login → try to send OTP email
        bool otpSent = false;
        try {
          await _sendOtp(email);
          otpSent = true;
        } catch (_) {
          // OTP email failed (e.g. SMTP / email provider not configured).
          // Auto-mark as verified so the user isn't permanently blocked.
          await prefs.setBool(verifiedKey, true);
        }

        if (otpSent) {
          // Sign out the session — user must complete OTP to get it back.
          await _supabase.auth.signOut();
          state = AuthState.needsOtp(email);
          return true;
        }
        // Fall through: OTP unavailable, treat as verified
      }

      // Verified user → check business setup
      final hasBusinessId = await _checkBusinessSetup();
      state = hasBusinessId
          ? AuthState.authenticated()
          : AuthState.needsSetup();
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  // ─── Send OTP ────────────────────────────────────────────────
  Future<void> _sendOtp(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
    );
  }

  /// Public resend for the OTP screen "Resend" button.
  Future<bool> resendOtp(String email) async {
    try {
      await _sendOtp(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Verify OTP ──────────────────────────────────────────────
  /// Verifies the 6-digit OTP the user received via email.
  /// On success marks the user as verified and moves to business-setup or dashboard.
  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      // Mark this user as OTP-verified on this device
      final prefs = await SharedPreferences.getInstance();
      final userId = _supabase.auth.currentUser?.id ?? '';
      await prefs.setBool('${AppConstants.kEmailVerified}_$userId', true);

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

  // ─── Google Sign In ──────────────────────────────────────────
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

  // ─── Sign Out ────────────────────────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.kSelectedBusinessId);
    state = AuthState.unauthenticated();
  }

  // ─── Password Reset ──────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────
  bool get isAuthenticated => state.status == AuthStatus.authenticated;
  bool get needsBusinessSetup =>
      state.status == AuthStatus.needsBusinessSetup;
  bool get needsOtpVerification =>
      state.status == AuthStatus.needsOtpVerification;
}
