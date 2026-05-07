class BusinessProfile {
  final String id;
  final String userId;
  final String businessName;
  final String? ownerName;
  final String? businessCategory;
  final String? panVatNumber;
  final String? businessAddress;
  final String? companyLogoUrl;
  final String? phone;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    this.ownerName,
    this.businessCategory,
    this.panVatNumber,
    this.businessAddress,
    this.companyLogoUrl,
    this.phone,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        businessName: json['business_name'] as String,
        ownerName: json['owner_name'] as String?,
        businessCategory: json['business_category'] as String?,
        panVatNumber: json['pan_vat_number'] as String?,
        businessAddress: json['business_address'] as String?,
        companyLogoUrl: json['company_logo_url'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'business_name': businessName,
        'owner_name': ownerName,
        'business_category': businessCategory,
        'pan_vat_number': panVatNumber,
        'business_address': businessAddress,
        'company_logo_url': companyLogoUrl,
        'phone': phone,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      };

  BusinessProfile copyWith({
    String? businessName,
    String? ownerName,
    String? businessCategory,
    String? panVatNumber,
    String? businessAddress,
    String? companyLogoUrl,
    String? phone,
    String? email,
  }) =>
      BusinessProfile(
        id: id,
        userId: userId,
        businessName: businessName ?? this.businessName,
        ownerName: ownerName ?? this.ownerName,
        businessCategory: businessCategory ?? this.businessCategory,
        panVatNumber: panVatNumber ?? this.panVatNumber,
        businessAddress: businessAddress ?? this.businessAddress,
        companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
