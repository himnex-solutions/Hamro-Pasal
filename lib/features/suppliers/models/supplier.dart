class Supplier {
  final String? id;
  final String userId;
  final String name;
  final String? phone;
  final String? address;
  final double totalDue;
  final DateTime? createdAt;

  const Supplier({
    this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.address,
    this.totalDue = 0.0,
    this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
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
}
