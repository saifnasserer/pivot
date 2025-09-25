import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define TaskImportance enum here
enum TaskImportance { high, mid, low }

class Task {
  final String id;
  String title;
  String description;
  DateTime dueDate;
  TaskImportance importance;
  String? subjectId; // To associate task with a specific subject
  String? sectionId; // To associate task with a specific section
  String? assistantId; // To associate task with a specific assistant
  List<String> completedBy; // List of user IDs who completed the task
  bool isPersonal;
  List<Map<String, String>>? attachments;

  Task({
    String? id, // Make ID optional
    required this.title,
    this.description = '',
    required this.dueDate,
    this.importance = TaskImportance.mid,
    this.subjectId,
    this.sectionId,
    this.assistantId,
    this.completedBy = const [],
    this.isPersonal = false,
    this.attachments,
  }) : id = id ?? const Uuid().v4(); // Generate ID if null

  // Helper method to check if the task is completed by a specific user
  bool isCompletedFor(String userId) {
    return completedBy.contains(userId);
  }

  // Convert a Task object into a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'importance':
          importance.toString().split('.').last, // Store enum as string
      'subjectId': subjectId,
      'sectionId': sectionId,
      'assistantId': assistantId,
      'completedBy': completedBy,
      'isPersonal': isPersonal,
      'attachments': attachments,
    };
  }

  // Create a Task object from a Firestore document
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      importance: TaskImportance.values.firstWhere(
        (e) => e.toString().split('.').last == map['importance'],
        orElse: () => TaskImportance.mid, // Default value if parsing fails
      ),
      subjectId: map['subjectId'],
      sectionId: map['sectionId'],
      assistantId: map['assistantId'],
      completedBy: List<String>.from(map['completedBy'] ?? []),
      isPersonal: map['isPersonal'] ?? false,
      attachments:
          map['attachments'] != null
              ? List<Map<String, String>>.from(
                (map['attachments'] as List).map(
                  (item) => Map<String, String>.from(item),
                ),
              )
              : null,
    );
  }

  // copyWith method for immutable updates
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskImportance? importance,
    String? subjectId,
    String? sectionId,
    String? assistantId,
    List<String>? completedBy,
    bool? isPersonal,
    List<Map<String, String>>? attachments,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      importance: importance ?? this.importance,
      subjectId: subjectId ?? this.subjectId,
      sectionId: sectionId ?? this.sectionId,
      assistantId: assistantId ?? this.assistantId,
      completedBy: completedBy ?? this.completedBy,
      isPersonal: isPersonal ?? this.isPersonal,
      attachments: attachments ?? this.attachments,
    );
  }
}
