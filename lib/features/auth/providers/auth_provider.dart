import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../models/user_profile.dart';

// ─── Auth State Provider ──────────────────────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.instance.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseService.instance.currentUser;
});

// ─── Profile Provider ─────────────────────────────────────────────────────────

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  // Watch auth state so profile reloads on login/logout automatically
  ref.watch(authStateProvider);
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  // Start as data(null) — avoids a loading spinner on cold start
  ProfileNotifier() : super(const AsyncValue.data(null)) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    // Show loading only when we actually have a user to fetch for
    state = const AsyncValue.loading();
    try {
      final json = await SupabaseService.instance.getProfile(userId);
      state = AsyncValue.data(
          json != null ? UserProfile.fromJson(json) : null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    try {
      await SupabaseService.instance.upsertProfile(profile.toJson());
      // Reload from DB to get the server-assigned id/timestamps
      await loadProfile();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

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
      _ref.invalidate(profileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.instance.signInWithGoogle();
      _ref.invalidate(profileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await SupabaseService.instance.signOut();
    _ref.invalidate(profileProvider);
  }
}
