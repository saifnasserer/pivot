import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/services/smart_refresh_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _tasksCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(user.uid).collection('tasks');
  }

  Future<List<Task>> fetchTasks({bool force = false}) async {
    try {
      // Use smart refresh to avoid unnecessary calls
      final result = await SmartRefreshService().smartRefresh(
        'tasks',
        () async {
          final snapshot =
              await _tasksCollection
                  .orderBy('createdAt', descending: true)
                  .get();

          return snapshot.docs
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        },
        force: force,
      );

      return result;
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  Future<void> addTask(Task task) async {
    try {
      await _tasksCollection.add(task.toMap());

      // TODO: Implement sound and notification services
      // await SoundService().playTaskAddedSound();
      // if (task.reminderTime != null) {
      //   await NotificationTriggerService().scheduleTaskReminder(task);
      // }
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  Future<void> updateTask(String id, Task task) async {
    try {
      await _tasksCollection.doc(id).update(task.toMap());

      // TODO: Implement notification services
      // await NotificationTriggerService().cancelNotification(id);
      // if (task.reminderTime != null) {
      //   await NotificationTriggerService().scheduleTaskReminder(task);
      // }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _tasksCollection.doc(id).delete();

      // TODO: Implement notification services
      // await NotificationTriggerService().cancelNotification(id);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<void> toggleTaskCompletion(String id) async {
    try {
      final doc = await _tasksCollection.doc(id).get();
      if (!doc.exists) throw Exception('Task not found');

      final task = Task.fromMap(doc.data() as Map<String, dynamic>);
      // Toggle completion by adding/removing current user from completedBy
      final currentUser = _auth.currentUser?.uid;
      if (currentUser == null) throw Exception('User not authenticated');

      final isCompleted = task.completedBy.contains(currentUser);
      final updatedCompletedBy =
          isCompleted
              ? task.completedBy.where((id) => id != currentUser).toList()
              : [...task.completedBy, currentUser];

      final updatedTask = task.copyWith(completedBy: updatedCompletedBy);

      await _tasksCollection.doc(id).update(updatedTask.toMap());

      // TODO: Implement sound service
      // if (updatedTask.completedBy.isNotEmpty) {
      //   await SoundService().playTaskCompletedSound();
      // }
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  Future<void> setTaskPriority(String id, TaskImportance importance) async {
    try {
      await _tasksCollection.doc(id).update({'importance': importance.name});
    } catch (e) {
      throw Exception('Failed to set task priority: $e');
    }
  }

  Future<void> setTaskDueDate(String id, DateTime? dueDate) async {
    try {
      await _tasksCollection.doc(id).update({
        'dueDate': dueDate?.millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to set task due date: $e');
    }
  }

  Future<void> addTaskNote(String id, String note) async {
    try {
      final doc = await _tasksCollection.doc(id).get();
      if (!doc.exists) throw Exception('Task not found');

      // final task = Task.fromMap(doc.data() as Map<String, dynamic>);
      // TODO: Implement notes functionality
      // final updatedNotes = [
      //   ...task.notes,
      //   TaskNote(
      //     id: DateTime.now().millisecondsSinceEpoch.toString(),
      //     content: note,
      //     createdAt: DateTime.now(),
      //   ),
      // ];

      // TODO: Implement notes update
      // await _tasksCollection.doc(id).update({
      //   'notes': updatedNotes.map((n) => n.toMap()).toList(),
      // });
    } catch (e) {
      throw Exception('Failed to add task note: $e');
    }
  }

  Future<void> deleteTaskNote(String id, String noteId) async {
    try {
      final doc = await _tasksCollection.doc(id).get();
      if (!doc.exists) throw Exception('Task not found');

      // final task = Task.fromMap(doc.data() as Map<String, dynamic>);
      // TODO: Implement notes functionality
      // final updatedNotes =
      //     task.notes.where((note) => note.id != noteId).toList();

      // TODO: Implement notes update
      // await _tasksCollection.doc(id).update({
      //   'notes': updatedNotes.map((n) => n.toMap()).toList(),
      // });
    } catch (e) {
      throw Exception('Failed to delete task note: $e');
    }
  }

  Future<void> scheduleTaskReminder(String id, DateTime reminderTime) async {
    try {
      await _tasksCollection.doc(id).update({
        'reminderTime': reminderTime.millisecondsSinceEpoch,
      });

      // TODO: Implement notification services
      // final doc = await _tasksCollection.doc(id).get();
      // if (doc.exists) {
      //   final task = Task.fromMap(doc.data() as Map<String, dynamic>);
      //   await NotificationTriggerService().scheduleTaskReminder(task);
      // }
    } catch (e) {
      throw Exception('Failed to schedule task reminder: $e');
    }
  }

  Future<void> cancelTaskReminder(String id) async {
    try {
      await _tasksCollection.doc(id).update({'reminderTime': null});
      // TODO: Implement notification services
      // await NotificationTriggerService().cancelNotification(id);
    } catch (e) {
      throw Exception('Failed to cancel task reminder: $e');
    }
  }
}
