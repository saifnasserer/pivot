import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? email;

  @HiveField(3)
  String department;

  @HiveField(4)
  String level;

  @HiveField(5)
  String section;

  @HiveField(6)
  String? profileImageUrl;

  @HiveField(7)
  String role;

  @HiveField(8)
  String aboutMe;

  @HiveField(9)
  List<String> teachingSubjects;

  @HiveField(10)
  List<String> enrolledSubjects;

  @HiveField(11)
  String gender;

  @HiveField(12)
  String? fcmToken;

  @HiveField(13)
  DateTime? lastTokenUpdate;

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
    this.fcmToken,
    this.lastTokenUpdate,
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
    String? fcmToken,
    DateTime? lastTokenUpdate,
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
      fcmToken: fcmToken ?? this.fcmToken,
      lastTokenUpdate: lastTokenUpdate ?? this.lastTokenUpdate,
    );
  }

  // Add this factory constructor to create a UserProfile from a Firestore map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseLastTokenUpdate(dynamic value) {
      if (value == null) return null;

      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      department: json['department'] as String? ?? 'غير محدد',
      level: json['level'] as String? ?? 'غير محدد',
      section: json['section'] as String? ?? 'A',
      profileImageUrl: json['profileImageUrl'] as String?,
      role: json['role'] as String? ?? 'Student',
      aboutMe: json['aboutMe'] as String? ?? '',
      teachingSubjects: List<String>.from(json['teachingSubjects'] ?? []),
      enrolledSubjects: List<String>.from(json['enrolledSubjects'] ?? []),
      gender: json['gender'] as String? ?? 'ذكر',
      fcmToken: json['fcmToken'] as String?,
      lastTokenUpdate: parseLastTokenUpdate(json['lastTokenUpdate']),
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
      'fcmToken': fcmToken,
      'lastTokenUpdate': lastTokenUpdate?.millisecondsSinceEpoch,
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
        other.gender == gender &&
        other.fcmToken == fcmToken &&
        other.lastTokenUpdate == lastTokenUpdate;
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
      fcmToken,
      lastTokenUpdate,
    );
  }
}
