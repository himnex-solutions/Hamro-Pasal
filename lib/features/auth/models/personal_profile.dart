class PersonalProfile {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonalProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PersonalProfile.fromJson(Map<String, dynamic> json) => PersonalProfile(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      };

  PersonalProfile copyWith({
    String? fullName,
    String? phone,
    String? email,
  }) =>
      PersonalProfile(
        id: id,
        userId: userId,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
