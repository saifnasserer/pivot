import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/services/notification_trigger_service.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final CollectionReference _tasksCollection;

  List<Task> _tasks = [];
  StreamSubscription? _tasksSubscription;

  bool _isLoading = false;
  String? _error;

  TaskProvider() {
    _tasksCollection = _firestore.collection('tasks');
    fetchTasks();
  }

  // Getters
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetches tasks from Firestore and listens for real-time updates
  void fetchTasks() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _tasksSubscription?.cancel();
    _tasksSubscription = _tasksCollection.snapshots().listen(
      (snapshot) {
        _tasks =
            snapshot.docs.map((doc) {
              return Task.fromMap(doc.data() as Map<String, dynamic>);
            }).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to fetch tasks: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Returns tasks filtered by a specific section ID
  List<Task> tasksForSection(String sectionId) {
    return _tasks.where((task) => task.sectionId == sectionId).toList();
  }

  // Adds a new task to Firestore
  Future<void> addTask(Task task) async {
    try {
      await _tasksCollection.doc(task.id).set(task.toMap());
      // Send auto notifications for new tasks
      await NotificationTriggerService().sendTaskReminders();
    } catch (e) {
      // Re-throw the exception to be handled by the UI
      throw Exception('Failed to add task: $e');
    }
  }

  // Updates an existing task in Firestore
  Future<void> updateTask(String id, Task updatedTask) async {
    try {
      await _tasksCollection.doc(id).update(updatedTask.toMap());
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Toggles the completion status of a task for the current user
  Future<void> toggleTaskCompletion(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final userId = user.uid;
    final taskRef = _tasksCollection.doc(taskId);

    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      if (task.completedBy.contains(userId)) {
        // If already completed, remove user from the list
        await taskRef.update({
          'completedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        // If not completed, add user to the list
        await taskRef.update({
          'completedBy': FieldValue.arrayUnion([userId]),
        });
      }

      // Send overdue task notifications after status change
      await NotificationTriggerService().sendTaskReminders();
    } catch (e) {
      throw Exception('Failed to toggle task status: $e');
    }
  }

  // Deletes a task from Firestore
  Future<void> deleteTask(String id) async {
    try {
      final doc = await _tasksCollection.doc(id).get();
      String title = '';
      if (doc.exists) {
        final data = doc.data();
        if (data != null &&
            data is Map<String, dynamic> &&
            data['title'] != null) {
          title = data['title'] as String;
        }
      }
      await _tasksCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
