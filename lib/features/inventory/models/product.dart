class Product {
  final String? id;
  final String userId;
  final String name;
  final String? barcode;
  final String? category;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final int lowStockLimit;
  final DateTime? expiryDate;
  final String? imageUrl;
  final DateTime? createdAt;

  const Product({
    this.id,
    required this.userId,
    required this.name,
    this.barcode,
    this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    this.lowStockLimit = 5,
    this.expiryDate,
    this.imageUrl,
    this.createdAt,
  });

  bool get isLowStock => stockQuantity <= lowStockLimit;
  double get profitMargin => sellingPrice - costPrice;
  double get profitPercent =>
      costPrice > 0 ? (profitMargin / costPrice) * 100 : 0;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String?,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        barcode: json['barcode'] as String?,
        category: json['category'] as String?,
        costPrice: (json['cost_price'] as num).toDouble(),
        sellingPrice: (json['selling_price'] as num).toDouble(),
        stockQuantity: json['stock_quantity'] as int,
        lowStockLimit: (json['low_stock_limit'] as int?) ?? 5,
        expiryDate: json['expiry_date'] != null
            ? DateTime.parse(json['expiry_date'] as String)
            : null,
        imageUrl: json['image_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'name': name,
        'barcode': barcode,
        'category': category,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock_quantity': stockQuantity,
        'low_stock_limit': lowStockLimit,
        'expiry_date': expiryDate?.toIso8601String().split('T')[0],
        'image_url': imageUrl,
      };

  Product copyWith({
    String? name,
    String? barcode,
    String? category,
    double? costPrice,
    double? sellingPrice,
    int? stockQuantity,
    int? lowStockLimit,
    DateTime? expiryDate,
    String? imageUrl,
  }) =>
      Product(
        id: id,
        userId: userId,
        name: name ?? this.name,
        barcode: barcode ?? this.barcode,
        category: category ?? this.category,
        costPrice: costPrice ?? this.costPrice,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        lowStockLimit: lowStockLimit ?? this.lowStockLimit,
        expiryDate: expiryDate ?? this.expiryDate,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt,
      );
}
