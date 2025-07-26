import 'package:hive/hive.dart';
part 'subject_model.g.dart';

@HiveType(typeId: 2)
class Subject extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int hours;
  @HiveField(3)
  final int year;
  @HiveField(4)
  final String? doctorId;
  @HiveField(5)
  final List<String> departments;
  @HiveField(6)
  final String? description;
  @HiveField(7)
  final List<String> enrolledStudents;
  @HiveField(8)
  final String englishName;

  Subject({
    required this.id,
    required this.name,
    required this.hours,
    required this.year,
    this.doctorId,
    required this.departments,
    this.description,
    this.enrolledStudents = const [],
    required this.englishName,
  });

  Subject copyWith({
    String? id,
    String? name,
    int? hours,
    int? year,
    String? doctorId,
    List<String>? departments,
    String? description,
    List<String>? enrolledStudents,
    String? englishName,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      hours: hours ?? this.hours,
      year: year ?? this.year,
      doctorId: doctorId ?? this.doctorId,
      departments: departments ?? this.departments,
      description: description ?? this.description,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      englishName: englishName ?? this.englishName,
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json, String id) {
    final dynamic rawHours = json['hours'] ?? json['code'] ?? 0;
    int hours;
    if (rawHours is int) {
      hours = rawHours;
    } else if (rawHours is String) {
      hours = int.tryParse(rawHours) ?? 0;
    } else {
      hours = 0;
    }
    return Subject(
      id: id,
      name: json['name'] as String,
      hours: hours,
      year: json['year'] as int,
      doctorId: json['doctorId'] as String?,
      departments: List<String>.from(
        json['departments'] ??
            (json['department'] != null ? [json['department']] : []),
      ),
      description: json['description'] as String?,
      enrolledStudents: List<String>.from(json['enrolledStudents'] ?? []),
      englishName: json['englishName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hours': hours,
      'year': year,
      'doctorId': doctorId,
      'departments': departments,
      'description': description,
      'enrolledStudents': enrolledStudents,
      'englishName': englishName,
    };
  }
}
