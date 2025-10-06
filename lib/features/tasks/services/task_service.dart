import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/services/smart_refresh_service.dart';
import 'package:pivot/services/sound_service.dart';
import 'package:pivot/services/local_notification_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _tasksCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(user.uid).collection('tasks');
  }

  /// Get user-specific notes for a task
  Future<List<TaskNote>> getTaskNotes(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final noteDoc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('task_notes')
              .doc(taskId)
              .get();

      if (!noteDoc.exists || noteDoc.data()?['notes'] == null) {
        return [];
      }

      return (noteDoc.data()!['notes'] as List)
          .map((n) => TaskNote.fromMap(n as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
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
      final docRef = await _tasksCollection.add(task.toMap());

      // Play notification sound for task added
      await SoundService().playNotificationSound();

      // Schedule task reminders if due date is set
      await LocalNotificationService.instance.scheduleTaskReminders(
        taskId: docRef.id,
        taskName: task.title,
        dueDateTime: task.dueDate,
        isCompleted: task.completedBy.isNotEmpty,
      );
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  Future<void> updateTask(String id, Task task) async {
    try {
      await _tasksCollection.doc(id).update(task.toMap());

      // Cancel existing notifications and reschedule if needed
      await LocalNotificationService.instance.cancelTaskReminders(id);

      await LocalNotificationService.instance.scheduleTaskReminders(
        taskId: id,
        taskName: task.title,
        dueDateTime: task.dueDate,
        isCompleted: task.completedBy.isNotEmpty,
      );
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _tasksCollection.doc(id).delete();

      // Cancel all task reminders
      await LocalNotificationService.instance.cancelTaskReminders(id);
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

      // Play completion sound when task is marked as complete
      if (updatedCompletedBy.isNotEmpty && task.completedBy.isEmpty) {
        await SoundService().playCorrectSound();
      }
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
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Store notes in user-specific subcollection for privacy
      final noteDoc = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('task_notes')
          .doc(id);

      final doc = await noteDoc.get();
      final existingNotes =
          doc.exists && doc.data()?['notes'] != null
              ? (doc.data()!['notes'] as List)
                  .map((n) => TaskNote.fromMap(n as Map<String, dynamic>))
                  .toList()
              : <TaskNote>[];

      final updatedNotes = [...existingNotes, TaskNote(content: note)];

      await noteDoc.set({
        'notes': updatedNotes.map((n) => n.toMap()).toList(),
        'taskId': id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add task note: $e');
    }
  }

  Future<void> deleteTaskNote(String id, String noteId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Delete from user-specific subcollection
      final noteDoc = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('task_notes')
          .doc(id);

      final doc = await noteDoc.get();
      if (!doc.exists) return;

      final existingNotes =
          doc.data()?['notes'] != null
              ? (doc.data()!['notes'] as List)
                  .map((n) => TaskNote.fromMap(n as Map<String, dynamic>))
                  .toList()
              : <TaskNote>[];

      final updatedNotes =
          existingNotes.where((note) => note.id != noteId).toList();

      await noteDoc.set({
        'notes': updatedNotes.map((n) => n.toMap()).toList(),
        'taskId': id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete task note: $e');
    }
  }

  Future<void> scheduleTaskReminder(String id, DateTime reminderTime) async {
    try {
      await _tasksCollection.doc(id).update({
        'reminderTime': reminderTime.millisecondsSinceEpoch,
      });

      // Get task details and schedule reminders
      final doc = await _tasksCollection.doc(id).get();
      if (doc.exists) {
        final task = Task.fromMap(doc.data() as Map<String, dynamic>);
        await LocalNotificationService.instance.scheduleTaskReminders(
          taskId: id,
          taskName: task.title,
          dueDateTime: task.dueDate,
          isCompleted: task.completedBy.isNotEmpty,
        );
      }
    } catch (e) {
      throw Exception('Failed to schedule task reminder: $e');
    }
  }

  Future<void> cancelTaskReminder(String id) async {
    try {
      await _tasksCollection.doc(id).update({'reminderTime': null});
      await LocalNotificationService.instance.cancelTaskReminders(id);
    } catch (e) {
      throw Exception('Failed to cancel task reminder: $e');
    }
  }
}
