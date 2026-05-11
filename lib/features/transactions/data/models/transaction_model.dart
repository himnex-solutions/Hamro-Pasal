// transaction_model.dart — no external model imports needed

class Transaction {
  final String id;
  final String businessId;
  final String type;
  final String paymentMethod;
  final double amount;
  final double paidAmount;
  final double dueAmount;
  final String? partyId;
  final String? partyName;
  final String? accountId;
  final String? note;
  final String? receiptImageUrl;
  final DateTime transactionDate;
  final DateTime createdAt;
  final String? createdBy;
  final List<TransactionItem> items;

  const Transaction({
    required this.id,
    required this.businessId,
    required this.type,
    required this.paymentMethod,
    required this.amount,
    required this.paidAmount,
    required this.dueAmount,
    this.partyId,
    this.partyName,
    this.accountId,
    this.note,
    this.receiptImageUrl,
    required this.transactionDate,
    required this.createdAt,
    this.createdBy,
    this.items = const [],
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      type: json['type'] as String,
      paymentMethod: json['payment_method'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      dueAmount: (json['due_amount'] as num?)?.toDouble() ?? 0,
      partyId: json['party_id'] as String?,
      partyName: json['party_name'] as String?,
      accountId: json['account_id'] as String?,
      note: json['note'] as String?,
      receiptImageUrl: json['receipt_image_url'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
      items: (json['transaction_items'] as List<dynamic>?)
              ?.map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'type': type,
        'payment_method': paymentMethod,
        'amount': amount,
        'paid_amount': paidAmount,
        'due_amount': dueAmount,
        'party_id': partyId,
        'account_id': accountId,
        'note': note,
        'receipt_image_url': receiptImageUrl,
        'transaction_date': transactionDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'created_by': createdBy,
      };
}

class TransactionItem {
  final String id;
  final String transactionId;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double totalPrice;

  const TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    required this.totalPrice,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_id': transactionId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'discount': discount,
        'total_price': totalPrice,
      };
}
