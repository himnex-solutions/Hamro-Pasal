/// Plain Dart data class replacing the old Isar LocalSyncQueue schema.
/// Used by LocalDbService for offline sync queue storage.
class LocalSyncQueue {
  final String id;
  final String entityType;
  final String operation; // create | update | delete
  final Map<String, dynamic> payload;
  String status; // pending | syncing | synced | failed
  int retryCount;
  String? errorMessage;
  final DateTime createdAt;
  DateTime? syncedAt;

  LocalSyncQueue({
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

  factory LocalSyncQueue.fromJson(Map<String, dynamic> json) => LocalSyncQueue(
        id: json['id'] as String,
        entityType: json['entity_type'] as String,
        operation: json['operation'] as String,
        payload: json['payload'] as Map<String, dynamic>? ?? {},
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
