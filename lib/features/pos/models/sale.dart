import '../../inventory/models/product.dart';

class SaleItem {
  final String? id;
  final String? saleId;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double total;

  const SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory SaleItem.fromProduct(Product p, int qty) => SaleItem(
        productId: p.id!,
        productName: p.name,
        quantity: qty,
        price: p.sellingPrice,
        total: p.sellingPrice * qty,
      );

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        id: json['id'] as String?,
        saleId: json['sale_id'] as String?,
        productId: json['product_id'] as String,
        productName: json['product_name'] as String,
        quantity: json['quantity'] as int,
        price: (json['price'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (saleId != null) 'sale_id': saleId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'price': price,
        'total': total,
      };

  SaleItem copyWith({int? quantity}) {
    final qty = quantity ?? this.quantity;
    return SaleItem(
      id: id,
      saleId: saleId,
      productId: productId,
      productName: productName,
      quantity: qty,
      price: price,
      total: price * qty,
    );
  }
}

enum PaymentStatus { paid, credit, partial }
enum PaymentMethod { cash, khalti, esewa, credit, qr }

class Sale {
  final String? id;
  final String userId;
  final String? customerId;
  final String billNumber;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String adDate;
  final String? bsDate;
  final DateTime? createdAt;

  const Sale({
    this.id,
    required this.userId,
    this.customerId,
    required this.billNumber,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.total,
    this.paymentStatus = PaymentStatus.paid,
    this.paymentMethod = PaymentMethod.cash,
    required this.adDate,
    this.bsDate,
    this.createdAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String?,
        userId: json['user_id'] as String,
        customerId: json['customer_id'] as String?,
        billNumber: json['bill_number'] as String,
        items: (json['sale_items'] as List<dynamic>?)
                ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        subtotal: (json['subtotal'] as num).toDouble(),
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num).toDouble(),
        paymentStatus: PaymentStatus.values.firstWhere(
            (e) => e.name == json['payment_status'],
            orElse: () => PaymentStatus.paid),
        paymentMethod: PaymentMethod.values.firstWhere(
            (e) => e.name == json['payment_method'],
            orElse: () => PaymentMethod.cash),
        adDate: json['ad_date'] as String,
        bsDate: json['bs_date'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'customer_id': customerId,
        'bill_number': billNumber,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'payment_status': paymentStatus.name,
        'payment_method': paymentMethod.name,
        'ad_date': adDate,
        'bs_date': bsDate,
      };
}
