import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import 'profile_provider.dart';

// ─── Auth State Provider ──────────────────────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.instance.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseService.instance.currentUser;
});

// ─── Auth Notifier ────────────────────────────────────────────────────────────

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.instance
          .signUp(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.instance
          .signInWithPassword(email: email, password: password);
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(activeProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithOtp({
    required String email,
  }) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.instance.signInWithOtp(email: email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.instance.verifyOtp(email: email, token: token);
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(activeProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Send OTP for email verification after first login
  Future<void> sendVerificationOtp({
    required String email,
  }) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.instance.sendVerificationOtp(email: email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Verify the email OTP code for email verification
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.instance.verifyEmailOtp(email: email, token: token);
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(activeProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.instance.signInWithGoogle();
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(activeProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await SupabaseService.instance.signOut();
    _ref.invalidate(userProfileProvider);
    _ref.invalidate(activeProfileProvider);
  }
}
