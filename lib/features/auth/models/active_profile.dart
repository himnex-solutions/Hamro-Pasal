class ActiveProfile {
  final String id;
  final String userId;
  final String activeProfileId;
  final String activeProfileType; // 'business' or 'personal'
  final DateTime updatedAt;

  const ActiveProfile({
    required this.id,
    required this.userId,
    required this.activeProfileId,
    required this.activeProfileType,
    required this.updatedAt,
  });

  factory ActiveProfile.fromJson(Map<String, dynamic> json) => ActiveProfile(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        activeProfileId: json['active_profile_id'] as String,
        activeProfileType: json['active_profile_type'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'active_profile_id': activeProfileId,
        'active_profile_type': activeProfileType,
        'updated_at': DateTime.now().toIso8601String(),
      };

  ActiveProfile copyWith({
    String? activeProfileId,
    String? activeProfileType,
  }) =>
      ActiveProfile(
        id: id,
        userId: userId,
        activeProfileId: activeProfileId ?? this.activeProfileId,
        activeProfileType: activeProfileType ?? this.activeProfileType,
        updatedAt: DateTime.now(),
      );
}
