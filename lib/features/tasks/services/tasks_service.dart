import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/screens/models/task.dart';

class TasksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get tasks collection reference for current user
  CollectionReference get _tasksCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(user.uid).collection('tasks');
  }

  // Get all tasks for current user
  Future<List<Task>> getAllTasks() async {
    try {
      final snapshot =
          await _tasksCollection.orderBy('dueDate', descending: false).get();
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  // Get tasks by section
  Future<List<Task>> getTasksBySection(String sectionId) async {
    try {
      final snapshot =
          await _tasksCollection
              .where('sectionId', isEqualTo: sectionId)
              .orderBy('dueDate', descending: false)
              .get();
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks by section: $e');
    }
  }

  // Get tasks by subject
  Future<List<Task>> getTasksBySubject(String subjectId) async {
    try {
      final snapshot =
          await _tasksCollection
              .where('subjectId', isEqualTo: subjectId)
              .orderBy('dueDate', descending: false)
              .get();
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks by subject: $e');
    }
  }

  // Get tasks by importance
  Future<List<Task>> getTasksByImportance(TaskImportance importance) async {
    try {
      final snapshot =
          await _tasksCollection
              .where(
                'importance',
                isEqualTo: importance.toString().split('.').last,
              )
              .orderBy('dueDate', descending: false)
              .get();
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks by importance: $e');
    }
  }

  // Get personal tasks
  Future<List<Task>> getPersonalTasks() async {
    try {
      final snapshot =
          await _tasksCollection
              .where('isPersonal', isEqualTo: true)
              .orderBy('dueDate', descending: false)
              .get();
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch personal tasks: $e');
    }
  }

  // Get completed tasks
  Future<List<Task>> getCompletedTasks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot =
          await _tasksCollection
              .where('completedBy', arrayContains: user.uid)
              .orderBy('dueDate', descending: true)
              .get();
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch completed tasks: $e');
    }
  }

  // Get pending tasks
  Future<List<Task>> getPendingTasks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final allTasks = await getAllTasks();
      return allTasks.where((task) => !task.isCompletedFor(user.uid)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending tasks: $e');
    }
  }

  // Get overdue tasks
  Future<List<Task>> getOverdueTasks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final allTasks = await getAllTasks();
      return allTasks
          .where(
            (task) =>
                task.dueDate.isBefore(now) && !task.isCompletedFor(user.uid),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch overdue tasks: $e');
    }
  }

  // Get tasks due today
  Future<List<Task>> getTasksDueToday() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final allTasks = await getAllTasks();
      return allTasks
          .where(
            (task) =>
                task.dueDate.isAfter(today) &&
                task.dueDate.isBefore(tomorrow) &&
                !task.isCompletedFor(user.uid),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks due today: $e');
    }
  }

  // Add task
  Future<bool> addTask(Task task) async {
    try {
      await _tasksCollection.doc(task.id).set(task.toMap());
      return true;
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  // Update task
  Future<bool> updateTask(Task task) async {
    try {
      await _tasksCollection.doc(task.id).update(task.toMap());
      return true;
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Delete task
  Future<bool> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Mark task as completed
  Future<bool> markTaskCompleted(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final taskDoc = await _tasksCollection.doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');

      final taskData = taskDoc.data() as Map<String, dynamic>;
      final completedBy = List<String>.from(taskData['completedBy'] ?? []);

      if (!completedBy.contains(user.uid)) {
        completedBy.add(user.uid);
        await _tasksCollection.doc(taskId).update({'completedBy': completedBy});
      }

      return true;
    } catch (e) {
      throw Exception('Failed to mark task as completed: $e');
    }
  }

  // Mark task as not completed
  Future<bool> markTaskNotCompleted(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final taskDoc = await _tasksCollection.doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');

      final taskData = taskDoc.data() as Map<String, dynamic>;
      final completedBy = List<String>.from(taskData['completedBy'] ?? []);

      completedBy.remove(user.uid);
      await _tasksCollection.doc(taskId).update({'completedBy': completedBy});

      return true;
    } catch (e) {
      throw Exception('Failed to mark task as not completed: $e');
    }
  }

  // Search tasks
  Future<List<Task>> searchTasks(String query) async {
    try {
      final allTasks = await getAllTasks();
      final lowercaseQuery = query.toLowerCase();

      return allTasks.where((task) {
        return task.title.toLowerCase().contains(lowercaseQuery) ||
            task.description.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }

  // Get task statistics
  Future<Map<String, dynamic>> getTaskStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final allTasks = await getAllTasks();
      final completedTasks = await getCompletedTasks();
      final pendingTasks = await getPendingTasks();
      final overdueTasks = await getOverdueTasks();
      final todayTasks = await getTasksDueToday();

      int totalTasks = allTasks.length;
      int completedCount = completedTasks.length;
      int pendingCount = pendingTasks.length;
      int overdueCount = overdueTasks.length;
      int todayCount = todayTasks.length;

      // Count by importance
      Map<String, int> importanceCounts = {};
      for (var task in allTasks) {
        final importance = task.importance.toString().split('.').last;
        importanceCounts[importance] = (importanceCounts[importance] ?? 0) + 1;
      }

      // Count by section
      Map<String, int> sectionCounts = {};
      for (var task in allTasks) {
        if (task.sectionId != null) {
          sectionCounts[task.sectionId!] =
              (sectionCounts[task.sectionId!] ?? 0) + 1;
        }
      }

      return {
        'totalTasks': totalTasks,
        'completedCount': completedCount,
        'pendingCount': pendingCount,
        'overdueCount': overdueCount,
        'todayCount': todayCount,
        'completionRate':
            totalTasks > 0 ? (completedCount / totalTasks * 100).round() : 0,
        'importanceCounts': importanceCounts,
        'sectionCounts': sectionCounts,
      };
    } catch (e) {
      throw Exception('Failed to fetch task statistics: $e');
    }
  }

  // Get tasks by date range
  Future<List<Task>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allTasks = await getAllTasks();
      return allTasks
          .where(
            (task) =>
                task.dueDate.isAfter(startDate) &&
                task.dueDate.isBefore(endDate),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks by date range: $e');
    }
  }

  // Bulk update tasks
  Future<bool> bulkUpdateTasks(List<Task> tasks) async {
    try {
      final batch = _firestore.batch();

      for (var task in tasks) {
        batch.update(_tasksCollection.doc(task.id), task.toMap());
      }

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('Failed to bulk update tasks: $e');
    }
  }

  // Bulk delete tasks
  Future<bool> bulkDeleteTasks(List<String> taskIds) async {
    try {
      final batch = _firestore.batch();

      for (var taskId in taskIds) {
        batch.delete(_tasksCollection.doc(taskId));
      }

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('Failed to bulk delete tasks: $e');
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _tasksCollection.doc(taskId).get();
      if (!doc.exists) throw Exception('Task not found');

      final task = Task.fromMap(doc.data() as Map<String, dynamic>);
      final isCompleted = task.completedBy.contains(user.uid);

      if (isCompleted) {
        await _tasksCollection.doc(taskId).update({
          'completedBy': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        await _tasksCollection.doc(taskId).update({
          'completedBy': FieldValue.arrayUnion([user.uid]),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
