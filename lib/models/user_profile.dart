class UserProfile {
  final String id; // Assuming an ID is generated or comes from auth
  String name;
  String? email;
  String department;
  String level;
  String section;
  String? profileImageUrl; // Optional profile picture

  UserProfile({
    required this.id,
    required this.name,
    this.email,
    required this.department,
    required this.level,
    required this.section,
    this.profileImageUrl,
  });

  // Optional: copyWith method for easier updates
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? level,
    String? department,
    String? section,
    String? profileImageUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      level: level ?? this.level,
      section: section ?? this.section,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  // Add this factory constructor to create a UserProfile from a Firestore map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      department: json['department'] as String,
      level: json['level'] as String,
      section: json['section'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  // Add this method to convert a UserProfile to a Firestore map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'level': level,
      'section': section,
      'profileImageUrl': profileImageUrl,
    };
  }
}
