import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'section_model.g.dart';

@HiveType(typeId: 1)
class Section extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String assistantId; // Changed from subjectId - sections belong to assistants
  @HiveField(3)
  final String subjectId; // Now a reference field - which subject this section is for
  @HiveField(4)
  final String days;
  @HiveField(5)
  final String time;
  @HiveField(6)
  final String location;

  Section({
    required this.id,
    required this.name,
    required this.assistantId,
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
      assistantId: data['assistantId'] ?? '',
      subjectId: data['subjectId'] ?? '',
      days: data['days'] ?? '',
      time: data['time'] ?? '',
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'assistantId': assistantId,
      'subjectId': subjectId,
      'days': days,
      'time': time,
      'location': location,
    };
  }
}
