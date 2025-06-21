import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  AnnouncementData({
    this.id,
    required this.title,
    required this.date,
    required Color color,
    required this.description,
    required this.tags,
    DateTime? timestamp,
    this.imageUrls = const [],
    this.links = const [],
    this.pinned = false,
    this.draft = false,
    DateTime? publishAt,
    DateTime? expireAt,
  }) : colorValue = color.value,
       timestampMillis = (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
       publishAtMillis = publishAt?.millisecondsSinceEpoch,
       expireAtMillis = expireAt?.millisecondsSinceEpoch;

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
    };
  }

  // Create an AnnouncementData object from a Firestore document
  factory AnnouncementData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AnnouncementData(
      id: doc.id,
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      color: Color(data['color'] ?? 0xFFFFFFFF),
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      links: List<Map<String, String>>.from(
        (data['links'] ?? []).map((item) => Map<String, String>.from(item)),
      ),
      pinned: data['pinned'] ?? false,
      draft: data['draft'] ?? false,
      publishAt:
          data['publishAt'] != null
              ? (data['publishAt'] as Timestamp).toDate()
              : null,
      expireAt:
          data['expireAt'] != null
              ? (data['expireAt'] as Timestamp).toDate()
              : null,
    );
  }
}
