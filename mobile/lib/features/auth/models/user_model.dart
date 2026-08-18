class UserModel {
  final String id;
  final String name;
  final String email;
  final String? picture;
  final String role;
  final bool isActive;
  final String registrationNumber;
  final String neoPatId;
  final String customAiPrompt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? notificationPreferences;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.picture,
    required this.role,
    required this.isActive,
    this.registrationNumber = '',
    this.neoPatId = '',
    this.customAiPrompt = 'Summarize email highlighting placement action items, test links, shortlist status, deadlines, and mandatory next steps.',
    this.lastLoginAt,
    this.notificationPreferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      picture: json['picture'] as String?,
      role: json['role'] as String? ?? 'user',
      isActive: json['isActive'] as bool? ?? true,
      registrationNumber: json['registrationNumber'] as String? ?? '',
      neoPatId: json['neoPatId'] as String? ?? '',
      customAiPrompt: json['customAiPrompt'] as String? ?? 'Summarize email highlighting placement action items, test links, shortlist status, deadlines, and mandatory next steps.',
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'] as String)
          : null,
      notificationPreferences: json['notificationPreferences'] as Map<String, dynamic>?,
    );
  }

  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? name,
    String? picture,
    String? registrationNumber,
    String? neoPatId,
    String? customAiPrompt,
    Map<String, dynamic>? notificationPreferences,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      picture: picture ?? this.picture,
      role: role,
      isActive: isActive,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      neoPatId: neoPatId ?? this.neoPatId,
      customAiPrompt: customAiPrompt ?? this.customAiPrompt,
      lastLoginAt: lastLoginAt,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }
}

