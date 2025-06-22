import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

// Custom Hive adapter to handle null safety properly
class AnnouncementDataAdapter extends TypeAdapter<AnnouncementData> {
  @override
  final int typeId = 5;

  @override
  AnnouncementData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnouncementData.fromHive(
      id: fields[0] as String?,
      title: fields[1] as String,
      date: fields[2] as String,
      colorValue: fields[3] as int,
      description: fields[4] as String,
      tags: (fields[5] as List).cast<String>(),
      timestampMillis: fields[6] as int,
      imageUrls: (fields[7] as List).cast<String>(),
      links:
          (fields[8] as List)
              .map((dynamic e) => (e as Map).cast<String, String>())
              .toList(),
      pinned: fields[9] as bool? ?? false,
      draft: fields[10] as bool? ?? false,
      publishAtMillis: fields[11] as int?,
      expireAtMillis: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, AnnouncementData obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.timestampMillis)
      ..writeByte(7)
      ..write(obj.imageUrls)
      ..writeByte(8)
      ..write(obj.links)
      ..writeByte(9)
      ..write(obj.pinned)
      ..writeByte(10)
      ..write(obj.draft)
      ..writeByte(11)
      ..write(obj.publishAtMillis)
      ..writeByte(12)
      ..write(obj.expireAtMillis);
  }
}
