import 'package:cloud_firestore/cloud_firestore.dart';

class Lecture {
  final String id;
  final String title;
  final String doctorId;
  final String categoryName;
  final List<Map<String, String>> links;

  Lecture({
    required this.id,
    required this.title,
    required this.doctorId,
    required this.categoryName,
    this.links = const [],
  });

  Lecture copyWith({
    String? id,
    String? title,
    String? doctorId,
    String? categoryName,
    List<Map<String, String>>? links,
  }) {
    return Lecture(
      id: id ?? this.id,
      title: title ?? this.title,
      doctorId: doctorId ?? this.doctorId,
      categoryName: categoryName ?? this.categoryName,
      links: links ?? this.links,
    );
  }

  factory Lecture.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Lecture(
      id: doc.id,
      title: data['title'] ?? '',
      doctorId: data['doctorId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      links: List<Map<String, String>>.from(
          data['links']?.map((item) => Map<String, String>.from(item)) ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'doctorId': doctorId,
      'categoryName': categoryName,
      'links': links,
    };
  }
}
