import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_saoji/core/services/local_db_service.dart';
import 'package:smart_saoji/core/services/notification_service.dart';

// ── Connectivity Provider ─────────────────────────────────────
enum ConnectivityStatus { online, offline }

final connectivityProvider =
    StreamProvider<ConnectivityStatus>((ref) async* {
  final connectivity = Connectivity();
  final initialList = await connectivity.checkConnectivity();
  yield (initialList.length == 1 && initialList.first == ConnectivityResult.none)
      ? ConnectivityStatus.offline
      : ConnectivityStatus.online;
  yield* connectivity.onConnectivityChanged.map((results) =>
      (results.isEmpty || (results.length == 1 && results.first == ConnectivityResult.none))
          ? ConnectivityStatus.offline
          : ConnectivityStatus.online);
});

// ── Sync Service Provider ─────────────────────────────────────
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

// ── Sync Queue Entry ──────────────────────────────────────────
class SyncQueueEntry {
  final String id;
  final String entityType;
  final String operation; // create | update | delete
  final Map<String, dynamic> payload;
  String status; // pending | syncing | synced | failed
  int retryCount;
  String? errorMessage;
  final DateTime createdAt;
  DateTime? syncedAt;

  SyncQueueEntry({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.payload,
    this.status = 'pending',
    this.retryCount = 0,
    this.errorMessage,
    required this.createdAt,
    this.syncedAt,
  });

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) => SyncQueueEntry(
        id: json['id'] as String,
        entityType: json['entity_type'] as String,
        operation: json['operation'] as String,
        payload: json['payload'] as Map<String, dynamic>,
        status: json['status'] as String? ?? 'pending',
        retryCount: json['retry_count'] as int? ?? 0,
        errorMessage: json['error_message'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        syncedAt: json['synced_at'] != null
            ? DateTime.parse(json['synced_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'entity_type': entityType,
        'operation': operation,
        'payload': payload,
        'status': status,
        'retry_count': retryCount,
        'error_message': errorMessage,
        'created_at': createdAt.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
      };
}

// ── SyncService ───────────────────────────────────────────────
class SyncService {
  static const _table = 'local_sync_queue';

  SyncService() {
    _listenConnectivity();
  }

  void _listenConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = !(results.isEmpty ||
          (results.length == 1 && results.first == ConnectivityResult.none));
      if (isOnline) syncAll();
    });
  }

  /// Add an operation to the local sync queue
  Future<void> enqueue({
    required String entityType,
    required String operation,
    required String localId,
    required Map<String, dynamic> payload,
  }) async {
    final entry = SyncQueueEntry(
      id: localId,
      entityType: entityType,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await LocalDbService.put(_table, entry.toJson());
  }

  /// Process all pending sync queue items
  Future<void> syncAll() async {
    final all = LocalDbService.getAll(_table);
    final pending = all
        .where((e) => e['status'] == 'pending' || e['status'] == 'failed')
        .map((e) => SyncQueueEntry.fromJson(e))
        .toList();

    if (pending.isEmpty) return;

    final supabase = Supabase.instance.client;
    int failCount = 0;

    for (final item in pending) {
      try {
        // Mark as syncing
        item.status = 'syncing';
        await LocalDbService.put(_table, item.toJson());

        switch (item.operation) {
          case 'create':
            await supabase.from(item.entityType).insert(item.payload);
            break;
          case 'update':
            await supabase
                .from(item.entityType)
                .update(item.payload)
                .eq('id', item.payload['id']);
            break;
          case 'delete':
            await supabase
                .from(item.entityType)
                .delete()
                .eq('id', item.payload['id']);
            break;
        }

        // Mark as synced
        item.status = 'synced';
        item.syncedAt = DateTime.now();
        await LocalDbService.put(_table, item.toJson());
      } catch (e) {
        failCount++;
        item.status = 'failed';
        item.retryCount++;
        item.errorMessage = e.toString();
        await LocalDbService.put(_table, item.toJson());
      }
    }

    if (failCount > 0) {
      await NotificationService.showSyncFailedAlert();
    }
  }

  /// Get count of pending sync items
  int getPendingCount() {
    return LocalDbService.where(_table, 'status', 'pending').length;
  }
}
