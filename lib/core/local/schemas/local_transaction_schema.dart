/// Simple data class replacing the old Isar LocalTransaction schema.
/// No code generation required.
class LocalTransaction {
  final String id;
  final String remoteId;
  final String businessId;
  final String type;
  final String paymentMethod;
  final double amount;
  final double paidAmount;
  final double dueAmount;
  final String? partyId;
  final String? partyName;
  final String? note;
  final DateTime transactionDate;
  final DateTime createdAt;
  final bool isDirty;
  final bool isPendingDelete;

  const LocalTransaction({
    required this.id,
    required this.remoteId,
    required this.businessId,
    required this.type,
    required this.paymentMethod,
    required this.amount,
    required this.paidAmount,
    required this.dueAmount,
    this.partyId,
    this.partyName,
    this.note,
    required this.transactionDate,
    required this.createdAt,
    this.isDirty = false,
    this.isPendingDelete = false,
  });

  factory LocalTransaction.fromJson(Map<String, dynamic> json) =>
      LocalTransaction(
        id: json['id'] as String,
        remoteId: json['remote_id'] as String? ?? json['id'] as String,
        businessId: json['business_id'] as String,
        type: json['type'] as String,
        paymentMethod: json['payment_method'] as String,
        amount: (json['amount'] as num).toDouble(),
        paidAmount: (json['paid_amount'] as num).toDouble(),
        dueAmount: (json['due_amount'] as num).toDouble(),
        partyId: json['party_id'] as String?,
        partyName: json['party_name'] as String?,
        note: json['note'] as String?,
        transactionDate: DateTime.parse(json['transaction_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        isDirty: json['is_dirty'] as bool? ?? false,
        isPendingDelete: json['is_pending_delete'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'remote_id': remoteId,
        'business_id': businessId,
        'type': type,
        'payment_method': paymentMethod,
        'amount': amount,
        'paid_amount': paidAmount,
        'due_amount': dueAmount,
        'party_id': partyId,
        'party_name': partyName,
        'note': note,
        'transaction_date': transactionDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'is_dirty': isDirty,
        'is_pending_delete': isPendingDelete,
      };
}
