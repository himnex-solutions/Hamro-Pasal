import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../models/user_profile.dart';
import '../models/business_profile.dart';
import '../models/personal_profile.dart';
import '../models/active_profile.dart';
import 'auth_provider.dart';

// ─── User Profile Provider ───────────────────────────────────────────────────

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  ref.watch(authStateProvider);
  return UserProfileNotifier();
});

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  UserProfileNotifier() : super(const AsyncValue.data(null)) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final json = await SupabaseService.instance.getUserProfile(userId);
      state = AsyncValue.data(
          json != null ? UserProfile.fromJson(json) : null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    try {
      await SupabaseService.instance.upsertUserProfile(profile.toJson());
      await loadProfile();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─── Business Profile Provider ───────────────────────────────────────────────

final businessProfileProvider =
    StateNotifierProvider<BusinessProfileNotifier, AsyncValue<BusinessProfile?>>((ref) {
  ref.watch(authStateProvider);
  return BusinessProfileNotifier();
});

class BusinessProfileNotifier extends StateNotifier<AsyncValue<BusinessProfile?>> {
  BusinessProfileNotifier() : super(const AsyncValue.data(null)) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final json = await SupabaseService.instance.getBusinessProfile(userId);
      state = AsyncValue.data(
          json != null ? BusinessProfile.fromJson(json) : null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(BusinessProfile profile) async {
    try {
      await SupabaseService.instance.upsertBusinessProfile(profile.toJson());
      await loadProfile();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─── Personal Profile Provider ───────────────────────────────────────────────

final personalProfileProvider =
    StateNotifierProvider<PersonalProfileNotifier, AsyncValue<PersonalProfile?>>((ref) {
  ref.watch(authStateProvider);
  return PersonalProfileNotifier();
});

class PersonalProfileNotifier extends StateNotifier<AsyncValue<PersonalProfile?>> {
  PersonalProfileNotifier() : super(const AsyncValue.data(null)) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final json = await SupabaseService.instance.getPersonalProfile(userId);
      state = AsyncValue.data(
          json != null ? PersonalProfile.fromJson(json) : null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(PersonalProfile profile) async {
    try {
      await SupabaseService.instance.upsertPersonalProfile(profile.toJson());
      await loadProfile();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─── Active Profile Provider ─────────────────────────────────────────────────

final activeProfileProvider =
    StateNotifierProvider<ActiveProfileNotifier, AsyncValue<ActiveProfile?>>((ref) {
  ref.watch(authStateProvider);
  return ActiveProfileNotifier();
});

class ActiveProfileNotifier extends StateNotifier<AsyncValue<ActiveProfile?>> {
  ActiveProfileNotifier() : super(const AsyncValue.data(null)) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final json = await SupabaseService.instance.getActiveProfile(userId);
      state = AsyncValue.data(
          json != null ? ActiveProfile.fromJson(json) : null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(ActiveProfile profile) async {
    try {
      await SupabaseService.instance.upsertActiveProfile(profile.toJson());
      await loadProfile();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
