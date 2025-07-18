import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledNotification {
  final String? id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final List<String> targetUserIds;
  final bool sendToAllUsers;
  final String? department;
  final String? level;
  final String status; // 'pending', 'sent', 'cancelled', 'failed'
  final int? sentCount;
  final int? totalCount;
  final String? errorMessage;
  final DateTime? sentAt;
  final Map<String, dynamic>? additionalData;

  ScheduledNotification({
    this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    required this.targetUserIds,
    required this.sendToAllUsers,
    this.department,
    this.level,
    required this.status,
    this.sentCount,
    this.totalCount,
    this.errorMessage,
    this.sentAt,
    this.additionalData,
  });

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: json['id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      scheduledTime: (json['scheduledTime'] as Timestamp).toDate(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      createdBy: json['createdBy'] as String,
      createdByName: json['createdByName'] as String,
      targetUserIds: List<String>.from(json['targetUserIds'] ?? []),
      sendToAllUsers: json['sendToAllUsers'] as bool? ?? false,
      department: json['department'] as String?,
      level: json['level'] as String?,
      status: json['status'] as String? ?? 'pending',
      sentCount: json['sentCount'] as int?,
      totalCount: json['totalCount'] as int?,
      errorMessage: json['errorMessage'] as String?,
      sentAt:
          json['sentAt'] != null
              ? (json['sentAt'] as Timestamp).toDate()
              : null,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'targetUserIds': targetUserIds,
      'sendToAllUsers': sendToAllUsers,
      'department': department,
      'level': level,
      'status': status,
      'sentCount': sentCount,
      'totalCount': totalCount,
      'errorMessage': errorMessage,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'additionalData': additionalData,
    };
  }

  ScheduledNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? scheduledTime,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
    List<String>? targetUserIds,
    bool? sendToAllUsers,
    String? department,
    String? level,
    String? status,
    int? sentCount,
    int? totalCount,
    String? errorMessage,
    DateTime? sentAt,
    Map<String, dynamic>? additionalData,
  }) {
    return ScheduledNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      targetUserIds: targetUserIds ?? this.targetUserIds,
      sendToAllUsers: sendToAllUsers ?? this.sendToAllUsers,
      department: department ?? this.department,
      level: level ?? this.level,
      status: status ?? this.status,
      sentCount: sentCount ?? this.sentCount,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage ?? this.errorMessage,
      sentAt: sentAt ?? this.sentAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  bool get isPending => status == 'pending';
  bool get isSent => status == 'sent';
  bool get isCancelled => status == 'cancelled';
  bool get isFailed => status == 'failed';
  bool get isOverdue => scheduledTime.isBefore(DateTime.now()) && isPending;

  String get statusText {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'sent':
        return 'تم الإرسال';
      case 'cancelled':
        return 'ملغي';
      case 'failed':
        return 'فشل';
      default:
        return 'غير معروف';
    }
  }

  String get timeUntilScheduled {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.isNegative) {
      return 'متأخر';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
