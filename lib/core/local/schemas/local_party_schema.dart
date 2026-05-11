/// Simple data class replacing the old Isar LocalParty schema.
class LocalParty {
  final String id;
  final String remoteId;
  final String businessId;
  final String name;
  final String type;
  final double currentBalance;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDirty;
  final bool isPendingDelete;

  const LocalParty({
    required this.id,
    required this.remoteId,
    required this.businessId,
    required this.name,
    required this.type,
    required this.currentBalance,
    this.phone,
    this.email,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    this.isDirty = false,
    this.isPendingDelete = false,
  });

  factory LocalParty.fromJson(Map<String, dynamic> json) => LocalParty(
        id: json['id'] as String,
        remoteId: json['remote_id'] as String? ?? json['id'] as String,
        businessId: json['business_id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        currentBalance: (json['current_balance'] as num).toDouble(),
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isDirty: json['is_dirty'] as bool? ?? false,
        isPendingDelete: json['is_pending_delete'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'remote_id': remoteId,
        'business_id': businessId,
        'name': name,
        'type': type,
        'current_balance': currentBalance,
        'phone': phone,
        'email': email,
        'address': address,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_dirty': isDirty,
        'is_pending_delete': isPendingDelete,
      };
}
