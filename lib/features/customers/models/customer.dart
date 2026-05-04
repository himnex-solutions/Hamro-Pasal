class Customer {
  final String? id;
  final String userId;
  final String name;
  final String? phone;
  final String? address;
  final double totalDue;
  final DateTime? createdAt;

  const Customer({
    this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.address,
    this.totalDue = 0.0,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String?,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        totalDue: (json['total_due'] as num?)?.toDouble() ?? 0.0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'address': address,
        'total_due': totalDue,
      };

  Customer copyWith({
    String? name,
    String? phone,
    String? address,
    double? totalDue,
  }) =>
      Customer(
        id: id,
        userId: userId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        totalDue: totalDue ?? this.totalDue,
        createdAt: createdAt,
      );
}

// ─── Ledger Transaction ───────────────────────────────────────────────────────
enum LedgerType { credit, payment }

class LedgerTransaction {
  final String? id;
  final String userId;
  final String customerId;
  final LedgerType type;
  final double amount;
  final String? note;
  final String adDate;
  final String? bsDate;
  final DateTime? createdAt;

  const LedgerTransaction({
    this.id,
    required this.userId,
    required this.customerId,
    required this.type,
    required this.amount,
    this.note,
    required this.adDate,
    this.bsDate,
    this.createdAt,
  });

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) =>
      LedgerTransaction(
        id: json['id'] as String?,
        userId: json['user_id'] as String,
        customerId: json['customer_id'] as String,
        type: json['type'] == 'credit' ? LedgerType.credit : LedgerType.payment,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String?,
        adDate: json['ad_date'] as String,
        bsDate: json['bs_date'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'customer_id': customerId,
        'type': type.name,
        'amount': amount,
        'note': note,
        'ad_date': adDate,
        'bs_date': bsDate,
      };
}
