import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Simple JSON-file local database — no code generation required.
/// Stores data as JSON files in the app's documents directory.
class LocalDbService {
  LocalDbService._();

  static final Map<String, List<Map<String, dynamic>>> _store = {};
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (kIsWeb) {
        _initialized = true;
        return; // Use in-memory only on web
      }
      // On mobile/desktop, hydrate from disk
      final dir = await getApplicationDocumentsDirectory();
      final tables = [
        'local_transactions',
        'local_parties',
        'local_products',
        'local_expenses',
        'local_sync_queue',
      ];
      for (final table in tables) {
        final file = File('${dir.path}/smart_saoji_$table.json');
        if (await file.exists()) {
          final raw = await file.readAsString();
          final List<dynamic> parsed = jsonDecode(raw) as List<dynamic>;
          _store[table] = parsed.cast<Map<String, dynamic>>();
        } else {
          _store[table] = [];
        }
      }
      _initialized = true;
    } catch (e) {
      debugPrint('LocalDbService init error: $e');
      _initialized = true;
    }
  }

  /// Get all records from a table
  static List<Map<String, dynamic>> getAll(String table) {
    return List.unmodifiable(_store[table] ?? []);
  }

  /// Insert a record into a table
  static Future<void> put(String table, Map<String, dynamic> record) async {
    _store.putIfAbsent(table, () => []);
    final idx = _store[table]!.indexWhere((r) => r['id'] == record['id']);
    if (idx >= 0) {
      _store[table]![idx] = record;
    } else {
      _store[table]!.add(record);
    }
    await _persist(table);
  }

  /// Delete a record from a table by id
  static Future<void> delete(String table, String id) async {
    _store[table]?.removeWhere((r) => r['id'] == id);
    await _persist(table);
  }

  /// Clear all records from a table
  static Future<void> clearTable(String table) async {
    _store[table] = [];
    await _persist(table);
  }

  /// Clear everything (sign-out)
  static Future<void> clearAll() async {
    for (final key in _store.keys) {
      _store[key] = [];
      await _persist(key);
    }
  }

  /// Query by field value
  static List<Map<String, dynamic>> where(
      String table, String field, dynamic value) {
    return (_store[table] ?? [])
        .where((r) => r[field] == value)
        .toList();
  }

  static Future<void> _persist(String table) async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/smart_saoji_$table.json');
      await file.writeAsString(jsonEncode(_store[table] ?? []));
    } catch (e) {
      debugPrint('LocalDbService persist error: $e');
    }
  }
}
