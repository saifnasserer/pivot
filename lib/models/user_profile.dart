import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
part 'user_profile.g.dart';

@HiveType(typeId: 1)
class SocialMediaLink {
  @HiveField(0)
  final String platform;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String? displayName;

  SocialMediaLink({
    required this.platform,
    required this.url,
    this.displayName,
  });

  factory SocialMediaLink.fromJson(Map<String, dynamic> json) {
    return SocialMediaLink(
      platform: json['platform'] as String,
      url: json['url'] as String,
      displayName: json['displayName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'platform': platform, 'url': url, 'displayName': displayName};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialMediaLink &&
        other.platform == platform &&
        other.url == url &&
        other.displayName == displayName;
  }

  @override
  int get hashCode {
    return Object.hash(platform, url, displayName);
  }
}

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

  @HiveField(14)
  NotificationPreferences notificationPreferences;

  @HiveField(15)
  List<SocialMediaLink> socialMediaLinks;

  @HiveField(16)
  Map<String, String> assistantPreferences; // subjectId -> assistantId

  @HiveField(17)
  int? userNumber; // Sequential user number for early adopter recognition

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
    NotificationPreferences? notificationPreferences,
    this.socialMediaLinks = const [],
    this.assistantPreferences = const {},
    this.userNumber,
  }) : notificationPreferences =
           notificationPreferences ?? NotificationPreferences();

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
    NotificationPreferences? notificationPreferences,
    List<SocialMediaLink>? socialMediaLinks,
    Map<String, String>? assistantPreferences,
    int? userNumber,
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
      teachingSubjects: teachingSubjects ?? this.teachingSubjects,
      enrolledSubjects: enrolledSubjects ?? this.enrolledSubjects,
      gender: gender ?? this.gender,
      fcmToken: fcmToken ?? this.fcmToken,
      lastTokenUpdate: lastTokenUpdate ?? this.lastTokenUpdate,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      assistantPreferences: assistantPreferences ?? this.assistantPreferences,
      userNumber: userNumber ?? this.userNumber,
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
      teachingSubjects:
          (json['teachingSubjects'] as List<dynamic>?)?.cast<String>() ?? [],
      enrolledSubjects:
          (json['enrolledSubjects'] as List<dynamic>?)?.cast<String>() ?? [],
      gender: json['gender'] as String? ?? 'ذكر',
      fcmToken: json['fcmToken'] as String?,
      lastTokenUpdate: parseLastTokenUpdate(json['lastTokenUpdate']),
      notificationPreferences: NotificationPreferences.fromJson(
        json['notificationPreferences'] ?? {},
      ),
      socialMediaLinks:
          (json['socialMediaLinks'] as List<dynamic>?)
              ?.map(
                (link) =>
                    SocialMediaLink.fromJson(link as Map<String, dynamic>),
              )
              .toList() ??
          [],
      assistantPreferences:
          (json['assistantPreferences'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
          ) ??
          {},
      userNumber: json['userNumber'] as int?,
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
      'notificationPreferences': notificationPreferences.toJson(),
      'socialMediaLinks':
          socialMediaLinks.map((link) => link.toJson()).toList(),
      'assistantPreferences': assistantPreferences,
      'userNumber': userNumber,
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
        other.lastTokenUpdate == lastTokenUpdate &&
        other.notificationPreferences == notificationPreferences &&
        listEquals(other.socialMediaLinks, socialMediaLinks) &&
        other.assistantPreferences == assistantPreferences &&
        other.userNumber == userNumber;
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
      notificationPreferences,
      Object.hashAll(socialMediaLinks),
      Object.hashAll(assistantPreferences.entries),
      userNumber,
    );
  }
}

@HiveType(typeId: 6)
class NotificationPreferences {
  @HiveField(0)
  final bool taskReminders;
  @HiveField(1)
  final bool classReminders;
  @HiveField(2)
  final bool announcements;
  @HiveField(3)
  final bool departmentNotifications;
  @HiveField(4)
  final bool levelNotifications;
  @HiveField(5)
  final int maxNotificationsPerHour;
  @HiveField(6)
  final bool welcomeNotification;

  NotificationPreferences({
    this.taskReminders = true,
    this.classReminders = true,
    this.announcements = true,
    this.departmentNotifications = true,
    this.levelNotifications = true,
    this.maxNotificationsPerHour = 10,
    this.welcomeNotification = true,
  });

  Map<String, dynamic> toJson() => {
    'taskReminders': taskReminders,
    'classReminders': classReminders,
    'announcements': announcements,
    'departmentNotifications': departmentNotifications,
    'levelNotifications': levelNotifications,
    'maxNotificationsPerHour': maxNotificationsPerHour,
    'welcomeNotification': welcomeNotification,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      taskReminders: json['taskReminders'] ?? true,
      classReminders: json['classReminders'] ?? true,
      announcements: json['announcements'] ?? true,
      departmentNotifications: json['departmentNotifications'] ?? true,
      levelNotifications: json['levelNotifications'] ?? true,
      maxNotificationsPerHour: json['maxNotificationsPerHour'] ?? 10,
      welcomeNotification: json['welcomeNotification'] ?? true,
    );
  }
}
