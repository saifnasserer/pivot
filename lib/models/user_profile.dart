import 'package:flutter/foundation.dart';

class UserProfile {
  final String id;
  String name;
  String? email;
  String department;
  String level;
  String section;
  String? profileImageUrl;
  String role;
  String aboutMe;
  List<String> teachingSubjects;
  List<String> enrolledSubjects;
  String gender;

  UserProfile({
    required this.id,
    required this.name,
    this.email,
    required this.department,
    required this.level,
    required this.section,
    this.profileImageUrl = '',
    this.role = 'Student',
    this.aboutMe = '',
    this.teachingSubjects = const [],
    this.enrolledSubjects = const [],
    this.gender = 'ذكر',
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
    String? role,
    String? aboutMe,
    List<String>? teachingSubjects,
    List<String>? enrolledSubjects,
    String? gender,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      level: level ?? this.level,
      section: section ?? this.section,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      aboutMe: aboutMe ?? this.aboutMe,
      teachingSubjects: teachingSubjects ?? [...this.teachingSubjects],
      enrolledSubjects: enrolledSubjects ?? [...this.enrolledSubjects],
      gender: gender ?? this.gender,
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
      role: json['role'] ?? 'Student',
      aboutMe: json['aboutMe'] ?? '',
      teachingSubjects: List<String>.from(json['teachingSubjects'] ?? []),
      enrolledSubjects: List<String>.from(json['enrolledSubjects'] ?? []),
      gender: json['gender'] as String? ?? 'ذكر',
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
      'role': role,
      'aboutMe': aboutMe,
      'teachingSubjects': teachingSubjects,
      'enrolledSubjects': enrolledSubjects,
      'gender': gender,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.department == department &&
        other.level == level &&
        other.section == section &&
        other.profileImageUrl == profileImageUrl &&
        other.role == role &&
        listEquals(other.teachingSubjects, teachingSubjects) &&
        listEquals(other.enrolledSubjects, enrolledSubjects) &&
        other.aboutMe == aboutMe &&
        other.gender == gender;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      department,
      level,
      section,
      profileImageUrl,
      role,
      Object.hashAll(teachingSubjects),
      Object.hashAll(enrolledSubjects),
      aboutMe,
      gender,
    );
  }
}
