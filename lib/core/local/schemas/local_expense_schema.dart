/// Simple data class replacing the old Isar LocalExpense schema.
class LocalExpense {
  final String id;
  final String remoteId;
  final String businessId;
  final String categoryName;
  final double amount;
  final String? note;
  final DateTime expenseDate;
  final DateTime createdAt;
  final bool isDirty;
  final bool isPendingDelete;

  const LocalExpense({
    required this.id,
    required this.remoteId,
    required this.businessId,
    required this.categoryName,
    required this.amount,
    this.note,
    required this.expenseDate,
    required this.createdAt,
    this.isDirty = false,
    this.isPendingDelete = false,
  });

  factory LocalExpense.fromJson(Map<String, dynamic> json) => LocalExpense(
        id: json['id'] as String,
        remoteId: json['remote_id'] as String? ?? json['id'] as String,
        businessId: json['business_id'] as String,
        categoryName: json['category_name'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String?,
        expenseDate: DateTime.parse(json['expense_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        isDirty: json['is_dirty'] as bool? ?? false,
        isPendingDelete: json['is_pending_delete'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'remote_id': remoteId,
        'business_id': businessId,
        'category_name': categoryName,
        'amount': amount,
        'note': note,
        'expense_date': expenseDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'is_dirty': isDirty,
        'is_pending_delete': isPendingDelete,
      };
}
