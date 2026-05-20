import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  AppLockService._();
  
  static const String _kAppLockEnabledKey = 'app_lock_enabled';
  static const String _kAppLockPinKey = 'app_lock_pin';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAppLockEnabledKey) ?? false;
  }

  static Future<bool> enableLock(String pin) async {
    if (pin.length != 4) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppLockPinKey, pin);
    await prefs.setBool(_kAppLockEnabledKey, true);
    return true;
  }

  static Future<void> disableLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAppLockPinKey);
    await prefs.setBool(_kAppLockEnabledKey, false);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_kAppLockPinKey);
    return savedPin == pin;
  }
}
