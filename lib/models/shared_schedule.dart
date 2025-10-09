import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/screens/models/schedule_item.dart';

class SharedSchedule {
  final String shareId;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final List<ScheduleItem> items;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int accessCount;
  final bool isActive;

  SharedSchedule({
    required this.shareId,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.items,
    required this.createdAt,
    this.expiresAt,
    this.accessCount = 0,
    this.isActive = true,
  });

  factory SharedSchedule.fromJson(Map<String, dynamic> json) {
    return SharedSchedule(
      shareId: json['shareId'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      items:
          (json['items'] as List<dynamic>)
              .map(
                (item) => ScheduleItem.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      expiresAt:
          json['expiresAt'] != null
              ? (json['expiresAt'] as Timestamp).toDate()
              : null,
      accessCount: json['accessCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shareId': shareId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'accessCount': accessCount,
      'isActive': isActive,
    };
  }

  SharedSchedule copyWith({
    String? shareId,
    String? ownerId,
    String? ownerName,
    String? title,
    String? description,
    List<ScheduleItem>? items,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? accessCount,
    bool? isActive,
  }) {
    return SharedSchedule(
      shareId: shareId ?? this.shareId,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      title: title ?? this.title,
      description: description ?? this.description,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      accessCount: accessCount ?? this.accessCount,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if the shared schedule is still valid (not expired)
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Get the shareable link
  String get shareLink {
    return 'https://your-app-domain.com/schedule/$shareId';
  }
}
