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
    );
  }

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
    };
  }
}
