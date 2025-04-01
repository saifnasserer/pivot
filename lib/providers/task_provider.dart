import 'package:flutter/foundation.dart';
import 'package:pivot/screens/models/task.dart';
import 'dart:math'; // For generating random IDs

class TaskProvider with ChangeNotifier {
  final List<Task> _tasks = [
    // Add some initial dummy data for testing
    Task(
      id: 'task1',
      title: 'تسليم او جزء من المشروع',
      description:
          'معاد تسليم الجزء الاول من المشروع السبت الحاي في معاج السكشن',
      dueDate: DateTime.now().add(Duration(days: 2)),
      sectionId: 'سكشن 1',
      importance: TaskImportance.high,
    ),
    Task(
      id: 'task2',
      title: 'Prepare Presentation Draft',
      dueDate: DateTime.now().add(Duration(days: 5)),
      sectionId: 'سكشن 1',
      isCompleted: true,
    ),
    Task(
      id: 'task3',
      title: 'Submit Assignment 1',
      dueDate: DateTime.now().add(Duration(days: -1)), // Past due
      sectionId: 'سكشن 2',
      importance: TaskImportance.mid,
    ),
  ];

  List<Task> get tasks => _tasks;

  List<Task> tasksForSection(String sectionId) {
    return _tasks.where((task) => task.sectionId == sectionId).toList();
  }

  // Simple random ID generator (replace with a robust solution like UUID later)
  String _generateRandomId() {
    return Random().nextInt(100000).toString();
  }

  void addTask(Task task) {
    // Assign a unique ID if not provided (or overwrite if needed)
    final newTask = Task(
      id: _generateRandomId(), // Generate ID here
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      importance: task.importance,
      sectionId: task.sectionId,
      isCompleted: task.isCompleted,
    );
    _tasks.add(newTask);
    notifyListeners();
  }

  void updateTask(String id, Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = updatedTask; // Ensure the ID remains the same
      notifyListeners();
    }
  }

  void toggleTaskCompletion(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }
}
