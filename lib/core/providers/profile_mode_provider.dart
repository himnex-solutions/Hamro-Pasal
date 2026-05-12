import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Profile Mode Enum ────────────────────────────────────────
enum ProfileMode { personal, business }

// ── Prefs Key ────────────────────────────────────────────────
const _kProfileMode = 'profile_mode';

// ── Provider ─────────────────────────────────────────────────
final profileModeProvider =
    StateNotifierProvider<ProfileModeNotifier, ProfileMode>((ref) {
  return ProfileModeNotifier();
});

class ProfileModeNotifier extends StateNotifier<ProfileMode> {
  ProfileModeNotifier() : super(ProfileMode.business) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kProfileMode);
    state = saved == 'personal' ? ProfileMode.personal : ProfileMode.business;
  }

  Future<void> switchTo(ProfileMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileMode, mode.name);
  }

  void toggle() {
    switchTo(state == ProfileMode.business
        ? ProfileMode.personal
        : ProfileMode.business);
  }

  bool get isBusiness => state == ProfileMode.business;
  bool get isPersonal => state == ProfileMode.personal;
}
