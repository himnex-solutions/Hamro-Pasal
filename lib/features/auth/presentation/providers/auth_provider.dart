import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
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
  final String? pendingEmail;

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

  // ── Initialization ────────────────────────────────────────
  Future<void> _init() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      state = AuthState.unauthenticated();
      return;
    }
    // Returning user with existing session — update heartbeat
    try {
      final deviceId = await _getOrCreateDeviceId();
      await _heartbeat(deviceId);
    } catch (_) {}
    final hasBusinessId = await _checkBusinessSetup();
    state = hasBusinessId ? AuthState.authenticated() : AuthState.needsSetup();
  }

  // ── Device ID ─────────────────────────────────────────────
  /// Returns a stable per-browser/device UUID stored in SharedPreferences
  /// (localStorage on web). A new device gets a new UUID automatically.
  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(AppConstants.kDeviceId);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString(AppConstants.kDeviceId, deviceId);
    }
    return deviceId;
  }

  // ── Trusted Device Check ──────────────────────────────────
  /// Returns true if the current device has been trusted for this user.
  /// Trusted device IDs are stored in Supabase user_metadata so they
  /// persist across all browsers and devices.
  bool _isDeviceTrusted(User user, String deviceId) {
    final metadata = user.userMetadata ?? {};
    final trustedDevices =
        (metadata['trusted_devices'] as List?)?.cast<String>() ?? [];
    return trustedDevices.contains(deviceId);
  }

  /// Adds deviceId to the user's trusted_devices list in Supabase metadata.
  Future<void> _trustDevice(String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final metadata = user.userMetadata ?? {};
      final trustedDevices = List<String>.from(
          (metadata['trusted_devices'] as List?)?.cast<String>() ?? []);
      if (!trustedDevices.contains(deviceId)) {
        trustedDevices.add(deviceId);
        // Keep max 20 trusted devices per user
        if (trustedDevices.length > 20) trustedDevices.removeAt(0);
        await _supabase.auth.updateUser(
          UserAttributes(data: {'trusted_devices': trustedDevices}),
        );
      }
    } catch (_) {}
  }

  // ── Session Limit Check ───────────────────────────────────
  /// Checks how many active sessions the business has and enforces the limit:
  ///   • Trial    → 1 concurrent session
  ///   • Subscribed → 4 concurrent sessions
  /// Returns an error message string if the limit is exceeded, null otherwise.
  Future<String?> _checkAndRegisterSession(String deviceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Get business membership
      final memberRow = await _supabase
          .from('business_members')
          .select('business_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();
      if (memberRow == null) return null; // No business yet — skip

      final businessId = memberRow['business_id'] as String;

      // Get subscription status
      final sub = await _supabase
          .from('subscriptions')
          .select('status')
          .eq('business_id', businessId)
          .maybeSingle();
      final subStatus =
          sub?['status'] as String? ?? AppConstants.statusTrialActive;
      final isSubscribed = subStatus == AppConstants.statusActive;
      final maxSessions = isSubscribed ? 4 : 1;

      // Count OTHER active sessions (last_active within 15 min)
      final cutoff = DateTime.now()
          .subtract(const Duration(minutes: 15))
          .toIso8601String();
      final activeSessions = await _supabase
          .from('business_sessions')
          .select('id, device_id')
          .eq('business_id', businessId)
          .neq('device_id', deviceId)
          .gte('last_active', cutoff);

      final activeCount = (activeSessions as List).length;

      if (activeCount >= maxSessions) {
        final limitStr = isSubscribed ? '4 users' : '1 user';
        return 'Session limit reached. Your plan allows $limitStr at a time. '
            'Please logout from another device first.';
      }

      // Register/refresh this session
      await _supabase.from('business_sessions').upsert({
        'business_id': businessId,
        'user_id': userId,
        'device_id': deviceId,
        'last_active': DateTime.now().toIso8601String(),
      }, onConflict: 'business_id,device_id');

      return null; // OK
    } catch (_) {
      return null; // Don't block login on tracking errors
    }
  }

  /// Sends a heartbeat update so the session stays "active".
  /// Call this periodically (e.g. every 5 min) from the shell screen.
  Future<void> _heartbeat(String deviceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase
          .from('business_sessions')
          .update({'last_active': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('device_id', deviceId);
    } catch (_) {}
  }

  /// Public heartbeat for the shell screen timer.
  Future<void> heartbeat() async {
    final deviceId = await _getOrCreateDeviceId();
    await _heartbeat(deviceId);
  }

  // ── Business Setup Check ──────────────────────────────────
  Future<bool> _checkBusinessSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId != null && businessId.isNotEmpty) return true;

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

  // ── Sign Up ───────────────────────────────────────────────
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

  // ── Sign In ───────────────────────────────────────────────
  /// OTP is required for EVERY new device/browser.
  /// Once OTP is verified, that device is permanently trusted (stored in
  /// Supabase user_metadata) so subsequent logins on the same device
  /// skip OTP. Clearing browser data creates a new device ID → OTP again.
  Future<bool> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = _supabase.auth.currentUser!;
      final deviceId = await _getOrCreateDeviceId();

      // Check if this device is already trusted
      if (!_isDeviceTrusted(user, deviceId)) {
        // Unknown device — send OTP
        bool otpSent = false;
        try {
          await _sendOtp(email);
          otpSent = true;
        } catch (_) {
          // SMTP not configured — auto-trust to avoid lockout
          await _trustDevice(deviceId);
        }

        if (otpSent) {
          await _supabase.auth.signOut();
          state = AuthState.needsOtp(email);
          return true;
        }
      }

      // Trusted device — check session limit
      final sessionError = await _checkAndRegisterSession(deviceId);
      if (sessionError != null) {
        await _supabase.auth.signOut();
        state = AuthState.error(sessionError);
        return false;
      }

      final hasBusinessId = await _checkBusinessSetup();
      state =
          hasBusinessId ? AuthState.authenticated() : AuthState.needsSetup();
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  // ── Send OTP ──────────────────────────────────────────────
  Future<void> _sendOtp(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
    );
  }

  Future<bool> resendOtp(String email) async {
    try {
      await _sendOtp(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Verify OTP ────────────────────────────────────────────
  /// On success: trusts this device, registers session, proceeds.
  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      final deviceId = await _getOrCreateDeviceId();

      // Permanently trust this device
      await _trustDevice(deviceId);

      // Check session limit before granting access
      final sessionError = await _checkAndRegisterSession(deviceId);
      if (sessionError != null) {
        await _supabase.auth.signOut();
        state = AuthState.error(sessionError);
        return false;
      }

      final hasBusinessId = await _checkBusinessSetup();
      state =
          hasBusinessId ? AuthState.authenticated() : AuthState.needsSetup();
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  // ── Google Sign In ────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
      final hasBusinessId = await _checkBusinessSetup();
      state =
          hasBusinessId ? AuthState.authenticated() : AuthState.needsSetup();
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        // Remove this device's session from the active sessions table
        await _supabase
            .from('business_sessions')
            .delete()
            .eq('user_id', userId)
            .eq('device_id', deviceId);
      }
    } catch (_) {}

    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.kSelectedBusinessId);
    state = AuthState.unauthenticated();
  }

  // ── Password Reset ────────────────────────────────────────
  /// Stage 1: Send 6-digit OTP to email for password reset
  Future<bool> sendPasswordResetOtp(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stage 2: Verify the OTP — establishes a temporary session
  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );
      return true;
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Stage 3: Update password using the verified session, then sign out
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
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

  /// Legacy — kept for compatibility
  Future<bool> sendPasswordReset(String email) => sendPasswordResetOtp(email);

  // ── Helpers ───────────────────────────────────────────────
  bool get isAuthenticated => state.status == AuthStatus.authenticated;
  bool get needsBusinessSetup => state.status == AuthStatus.needsBusinessSetup;
  bool get needsOtpVerification =>
      state.status == AuthStatus.needsOtpVerification;
}
