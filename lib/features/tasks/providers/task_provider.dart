import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/features/tasks/repositories/task_repository.dart';
import 'package:pivot/features/tasks/services/task_service.dart';
import 'package:pivot/screens/models/task.dart';

final taskServiceProvider = Provider<TaskService>((ref) => TaskService());

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final service = ref.watch(taskServiceProvider);
  return TaskRepository(service);
});

class TaskState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final StreamSubscription? tasksSubscription;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.tasksSubscription,
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    StreamSubscription? tasksSubscription,
  }) => TaskState(
    tasks: tasks ?? this.tasks,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    tasksSubscription: tasksSubscription ?? this.tasksSubscription,
  );
}

final taskProvider = StateNotifierProvider.autoDispose<TaskNotifier, TaskState>(
  (ref) => TaskNotifier(ref),
);

class TaskNotifier extends StateNotifier<TaskState> {
  TaskNotifier(this._ref) : super(const TaskState()) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      fetchTasks();
    }
  }

  final Ref _ref;
  late final TaskRepository _repo = _ref.read(taskRepositoryProvider);

  Future<void> fetchTasks({bool force = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _repo.fetchTasks(force: force);
      state = state.copyWith(isLoading: false, tasks: tasks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addTask(Task task) async {
    try {
      await _repo.addTask(task);
      // Refresh tasks
      await fetchTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateTask(String id, Task task) async {
    try {
      await _repo.updateTask(id, task);
      // Refresh tasks
      await fetchTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repo.deleteTask(id);
      // Refresh tasks
      await fetchTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleTaskCompletion(String id) async {
    try {
      await _repo.toggleTaskCompletion(id);
      // Refresh tasks
      await fetchTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setTaskPriority(String id, TaskImportance importance) async {
    try {
      await _repo.setTaskPriority(id, importance);
      // Refresh tasks
      await fetchTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setTaskDueDate(String id, DateTime? dueDate) async {
    try {
      await _repo.setTaskDueDate(id, dueDate);
      // Refresh tasks
      await fetchTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<List<TaskNote>> getTaskNotes(String taskId) async {
    try {
      return await _repo.getTaskNotes(taskId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<void> addTaskNote(String id, String note) async {
    // Notes are stored in user-specific collection, handled directly by service
    await _repo.addTaskNote(id, note);
  }

  Future<void> deleteTaskNote(String id, String noteId) async {
    // Notes are stored in user-specific collection, handled directly by service
    await _repo.deleteTaskNote(id, noteId);
  }

  Future<void> scheduleTaskReminder(String id, DateTime reminderTime) async {
    try {
      await _repo.scheduleTaskReminder(id, reminderTime);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cancelTaskReminder(String id) async {
    try {
      await _repo.cancelTaskReminder(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<Task> getTasksByPriority(TaskImportance importance) {
    return state.tasks.where((task) => task.importance == importance).toList();
  }

  List<Task> getCompletedTasks() {
    return state.tasks.where((task) => task.completedBy.isNotEmpty).toList();
  }

  List<Task> getOverdueTasks() {
    final now = DateTime.now();
    return state.tasks.where((task) {
      return task.dueDate.isBefore(now) && task.completedBy.isEmpty;
    }).toList();
  }

  List<Task> getTodayTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state.tasks.where((task) {
      return task.dueDate.isAtSameMomentAs(today);
    }).toList();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    state.tasksSubscription?.cancel();
    super.dispose();
  }
}
