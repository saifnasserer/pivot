class Subject {
  final String id;
  final String name;
  final String code;
  final int year;
  final String? doctorId;
  final String department;
  final String? description;
  final List<String> enrolledStudents;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.year,
    this.doctorId,
    required this.department,
    this.description,
    this.enrolledStudents = const [],
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
    };
  }
}
