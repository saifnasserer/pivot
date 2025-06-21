import 'package:hive/hive.dart';
part 'subject_model.g.dart';

@HiveType(typeId: 2)
class Subject extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String code;
  @HiveField(3)
  final int year;
  @HiveField(4)
  final String? doctorId;
  @HiveField(5)
  final String department;
  @HiveField(6)
  final String? description;
  @HiveField(7)
  final List<String> enrolledStudents;
  @HiveField(8)
  final String englishName;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.year,
    this.doctorId,
    required this.department,
    this.description,
    this.enrolledStudents = const [],
    required this.englishName,
  });

  Subject copyWith({
    String? id,
    String? name,
    String? code,
    int? year,
    String? doctorId,
    String? department,
    String? description,
    List<String>? enrolledStudents,
    String? englishName,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      year: year ?? this.year,
      doctorId: doctorId ?? this.doctorId,
      department: department ?? this.department,
      description: description ?? this.description,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      englishName: englishName ?? this.englishName,
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json, String id) {
    return Subject(
      id: id,
      name: json['name'] as String,
      code: json['code'] as String,
      year: json['year'] as int,
      doctorId: json['doctorId'] as String?,
      department: json['department'] as String,
      description: json['description'] as String?,
      enrolledStudents: List<String>.from(json['enrolledStudents'] ?? []),
      englishName: json['englishName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'year': year,
      'doctorId': doctorId,
      'department': department,
      'description': description,
      'enrolledStudents': enrolledStudents,
      'englishName': englishName,
    };
  }
}
