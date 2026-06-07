import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks and enforces daily usage limits per subscription plan.
/// Limits are stored locally in SharedPreferences with date-based keys
/// so they reset automatically each new day.
///
/// Gold plan limits:
///   - parties       : 10 / day
///   - transactions  : 50 / day
///   - expenses      : 50 / day
///   - products      : 20 / day
///
/// Diamond plan: unlimited (always returns allowed)
/// Basic plan  : no restriction from this service (handled by SubscriptionManager)
class DailyLimitService {
  DailyLimitService._();
  static final instance = DailyLimitService._();

  // ── Plan limits map ────────────────────────────────────────
  static const Map<String, Map<String, int>> _planLimits = {
    'basic': {
      'parties': 5,
      'transactions': 10,
      'expenses': 10,
      'products': 5,
    },
    'gold': {
      'parties': 10,
      'transactions': 50,
      'expenses': 50,
      'products': 20,
      'thermal_print': 10,
    },
    // diamond = unlimited → not in map → always allowed
  };

  // ── Key helpers ────────────────────────────────────────────
  String _todayStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  String _prefKey(String planCode, String action) =>
      'daily_limit_${planCode}_${action}_${_todayStr()}';

  // ── Public API ─────────────────────────────────────────────

  /// Returns the daily limit for [action] on [planCode].
  /// Returns null if unlimited.
  int? getLimit(String planCode, String action) {
    return _planLimits[planCode]?[action];
  }

  /// Returns how many times [action] has been done today for [planCode].
  Future<int> getTodayCount(String planCode, String action) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKey(planCode, action)) ?? 0;
  }

  /// Returns a [LimitCheckResult] — whether the action is allowed and
  /// how many uses remain.
  Future<LimitCheckResult> checkLimit(String planCode, String action) async {
    // Diamond (and any unknown plan) = unlimited
    final limit = getLimit(planCode, action);
    if (limit == null) {
      return const LimitCheckResult(allowed: true, used: 0, limit: null);
    }

    final used = await getTodayCount(planCode, action);
    return LimitCheckResult(
      allowed: used < limit,
      used: used,
      limit: limit,
    );
  }

  /// Increments the counter for [action] today. Call this AFTER a
  /// successful insert.
  Future<void> increment(String planCode, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefKey(planCode, action);
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  /// Returns a human-readable label for an action.
  static String actionLabel(String action) {
    switch (action) {
      case 'parties':
        return 'parties';
      case 'transactions':
        return 'transactions';
      case 'expenses':
        return 'expenses';
      case 'products':
        return 'products';
      case 'thermal_print':
        return 'thermal prints';
      default:
        return action;
    }
  }
}

class LimitCheckResult {
  final bool allowed;
  final int used;
  final int? limit; // null = unlimited

  const LimitCheckResult({
    required this.allowed,
    required this.used,
    required this.limit,
  });

  int get remaining => limit == null ? 999999 : (limit! - used).clamp(0, limit!);
}
