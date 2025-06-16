import 'package:cloud_firestore/cloud_firestore.dart';

class Section {
  final String id;
  final String name;
  final String subjectId;
  final String days;
  final String time;
  final String location;

  Section({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.days,
    required this.time,
    required this.location,
  });

  factory Section.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Section(
      id: doc.id,
      name: data['name'] ?? '',
      subjectId: data['subjectId'] ?? '',
      days: data['days'] ?? '',
      time: data['time'] ?? '',
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subjectId': subjectId,
      'days': days,
      'time': time,
      'location': location,
    };
  }
}
