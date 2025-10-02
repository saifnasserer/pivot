import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'announcement_data.g.dart';

/// Data class for announcements, compatible with Firestore
@HiveType(typeId: 5)
class AnnouncementData extends HiveObject {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String date;
  @HiveField(3)
  final int colorValue;
  @HiveField(4)
  final String description;
  @HiveField(5)
  final List<String> tags;
  @HiveField(6)
  final int timestampMillis;
  @HiveField(7)
  final List<String> imageUrls;
  @HiveField(8)
  final List<Map<String, String>> links;
  @HiveField(9)
  final bool pinned;
  @HiveField(10)
  final bool draft;
  @HiveField(11)
  final int? publishAtMillis;
  @HiveField(12)
  final int? expireAtMillis;
  @HiveField(13)
  final String? level;
  @HiveField(14)
  final String? department;

  AnnouncementData({
    this.id,
    required this.title,
    required this.date,
    Color? color,
    required this.description,
    required this.tags,
    DateTime? timestamp,
    this.imageUrls = const [],
    this.links = const [],
    this.pinned = false,
    this.draft = false,
    DateTime? publishAt,
    DateTime? expireAt,
    this.level,
    this.department,
  }) : colorValue = color?.value ?? 0xFFFFFFFF,
       timestampMillis = (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
       publishAtMillis = publishAt?.millisecondsSinceEpoch,
       expireAtMillis = expireAt?.millisecondsSinceEpoch;

  // Constructor for Hive (internal use)
  AnnouncementData._hive({
    this.id,
    required this.title,
    required this.date,
    required this.colorValue,
    required this.description,
    required this.tags,
    required this.timestampMillis,
    this.imageUrls = const [],
    this.links = const [],
    this.pinned = false,
    this.draft = false,
    this.publishAtMillis,
    this.expireAtMillis,
    this.level,
    this.department,
  });

  Color get color => Color(colorValue);
  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampMillis);
  DateTime? get publishAt =>
      publishAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(publishAtMillis!)
          : null;
  DateTime? get expireAt =>
      expireAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(expireAtMillis!)
          : null;

  // Factory constructor for Hive
  factory AnnouncementData.fromHive({
    String? id,
    required String title,
    required String date,
    required int colorValue,
    required String description,
    required List<String> tags,
    required int timestampMillis,
    List<String> imageUrls = const [],
    List<Map<String, String>> links = const [],
    bool pinned = false,
    bool draft = false,
    int? publishAtMillis,
    int? expireAtMillis,
    String? level,
    String? department,
  }) {
    return AnnouncementData._hive(
      id: id,
      title: title,
      date: date,
      colorValue: colorValue,
      description: description,
      tags: tags,
      timestampMillis: timestampMillis,
      imageUrls: imageUrls,
      links: links,
      pinned: pinned,
      draft: draft,
      publishAtMillis: publishAtMillis,
      expireAtMillis: expireAtMillis,
      level: level,
      department: department,
    );
  }

  // Custom factory for reading from Hive with null safety
  factory AnnouncementData.fromHiveWithNullSafety(Map<String, dynamic> data) {
    // Helper function to safely parse links from Hive
    List<Map<String, String>> parseLinksFromHive(dynamic linksData) {
      if (linksData == null) return [];
      final List<dynamic> linksList = List<dynamic>.from(linksData);
      return linksList.map((item) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          return {
            'title': map['title']?.toString() ?? '',
            'url': map['url']?.toString() ?? '',
          };
        }
        return {'title': '', 'url': ''};
      }).toList();
    }

    return AnnouncementData._hive(
      id: data['id'] as String?,
      title: data['title'] as String? ?? '',
      date: data['date'] as String? ?? '',
      colorValue: data['colorValue'] as int? ?? 0xFFFFFFFF,
      description: data['description'] as String? ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      timestampMillis:
          data['timestampMillis'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      links: parseLinksFromHive(data['links']),
      pinned: data['pinned'] as bool? ?? false,
      draft: data['draft'] as bool? ?? false,
      publishAtMillis: data['publishAtMillis'] as int?,
      expireAtMillis: data['expireAtMillis'] as int?,
      level: data['level'] as String?,
      department: data['department'] as String?,
    );
  }

  // Alias for fromFirestore to maintain compatibility
  factory AnnouncementData.fromMap(Map<String, dynamic> map, String id) {
    // Parse the data directly
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return AnnouncementData(
      id: id,
      title: map['title'] as String? ?? '',
      date: map['date'] as String? ?? '',
      color: Color(map['color'] as int? ?? 0xFF000000),
      description: map['description'] as String? ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      timestamp: parseDate(map['timestamp']),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      links: List<Map<String, String>>.from(
        (map['links'] ?? []).map((link) => Map<String, String>.from(link)),
      ),
      pinned: map['pinned'] as bool? ?? false,
      draft: map['draft'] as bool? ?? false,
      publishAt: map['publishAt'] != null ? parseDate(map['publishAt']) : null,
      expireAt: map['expireAt'] != null ? parseDate(map['expireAt']) : null,
      level: map['level'] as String?,
      department: map['department'] as String?,
    );
  }

  // Alias for toJson to maintain compatibility
  Map<String, dynamic> toMap() => toJson();

  // copyWith method for easier updates
  AnnouncementData copyWith({
    String? id,
    String? title,
    String? date,
    Color? color,
    String? description,
    List<String>? tags,
    DateTime? timestamp,
    List<String>? imageUrls,
    List<Map<String, String>>? links,
    bool? pinned,
    bool? draft,
    DateTime? publishAt,
    DateTime? expireAt,
    String? level,
    String? department,
  }) {
    return AnnouncementData(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      color: color ?? Color(colorValue),
      description: description ?? this.description,
      tags: tags ?? this.tags,
      timestamp:
          timestamp ?? DateTime.fromMillisecondsSinceEpoch(timestampMillis),
      imageUrls: imageUrls ?? this.imageUrls,
      links: links ?? this.links,
      pinned: pinned ?? this.pinned,
      draft: draft ?? this.draft,
      publishAt:
          publishAt ??
          (publishAtMillis != null
              ? DateTime.fromMillisecondsSinceEpoch(publishAtMillis!)
              : null),
      expireAt:
          expireAt ??
          (expireAtMillis != null
              ? DateTime.fromMillisecondsSinceEpoch(expireAtMillis!)
              : null),
      level: level ?? this.level,
      department: department ?? this.department,
    );
  }

  // Convert an AnnouncementData object into a map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'color': colorValue,
      'description': description,
      'tags': tags,
      'timestamp': timestampMillis,
      'imageUrls': imageUrls,
      'links': links,
      'pinned': pinned,
      'draft': draft,
      'publishAt': publishAtMillis,
      'expireAt': expireAtMillis,
      'level': level,
      'department': department,
    };
  }

  // Create an AnnouncementData object from a Firestore document
  factory AnnouncementData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        return DateTime.now();
      }
    }

    // Helper function to safely parse links
    List<Map<String, String>> parseLinks(dynamic linksData) {
      if (linksData == null) return [];
      final List<dynamic> linksList = List<dynamic>.from(linksData);
      return linksList.map((item) {
        final map = Map<String, dynamic>.from(item);
        return {
          'title': map['title']?.toString() ?? '',
          'url': map['url']?.toString() ?? '',
        };
      }).toList();
    }

    return AnnouncementData(
      id: doc.id,
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      color: Color(data['color'] ?? 0xFFFFFFFF),
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      timestamp: parseDate(data['timestamp']),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      links: parseLinks(data['links']),
      pinned: data['pinned'] ?? false,
      draft: data['draft'] ?? false,
      publishAt:
          data['publishAt'] != null ? parseDate(data['publishAt']) : null,
      expireAt: data['expireAt'] != null ? parseDate(data['expireAt']) : null,
      level: data['level'] as String?,
      department: data['department'] as String?,
    );
  }
}
