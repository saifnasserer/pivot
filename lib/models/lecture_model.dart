import 'package:cloud_firestore/cloud_firestore.dart';

class Lecture {
  final String id;
  final String title;
  final String subjectId;
  final String doctorId;
  final String categoryName;
  final List<Map<String, dynamic>> links;
  final DateTime? createdAt;

  Lecture({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.doctorId,
    required this.categoryName,
    this.links = const [],
    this.createdAt,
  });

  Lecture copyWith({
    String? id,
    String? title,
    String? subjectId,
    String? doctorId,
    String? categoryName,
    List<Map<String, dynamic>>? links,
    DateTime? createdAt,
  }) {
    return Lecture(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      doctorId: doctorId ?? this.doctorId,
      categoryName: categoryName ?? this.categoryName,
      links: links ?? this.links,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Lecture.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime? createdAt;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.tryParse(data['createdAt']);
      }
    }

    return Lecture(
      id: doc.id,
      title: data['title'] ?? '',
      subjectId: data['subjectId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      links: List<Map<String, dynamic>>.from(
        data['links']?.map((item) => Map<String, dynamic>.from(item)) ?? [],
      ),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subjectId': subjectId,
      'doctorId': doctorId,
      'categoryName': categoryName,
      'links': links,
      'createdAt': createdAt ?? DateTime.now(),
    };
  }
}
