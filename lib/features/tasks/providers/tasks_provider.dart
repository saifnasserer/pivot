import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/tasks/services/tasks_service.dart';
import 'package:pivot/features/tasks/repositories/tasks_repository.dart';
import 'package:pivot/screens/models/task.dart';

// Services
final tasksServiceProvider = Provider<TasksService>((ref) {
  return TasksService();
});

// Repositories
final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final service = ref.watch(tasksServiceProvider);
  return TasksRepository(service);
});

// State classes
class TasksState {
  final bool isLoading;
  final String? error;
  final List<Task> tasks;
  final List<Task> filteredTasks;
  final Map<String, dynamic>? statistics;
  final String searchQuery;
  final String? selectedSectionId;
  final String? selectedSubjectId;
  final TaskImportance? selectedImportance;
  final bool showPersonalOnly;
  final bool showCompletedOnly;
  final bool showOverdueOnly;
  final bool showTodayOnly;

  const TasksState({
    this.isLoading = false,
    this.error,
    this.tasks = const [],
    this.filteredTasks = const [],
    this.statistics,
    this.searchQuery = '',
    this.selectedSectionId,
    this.selectedSubjectId,
    this.selectedImportance,
    this.showPersonalOnly = false,
    this.showCompletedOnly = false,
    this.showOverdueOnly = false,
    this.showTodayOnly = false,
  });

  TasksState copyWith({
    bool? isLoading,
    String? error,
    List<Task>? tasks,
    List<Task>? filteredTasks,
    Map<String, dynamic>? statistics,
    String? searchQuery,
    String? selectedSectionId,
    String? selectedSubjectId,
    TaskImportance? selectedImportance,
    bool? showPersonalOnly,
    bool? showCompletedOnly,
    bool? showOverdueOnly,
    bool? showTodayOnly,
  }) {
    return TasksState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      tasks: tasks ?? this.tasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      statistics: statistics ?? this.statistics,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSectionId: selectedSectionId ?? this.selectedSectionId,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      selectedImportance: selectedImportance ?? this.selectedImportance,
      showPersonalOnly: showPersonalOnly ?? this.showPersonalOnly,
      showCompletedOnly: showCompletedOnly ?? this.showCompletedOnly,
      showOverdueOnly: showOverdueOnly ?? this.showOverdueOnly,
      showTodayOnly: showTodayOnly ?? this.showTodayOnly,
    );
  }
}

// Notifier
class TasksNotifier extends StateNotifier<TasksState> {
  final TasksRepository _repository;

  TasksNotifier(this._repository) : super(const TasksState());

  // Get all tasks
  Future<void> getAllTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _repository.getAllTasks();
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get tasks by section
  Future<void> getTasksBySection(String sectionId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedSectionId: sectionId,
    );
    try {
      final tasks = await _repository.getTasksBySection(sectionId);
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get tasks by subject
  Future<void> getTasksBySubject(String subjectId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedSubjectId: subjectId,
    );
    try {
      final tasks = await _repository.getTasksBySubject(subjectId);
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get tasks by importance
  Future<void> getTasksByImportance(TaskImportance importance) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedImportance: importance,
    );
    try {
      final tasks = await _repository.getTasksByImportance(importance);
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get personal tasks
  Future<void> getPersonalTasks() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      showPersonalOnly: true,
    );
    try {
      final tasks = await _repository.getPersonalTasks();
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get completed tasks
  Future<void> getCompletedTasks() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      showCompletedOnly: true,
    );
    try {
      final tasks = await _repository.getCompletedTasks();
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get pending tasks
  Future<void> getPendingTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _repository.getPendingTasks();
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get overdue tasks
  Future<void> getOverdueTasks() async {
    state = state.copyWith(isLoading: true, error: null, showOverdueOnly: true);
    try {
      final tasks = await _repository.getOverdueTasks();
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get tasks due today
  Future<void> getTasksDueToday() async {
    state = state.copyWith(isLoading: true, error: null, showTodayOnly: true);
    try {
      final tasks = await _repository.getTasksDueToday();
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Add task
  Future<bool> addTask(Task task) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.addTask(task);
      if (success) {
        await getAllTasks(); // Refresh the list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update task
  Future<bool> updateTask(Task task) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.updateTask(task);
      if (success) {
        await getAllTasks(); // Refresh the list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Delete task
  Future<bool> deleteTask(String taskId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.deleteTask(taskId);
      if (success) {
        await getAllTasks(); // Refresh the list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Mark task as completed
  Future<bool> markTaskCompleted(String taskId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.markTaskCompleted(taskId);
      if (success) {
        await getAllTasks(); // Refresh the list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Mark task as not completed
  Future<bool> markTaskNotCompleted(String taskId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.markTaskNotCompleted(taskId);
      if (success) {
        await getAllTasks(); // Refresh the list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Search tasks
  Future<void> searchTasks(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final tasks = await _repository.searchTasks(query);
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get task statistics
  Future<void> getTaskStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statistics = await _repository.getTaskStatistics();
      state = state.copyWith(isLoading: false, statistics: statistics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get tasks by date range
  Future<void> getTasksByDateRange(DateTime startDate, DateTime endDate) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _repository.getTasksByDateRange(startDate, endDate);
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Bulk update tasks
  Future<bool> bulkUpdateTasks(List<Task> tasks) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.bulkUpdateTasks(tasks);
      if (success) {
        await getAllTasks(); // Refresh the list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Bulk delete tasks
  Future<bool> bulkDeleteTasks(List<String> taskIds) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.bulkDeleteTasks(taskIds);
      if (success) {
        await getAllTasks(); // Refresh the list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Filter tasks locally
  void filterTasks({
    String? query,
    String? sectionId,
    String? subjectId,
    TaskImportance? importance,
    bool? personalOnly,
    bool? completedOnly,
    bool? overdueOnly,
    bool? todayOnly,
  }) {
    List<Task> filtered = state.tasks;

    // Filter by search query
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      filtered =
          filtered.where((task) {
            return task.title.toLowerCase().contains(lowercaseQuery) ||
                task.description.toLowerCase().contains(lowercaseQuery);
          }).toList();
    }

    // Filter by section
    if (sectionId != null && sectionId.isNotEmpty) {
      filtered = filtered.where((task) => task.sectionId == sectionId).toList();
    }

    // Filter by subject
    if (subjectId != null && subjectId.isNotEmpty) {
      filtered = filtered.where((task) => task.subjectId == subjectId).toList();
    }

    // Filter by importance
    if (importance != null) {
      filtered =
          filtered.where((task) => task.importance == importance).toList();
    }

    // Filter by personal only
    if (personalOnly == true) {
      filtered = filtered.where((task) => task.isPersonal).toList();
    }

    // Filter by completed only
    if (completedOnly == true) {
      // This would need to be implemented based on current user
      // For now, we'll skip this filter
    }

    // Filter by overdue only
    if (overdueOnly == true) {
      final now = DateTime.now();
      filtered = filtered.where((task) => task.dueDate.isBefore(now)).toList();
    }

    // Filter by today only
    if (todayOnly == true) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      filtered =
          filtered
              .where(
                (task) =>
                    task.dueDate.isAfter(today) &&
                    task.dueDate.isBefore(tomorrow),
              )
              .toList();
    }

    state = state.copyWith(
      filteredTasks: filtered,
      searchQuery: query ?? state.searchQuery,
      selectedSectionId: sectionId ?? state.selectedSectionId,
      selectedSubjectId: subjectId ?? state.selectedSubjectId,
      selectedImportance: importance ?? state.selectedImportance,
      showPersonalOnly: personalOnly ?? state.showPersonalOnly,
      showCompletedOnly: completedOnly ?? state.showCompletedOnly,
      showOverdueOnly: overdueOnly ?? state.showOverdueOnly,
      showTodayOnly: todayOnly ?? state.showTodayOnly,
    );
  }

  // Clear filters
  void clearFilters() {
    state = state.copyWith(
      filteredTasks: state.tasks,
      searchQuery: '',
      selectedSectionId: null,
      selectedSubjectId: null,
      selectedImportance: null,
      showPersonalOnly: false,
      showCompletedOnly: false,
      showOverdueOnly: false,
      showTodayOnly: false,
    );
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      await _repository.toggleTaskCompletion(taskId);
      // Refresh tasks to get updated completion status
      await getAllTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Providers
final tasksProvider =
    AutoDisposeStateNotifierProvider<TasksNotifier, TasksState>((ref) {
      final repository = ref.watch(tasksRepositoryProvider);
      return TasksNotifier(repository);
    });

// Convenience providers for specific data
final tasksListProvider = AutoDisposeProvider<List<Task>>((ref) {
  final state = ref.watch(tasksProvider);
  return state.tasks;
});

final filteredTasksProvider = AutoDisposeProvider<List<Task>>((ref) {
  final state = ref.watch(tasksProvider);
  return state.filteredTasks;
});

final taskStatisticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(tasksProvider);
  return state.statistics;
});

final tasksSearchQueryProvider = AutoDisposeProvider<String>((ref) {
  final state = ref.watch(tasksProvider);
  return state.searchQuery;
});

final tasksSelectedSectionProvider = AutoDisposeProvider<String?>((ref) {
  final state = ref.watch(tasksProvider);
  return state.selectedSectionId;
});

final tasksSelectedSubjectProvider = AutoDisposeProvider<String?>((ref) {
  final state = ref.watch(tasksProvider);
  return state.selectedSubjectId;
});

final tasksSelectedImportanceProvider = AutoDisposeProvider<TaskImportance?>((
  ref,
) {
  final state = ref.watch(tasksProvider);
  return state.selectedImportance;
});
