import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// Define TaskImportance enum here
enum TaskImportance { high, mid, low }

class Task {
  final String id;
  String title;
  String description;
  DateTime dueDate;
  TaskImportance importance;
  String subjectId; // To associate task with a specific subject
  String sectionId; // To associate task with a specific section
  List<String> completedBy; // List of user IDs who completed the task

  Task({
    String? id, // Make ID optional
    required this.title,
    this.description = '',
    required this.dueDate,
    this.importance = TaskImportance.mid,
    required this.subjectId,
    required this.sectionId,
    this.completedBy = const [],
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
      'importance': importance.toString().split('.').last, // Store enum as string
      'subjectId': subjectId,
      'sectionId': sectionId,
      'completedBy': completedBy,
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
      completedBy: List<String>.from(map['completedBy'] ?? []),
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
    List<String>? completedBy,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      importance: importance ?? this.importance,
      subjectId: subjectId ?? this.subjectId,
      sectionId: sectionId ?? this.sectionId,
      completedBy: completedBy ?? this.completedBy,
    );
  }
}
