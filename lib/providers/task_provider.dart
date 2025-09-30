import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/services/notification_trigger_service.dart';
import 'package:pivot/services/local_notification_service.dart';
import 'package:pivot/services/sound_service.dart';
import 'package:pivot/services/smart_refresh_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final CollectionReference _tasksCollection;

  List<Task> _tasks = [];
  StreamSubscription? _tasksSubscription;

  bool _isLoading = false;
  String? _error;

  TaskProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _tasksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks');
      fetchTasks();
    }
  }

  // Getters
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetches tasks from Firestore with smart refresh logic
  Future<void> fetchTasks({bool force = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use smart refresh to avoid unnecessary calls
      final result = await SmartRefreshService().smartRefresh(
        'tasks',
        () async {
          final snapshot =
              await _tasksCollection
                  .orderBy('createdAt', descending: true)
                  .limit(50) // Limit to prevent excessive reads
                  .get();

          return snapshot.docs.map((doc) {
            return Task.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();
        },
        force: force,
      );

      _tasks = result;

      // After syncing tasks, (re)schedule local reminders on mobile
      if (!kIsWeb) {
        for (final t in _tasks) {
          await LocalNotificationService.instance.scheduleTaskReminders(
            taskId: t.id,
            taskName: t.title,
            dueDateTime: t.dueDate,
            isCompleted: _isTaskCompletedForCurrentUser(t),
          );
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _error = 'Failed to fetch tasks: $error';
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isTaskCompletedForCurrentUser(Task task) {
    final user = _auth.currentUser;
    final uid = user?.uid;
    if (uid == null) return false;
    return task.completedBy.contains(uid);
  }

  // Send immediate local notification for new task
  Future<void> _sendLocalNewTaskNotification(Task task) async {
    try {
      if (kIsWeb) return; // Local notifications are for mobile only

      print(
        'TaskProvider: Sending local notification for new task: ${task.title}',
      );

      // Determine notification title and body based on task priority
      String notificationTitle;
      String notificationBody;

      switch (task.importance) {
        case TaskImportance.high:
          notificationTitle = '🔥 تاسك مهم جديد!';
          notificationBody = task.title;
          break;
        case TaskImportance.mid:
          notificationTitle = '📋 تاسك جديد';
          notificationBody = task.title;
          break;
        case TaskImportance.low:
          notificationTitle = '📝 تاسك جديد';
          notificationBody = task.title;
      }

      // Send instant notification
      await LocalNotificationService.instance.sendImmediateNotification(
        title: notificationTitle,
        body: notificationBody,
        payload: {
          'type': 'new_task',
          'taskId': task.id,
          'taskTitle': task.title,
        },
      );

      print(
        'TaskProvider: ✅ Successfully sent local notification for new task: ${task.title}',
      );
    } catch (e) {
      print('TaskProvider: Error sending local new task notification: $e');
    }
  }

  // Returns tasks filtered by a specific section ID
  List<Task> tasksForSection(String sectionId) {
    return _tasks.where((task) => task.sectionId == sectionId).toList();
  }

  // Adds a new task to Firestore
  Future<void> addTask(Task task) async {
    try {
      await _tasksCollection.doc(task.id).set(task.toMap());

      // Local scheduling for the current device
      if (!kIsWeb) {
        await LocalNotificationService.instance.scheduleTaskReminders(
          taskId: task.id,
          taskName: task.title,
          dueDateTime: task.dueDate,
          isCompleted: false,
        );
      }

      // Send immediate FCM notification for new task
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await NotificationTriggerService().sendNewTaskNotification(
          currentUser.uid,
          task.title,
          task.dueDate,
        );

        // Send immediate local notification for new task (only for non-personal tasks)
        if (!task.isPersonal) {
          await _sendLocalNewTaskNotification(task);
        }
      }
    } catch (e) {
      // Re-throw the exception to be handled by the UI
      throw Exception('Failed to add task: $e');
    }
  }

  // Updates an existing task in Firestore
  Future<void> updateTask(String id, Task updatedTask) async {
    try {
      await _tasksCollection.doc(id).update(updatedTask.toMap());

      // Re-schedule locally
      if (!kIsWeb) {
        await LocalNotificationService.instance.scheduleTaskReminders(
          taskId: updatedTask.id,
          taskName: updatedTask.title,
          dueDateTime: updatedTask.dueDate,
          isCompleted: _isTaskCompletedForCurrentUser(updatedTask),
        );
      }
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
      final currentlyCompleted = task.completedBy.contains(userId);
      if (currentlyCompleted) {
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

      // Re-schedule (or cancel) local reminders according to new status
      if (!kIsWeb) {
        final updatedCompleted = !currentlyCompleted;
        await LocalNotificationService.instance.scheduleTaskReminders(
          taskId: task.id,
          taskName: task.title,
          dueDateTime: task.dueDate,
          isCompleted: updatedCompleted,
        );
      }

      // Play sound when task is completed
      if (!currentlyCompleted) {
        // Task was just completed
        await SoundService().playCorrectSound();
      }

      // Send overdue task notifications after status change (legacy remote)
      try {
        await NotificationTriggerService().sendTaskReminders();
      } catch (e) {
        print('Warning: Failed to send task reminders after status change: $e');
        // Don't throw here as it's not critical for task completion
      }
    } catch (e) {
      throw Exception('Failed to toggle task status: $e');
    }
  }

  // Deletes a task from Firestore
  Future<void> deleteTask(String id) async {
    try {
      // Cancel local reminders first
      if (!kIsWeb) {
        await LocalNotificationService.instance.cancelTaskReminders(id);
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
