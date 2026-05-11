class Party {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String type; // customer, supplier, both
  final double openingBalance;
  final double currentBalance;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Party({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.type,
    this.openingBalance = 0,
    this.currentBalance = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Party.fromJson(Map<String, dynamic> json) => Party(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        type: json['type'] as String? ?? 'customer',
        openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0,
        currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'type': type,
        'opening_balance': openingBalance,
        'current_balance': currentBalance,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Party copyWith({double? currentBalance}) => Party(
        id: id,
        businessId: businessId,
        name: name,
        phone: phone,
        email: email,
        address: address,
        type: type,
        openingBalance: openingBalance,
        currentBalance: currentBalance ?? this.currentBalance,
        notes: notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
