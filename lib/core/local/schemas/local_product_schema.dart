/// Simple data class for a local product cache entry.
class LocalProduct {
  final String id;
  final String remoteId;
  final String businessId;
  final String name;
  final double sellingPrice;
  final double costPrice;
  final double stockQuantity;
  final double minStockAlert;
  final String? sku;
  final String? unit;
  final String? imageUrl;
  final bool isActive;
  final DateTime updatedAt;
  final bool isDirty;

  const LocalProduct({
    required this.id,
    required this.remoteId,
    required this.businessId,
    required this.name,
    required this.sellingPrice,
    required this.costPrice,
    required this.stockQuantity,
    required this.minStockAlert,
    this.sku,
    this.unit,
    this.imageUrl,
    this.isActive = true,
    required this.updatedAt,
    this.isDirty = false,
  });

  factory LocalProduct.fromJson(Map<String, dynamic> json) => LocalProduct(
        id: json['id'] as String,
        remoteId: json['remote_id'] as String? ?? json['id'] as String,
        businessId: json['business_id'] as String,
        name: json['name'] as String,
        sellingPrice: (json['selling_price'] as num).toDouble(),
        costPrice: (json['cost_price'] as num).toDouble(),
        stockQuantity: (json['stock_quantity'] as num).toDouble(),
        minStockAlert: (json['min_stock_alert'] as num? ?? 0).toDouble(),
        sku: json['sku'] as String?,
        unit: json['unit'] as String?,
        imageUrl: json['image_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isDirty: json['is_dirty'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'remote_id': remoteId,
        'business_id': businessId,
        'name': name,
        'selling_price': sellingPrice,
        'cost_price': costPrice,
        'stock_quantity': stockQuantity,
        'min_stock_alert': minStockAlert,
        'sku': sku,
        'unit': unit,
        'image_url': imageUrl,
        'is_active': isActive,
        'updated_at': updatedAt.toIso8601String(),
        'is_dirty': isDirty,
      };
}
