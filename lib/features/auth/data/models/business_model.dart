class Business {
  final String id;
  final String ownerId;
  final String name;
  final String? type;
  final String? address;
  final String? phone;
  final String? email;
  final String? panNumber;
  final String? logoUrl;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    this.type,
    this.address,
    this.phone,
    this.email,
    this.panNumber,
    this.logoUrl,
    this.currency = 'NPR',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        name: json['name'] as String,
        type: json['type'] as String?,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        panNumber: json['pan_number'] as String?,
        logoUrl: json['logo_url'] as String?,
        currency: json['currency'] as String? ?? 'NPR',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
        'type': type,
        'address': address,
        'phone': phone,
        'email': email,
        'pan_number': panNumber,
        'logo_url': logoUrl,
        'currency': currency,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
