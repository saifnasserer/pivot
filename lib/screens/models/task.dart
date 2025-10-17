import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define TaskImportance enum here
enum TaskImportance { high, mid, low }

// TaskNote class for task notes
class TaskNote {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TaskNote({
    String? id,
    required this.content,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory TaskNote.fromMap(Map<String, dynamic> map) {
    return TaskNote(
      id: map['id'],
      content: map['content'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt:
          map['updatedAt'] != null
              ? (map['updatedAt'] as Timestamp).toDate()
              : null,
    );
  }

  TaskNote copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskNote(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

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
  final List<TaskNote> notes; // List of notes for the task

  // Source information fields
  String? assistantName; // Assistant's name
  String? sectionNumber; // Section number extracted from section name

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
    List<TaskNote>? notes,
    this.assistantName,
    this.sectionNumber,
  }) : notes = notes ?? [],
       id = id ?? const Uuid().v4(); // Generate ID if null

  // Helper method to check if the task is completed by a specific user
  bool isCompletedFor(String userId) {
    return completedBy.contains(userId);
  }

  // Helper method to get formatted source information
  String get sourceInfo {
    if (assistantName != null && sectionNumber != null) {
      return '$assistantName - سكشن $sectionNumber';
    } else if (assistantName != null) {
      return assistantName!;
    } else if (sectionNumber != null) {
      return 'سكشن $sectionNumber';
    } else {
      return 'مصدر غير محدد';
    }
  }

  // Helper method to extract section number from section name
  static String extractSectionNumber(String sectionName) {
    // Extract number from section name (e.g., "سكشن 1" -> "1")
    final parts = sectionName.split(' ');
    if (parts.length > 1) {
      final lastPart = parts.last;
      // Check if it's a number
      if (RegExp(r'^\d+$').hasMatch(lastPart)) {
        return lastPart;
      }
    }
    return '';
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
      'assistantName': assistantName,
      'sectionNumber': sectionNumber,
      // Notes are stored separately in user-specific task_notes collection
    };
  }

  // Convert to JSON-safe map (for offline queueing)
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch, // Convert to int for JSON
      'importance':
          importance.toString().split('.').last, // Store enum as string
      'subjectId': subjectId,
      'sectionId': sectionId,
      'assistantId': assistantId,
      'completedBy': completedBy,
      'isPersonal': isPersonal,
      'attachments': attachments,
      'assistantName': assistantName,
      'sectionNumber': sectionNumber,
    };
  }

  // Create from JSON map
  factory Task.fromJsonMap(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(json['dueDate'] as int),
      importance: TaskImportance.values.firstWhere(
        (e) => e.toString().split('.').last == json['importance'],
        orElse: () => TaskImportance.mid,
      ),
      subjectId: json['subjectId'],
      sectionId: json['sectionId'],
      assistantId: json['assistantId'],
      completedBy: List<String>.from(json['completedBy'] ?? []),
      isPersonal: json['isPersonal'] ?? false,
      attachments:
          json['attachments'] != null
              ? List<Map<String, String>>.from(
                (json['attachments'] as List).map(
                  (item) => Map<String, String>.from(item),
                ),
              )
              : null,
      notes: [],
      assistantName: json['assistantName'],
      sectionNumber: json['sectionNumber'],
    );
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
      // Notes are not stored in task document, fetched separately from task_notes collection
      notes: [],
      assistantName: map['assistantName'],
      sectionNumber: map['sectionNumber'],
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
    List<TaskNote>? notes,
    String? assistantName,
    String? sectionNumber,
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
      notes: notes ?? this.notes,
      assistantName: assistantName ?? this.assistantName,
      sectionNumber: sectionNumber ?? this.sectionNumber,
    );
  }
}
