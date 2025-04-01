import 'package:uuid/uuid.dart'; // For generating unique IDs

// Define TaskImportance enum here
enum TaskImportance { high, mid, low }

class Task {
  final String id;
  String title;
  String description;
  DateTime dueDate;
  TaskImportance importance;
  String sectionId; // To associate task with a specific section
  bool isCompleted;

  Task({
    String? id, // Make ID optional
    required this.title,
    this.description = '',
    required this.dueDate,
    this.importance = TaskImportance.mid,
    required this.sectionId,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4(); // Generate ID if null
}
