class UserProfile {
  final String id;
  final String userId;
  final String pasalName;
  final String? panNumber;
  final String phone;
  final String address;
  final String? logoUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.pasalName,
    this.panNumber,
    required this.phone,
    required this.address,
    this.logoUrl,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        pasalName: json['pasal_name'] as String,
        panNumber: json['pan_number'] as String?,
        phone: json['phone'] as String,
        address: json['address'] as String,
        logoUrl: json['logo_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'pasal_name': pasalName,
        'pan_number': panNumber,
        'phone': phone,
        'address': address,
        'logo_url': logoUrl,
      };

  UserProfile copyWith({
    String? pasalName,
    String? panNumber,
    String? phone,
    String? address,
    String? logoUrl,
  }) =>
      UserProfile(
        id: id,
        userId: userId,
        pasalName: pasalName ?? this.pasalName,
        panNumber: panNumber ?? this.panNumber,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        logoUrl: logoUrl ?? this.logoUrl,
        createdAt: createdAt,
      );
}
