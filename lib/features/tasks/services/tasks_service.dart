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

  // Get archived tasks collection reference for current user
  CollectionReference get _archivedTasksCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('archived_tasks');
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
      print('🔥 [TasksService.addTask] Starting Firebase save...');
      print('   Task ID: ${task.id}');
      print('   Task Title: ${task.title}');

      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated - cannot save task');
      }

      print('   User authenticated: ${user.uid}');
      print('   Collection path: users/${user.uid}/tasks/${task.id}');

      // Validate task data before saving
      if (task.title.trim().isEmpty) {
        throw Exception('Task title cannot be empty');
      }

      // Convert task to map and validate
      final taskMap = task.toMap();
      print('   Task map keys: ${taskMap.keys.toList()}');
      print('   Task map values: ${taskMap.values.toList()}');

      // Add timeout to prevent hanging in release mode
      await _tasksCollection
          .doc(task.id)
          .set(taskMap)
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Task save operation timed out after 30 seconds');
            },
          );

      print('✅ [TasksService.addTask] Task saved successfully to Firebase');
      return true;
    } catch (e) {
      print('❌ [TasksService.addTask] Firebase save failed: $e');
      print('   Stack trace: ${StackTrace.current}');
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

  // Archive a completed task (move from tasks to archived_tasks)
  Future<bool> archiveTask(Task task) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ TasksService: User not logged in');
        throw Exception('User not logged in');
      }

      print('📦 TasksService: Starting archive process for task ${task.id}');
      print('   Task title: ${task.title}');
      print('   CompletedBy: ${task.completedBy}');

      // Add archived timestamp to task data
      final archivedTaskData = {
        ...task.toMap(),
        'archivedAt': FieldValue.serverTimestamp(),
        'archivedBy': user.uid,
      };

      print('   Archive data prepared, starting batch operation...');

      // Use batch to ensure atomicity
      final batch = _firestore.batch();

      // Add to archived collection
      final archivedDocRef = _archivedTasksCollection.doc(task.id);
      batch.set(archivedDocRef, archivedTaskData);
      print('   ✓ Batch: SET to archived_tasks/${task.id}');

      // Remove from active tasks
      final activeDocRef = _tasksCollection.doc(task.id);
      batch.delete(activeDocRef);
      print('   ✓ Batch: DELETE from tasks/${task.id}');

      print('   Committing batch...');
      await batch.commit();

      print('✅ TasksService: Task ${task.id} archived successfully!');
      print('   Path: users/${user.uid}/archived_tasks/${task.id}');
      return true;
    } catch (e) {
      print('❌ TasksService: Failed to archive task - $e');
      print('   Stack trace: ${StackTrace.current}');
      throw Exception('Failed to archive task: $e');
    }
  }

  // Restore archived task back to active tasks
  Future<bool> restoreArchivedTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ TasksService: User not logged in for restore');
        throw Exception('User not logged in');
      }

      print('🔄 TasksService: Starting restore process for task $taskId');

      // Get archived task
      final archivedDoc = await _archivedTasksCollection.doc(taskId).get();
      if (!archivedDoc.exists) {
        print('❌ TasksService: Archived task $taskId not found');
        throw Exception('Archived task not found');
      }

      final taskData = archivedDoc.data() as Map<String, dynamic>;
      print('   Task title: ${taskData['title']}');
      print('   Current completedBy: ${taskData['completedBy']}');

      // Remove archive-specific fields
      taskData.remove('archivedAt');
      taskData.remove('archivedBy');

      // IMPORTANT: Remove current user from completedBy array
      // This marks the task as NOT completed for this user
      final completedBy = List<String>.from(taskData['completedBy'] ?? []);
      completedBy.remove(user.uid);
      taskData['completedBy'] = completedBy;

      print('   Updated completedBy (user removed): $completedBy');

      // Use batch to ensure atomicity
      final batch = _firestore.batch();

      // Add back to active tasks with updated completedBy
      batch.set(_tasksCollection.doc(taskId), taskData);

      // Remove from archived collection
      batch.delete(_archivedTasksCollection.doc(taskId));

      print('   Committing batch...');
      await batch.commit();

      print('✅ TasksService: Task $taskId restored successfully');
      print('   Path: users/${user.uid}/tasks/$taskId');
      return true;
    } catch (e) {
      print('❌ TasksService: Failed to restore task - $e');
      throw Exception('Failed to restore task: $e');
    }
  }

  // Get all archived tasks for current user
  Future<List<Task>> getArchivedTasks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ TasksService: User not logged in for getArchivedTasks');
        throw Exception('User not logged in');
      }

      print('📂 TasksService: Fetching archived tasks...');
      print('   Path: users/${user.uid}/archived_tasks');

      final snapshot =
          await _archivedTasksCollection
              .orderBy('archivedAt', descending: true)
              .get();

      print('   Found ${snapshot.docs.length} archived tasks');

      final tasks =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('   - ${doc.id}: ${data['title']}');
            return Task.fromMap(data);
          }).toList();

      print(
        '✅ TasksService: Successfully fetched ${tasks.length} archived tasks',
      );
      return tasks;
    } catch (e) {
      print('❌ TasksService: Failed to fetch archived tasks - $e');
      throw Exception('Failed to fetch archived tasks: $e');
    }
  }

  // Get all archived tasks including global tasks where user is in completedBy
  Future<List<Task>> getAllArchivedTasks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ TasksService: User not logged in for getAllArchivedTasks');
        throw Exception('User not logged in');
      }

      print(
        '📂 TasksService: Fetching all archived tasks (personal + global)...',
      );

      // Get personal archived tasks
      final personalArchivedTasks = await getArchivedTasks();
      print('   Found ${personalArchivedTasks.length} personal archived tasks');

      // Get global tasks where user is in completedBy list
      final globalCompletedTasks = await _getGlobalCompletedTasks(user.uid);
      print('   Found ${globalCompletedTasks.length} global completed tasks');

      // Combine both lists
      final allArchivedTasks = [
        ...personalArchivedTasks,
        ...globalCompletedTasks,
      ];

      // Sort by completion date (most recent first)
      allArchivedTasks.sort((a, b) {
        // For personal tasks, use archivedAt
        // For global tasks, we'll use dueDate as completion date
        if (a.isPersonal && b.isPersonal) {
          // Both personal - compare archivedAt if available
          return 0; // Keep original order from query
        } else if (a.isPersonal) {
          return -1; // Personal tasks first
        } else if (b.isPersonal) {
          return 1; // Global tasks after personal
        } else {
          // Both global - compare by dueDate
          return b.dueDate.compareTo(a.dueDate);
        }
      });

      print(
        '✅ TasksService: Successfully fetched ${allArchivedTasks.length} total archived tasks',
      );
      return allArchivedTasks;
    } catch (e) {
      print('❌ TasksService: Failed to fetch all archived tasks - $e');
      throw Exception('Failed to fetch all archived tasks: $e');
    }
  }

  // Get global tasks where user is in completedBy list
  Future<List<Task>> _getGlobalCompletedTasks(String userId) async {
    try {
      print('🌐 TasksService: Fetching global tasks completed by user $userId');

      // Query global tasks where user is in completedBy array
      final snapshot =
          await _tasksCollection
              .where('completedBy', arrayContains: userId)
              .where('isPersonal', isEqualTo: false)
              .get();

      print('   Found ${snapshot.docs.length} global completed tasks');

      final tasks =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('   - ${doc.id}: ${data['title']} (Global)');
            return Task.fromMap(data);
          }).toList();

      return tasks;
    } catch (e) {
      print('❌ TasksService: Failed to fetch global completed tasks - $e');
      return []; // Return empty list on error to not break the main flow
    }
  }

  // Delete archived task permanently
  Future<bool> deleteArchivedTask(String taskId) async {
    try {
      await _archivedTasksCollection.doc(taskId).delete();
      print('✅ TasksService: Archived task $taskId deleted permanently');
      return true;
    } catch (e) {
      print('❌ TasksService: Failed to delete archived task - $e');
      throw Exception('Failed to delete archived task: $e');
    }
  }

  // Clean up old archived tasks (optional - can be called periodically)
  Future<bool> cleanupOldArchivedTasks({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final snapshot =
          await _archivedTasksCollection
              .where('archivedAt', isLessThan: Timestamp.fromDate(cutoffDate))
              .get();

      if (snapshot.docs.isEmpty) {
        print('✅ TasksService: No old archived tasks to clean up');
        return true;
      }

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print(
        '✅ TasksService: Cleaned up ${snapshot.docs.length} old archived tasks',
      );
      return true;
    } catch (e) {
      print('❌ TasksService: Failed to cleanup archived tasks - $e');
      throw Exception('Failed to cleanup archived tasks: $e');
    }
  }
}
