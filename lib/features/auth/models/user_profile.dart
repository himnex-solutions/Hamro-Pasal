class UserProfile {
  final String id;
  final String userId;
  final String profileType; // 'business', 'personal', 'both'
  final String? fullName;
  final String? email;
  final String? phone;
  final bool isFirstLogin;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.profileType,
    this.fullName,
    this.email,
    this.phone,
    this.isFirstLogin = true,
    this.emailVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        profileType: json['profile_type'] as String,
        fullName: json['full_name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        isFirstLogin: json['is_first_login'] as bool? ?? true,
        emailVerified: json['email_verified'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'profile_type': profileType,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'is_first_login': isFirstLogin,
        'email_verified': emailVerified,
        'updated_at': DateTime.now().toIso8601String(),
      };

  UserProfile copyWith({
    String? profileType,
    String? fullName,
    String? email,
    String? phone,
    bool? isFirstLogin,
    bool? emailVerified,
  }) =>
      UserProfile(
        id: id,
        userId: userId,
        profileType: profileType ?? this.profileType,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        isFirstLogin: isFirstLogin ?? this.isFirstLogin,
        emailVerified: emailVerified ?? this.emailVerified,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
