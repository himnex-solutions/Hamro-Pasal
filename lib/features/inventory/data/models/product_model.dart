class Product {
  final String id;
  final String businessId;
  final String? categoryId;
  final String name;
  final String? sku;
  final String? barcode;
  final String? unit;
  final double costPrice;
  final double sellingPrice;
  final double stockQuantity;
  final double minStockAlert;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.businessId,
    this.categoryId,
    required this.name,
    this.sku,
    this.barcode,
    this.unit,
    this.costPrice = 0,
    required this.sellingPrice,
    this.stockQuantity = 0,
    this.minStockAlert = 5,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        categoryId: json['category_id'] as String?,
        name: json['name'] as String,
        sku: json['sku'] as String?,
        barcode: json['barcode'] as String?,
        unit: json['unit'] as String?,
        costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0,
        sellingPrice: (json['selling_price'] as num).toDouble(),
        stockQuantity: (json['stock_quantity'] as num?)?.toDouble() ?? 0,
        minStockAlert: (json['min_stock_alert'] as num?)?.toDouble() ?? 5,
        imageUrl: json['image_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'category_id': categoryId,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'unit': unit,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock_quantity': stockQuantity,
        'min_stock_alert': minStockAlert,
        'image_url': imageUrl,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  bool get isLowStock => stockQuantity <= minStockAlert;
  double get profitMargin =>
      sellingPrice > 0 ? ((sellingPrice - costPrice) / sellingPrice) * 100 : 0;
  double get inventoryValue => costPrice * stockQuantity;
}

class ProductUnit {
  static const List<String> all = [
    'Piece',
    'Dozen',
    'Box',
    'Kg',
    'Gram',
    'Liter',
    'ML',
    'Meter',
    'Feet',
    'Bag',
    'Bundle',
    'Pack',
    'Bottle',
    'Carton',
    'Roll',
  ];
}
