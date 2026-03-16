class UserModel {
  final String id;
  final String firstName;
  final int age;
  final String gender;
  final String interestedIn; // 'Men' | 'Women' | 'Everyone'
  final String bio;
  final List<String> photos;

  // Verification — stored privately, never shown publicly
  final String companyDomain;
  final bool workVerified;

  // What's optionally displayed on profile (user's choice)
  final String industryCategory; // e.g. "Technology", "Finance"
  final String role;             // e.g. "Software Engineer"
  final bool showIndustry;
  final bool showRole;

  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.age,
    required this.gender,
    this.interestedIn = 'Everyone',
    required this.bio,
    required this.photos,
    required this.companyDomain,
    required this.workVerified,
    required this.industryCategory,
    required this.role,
    required this.showIndustry,
    required this.showRole,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'age': age,
      'gender': gender,
      'interestedIn': interestedIn,
      'bio': bio,
      'photos': photos,
      'companyDomain': companyDomain,
      'workVerified': workVerified,
      'industryCategory': industryCategory,
      'role': role,
      'showIndustry': showIndustry,
      'showRole': showRole,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      firstName: map['firstName'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      interestedIn: map['interestedIn'] ?? 'Everyone',
      bio: map['bio'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      companyDomain: map['companyDomain'] ?? '',
      workVerified: map['workVerified'] ?? false,
      industryCategory: map['industryCategory'] ?? '',
      role: map['role'] ?? '',
      showIndustry: map['showIndustry'] ?? true,
      showRole: map['showRole'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
