import 'package:cloud_firestore/cloud_firestore.dart';

class CommentData {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime timestamp;
  final List<String> likes;
  final String? parentId;
  final bool edited;
  final DateTime? editedAt;
  final String? userProfileImageUrl;

  CommentData({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.timestamp,
    required this.likes,
    this.parentId,
    this.edited = false,
    this.editedAt,
    this.userProfileImageUrl,
  });

  factory CommentData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentData(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      content: data['content'] ?? '',
      timestamp:
          (data['timestamp'] is Timestamp)
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      likes: List<String>.from(data['likes'] ?? []),
      parentId: data['parentId'],
      edited: data['edited'] ?? false,
      editedAt:
          data['editedAt'] != null
              ? (data['editedAt'] is Timestamp
                  ? (data['editedAt'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(data['editedAt']))
              : null,
      userProfileImageUrl: data['userProfileImageUrl'] as String?,
    );
  }

  // Alias for fromFirestore to maintain compatibility
  factory CommentData.fromMap(Map<String, dynamic> map, String id) {
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

    return CommentData(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      content: map['content'] as String? ?? '',
      timestamp: parseDate(map['timestamp']),
      likes: List<String>.from(map['likes'] ?? []),
      parentId: map['parentId'] as String?,
      edited: map['edited'] as bool? ?? false,
      editedAt: map['editedAt'] != null ? parseDate(map['editedAt']) : null,
      userProfileImageUrl: map['userProfileImageUrl'] as String?,
    );
  }

  // Alias for toJson to maintain compatibility
  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'likes': likes,
      'parentId': parentId,
      'edited': edited,
      'editedAt': editedAt?.millisecondsSinceEpoch,
      'userProfileImageUrl': userProfileImageUrl,
    };
  }
}
