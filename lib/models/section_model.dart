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
  final String subjectId;
  @HiveField(3)
  final String days;
  @HiveField(4)
  final String time;
  @HiveField(5)
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
