import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/tasks/services/tasks_service.dart';
import 'package:pivot/features/tasks/repositories/tasks_repository.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/services/offline_queue_service.dart';
import 'package:pivot/features/subjects/providers/subject_provider.dart';

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
  final Ref _ref;
  DateTime? _lastRefreshTime;

  TasksNotifier(this._repository, this._ref) : super(const TasksState());

  // Helper method to execute operations with offline check
  Future<T> _executeWithOfflineCheck<T>({
    required Future<T> Function() operation,
    required T emptyResult,
  }) async {
    final offlineService = _ref.read(offlineServiceProvider);
    if (offlineService.isOffline) {
      print('📴 [TasksProvider] Offline - returning empty result');
      return emptyResult;
    }

    print('🌐 [TasksProvider] Online - executing operation');
    return await operation();
  }

  // Helper method to check if task should be shown in current view
  bool _shouldShowTaskInCurrentView(Task task) {
    // Check section filter
    if (state.selectedSectionId != null &&
        task.sectionId != state.selectedSectionId) {
      return false;
    }

    // Check subject filter
    if (state.selectedSubjectId != null &&
        task.subjectId != state.selectedSubjectId) {
      return false;
    }

    // Check importance filter
    if (state.selectedImportance != null &&
        task.importance != state.selectedImportance) {
      return false;
    }

    // Check personal filter
    if (state.showPersonalOnly && !task.isPersonal) {
      return false;
    }

    // Check overdue filter
    if (state.showOverdueOnly && !task.dueDate.isBefore(DateTime.now())) {
      return false;
    }

    // Check today filter
    if (state.showTodayOnly) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      if (!(task.dueDate.isAfter(today) && task.dueDate.isBefore(tomorrow))) {
        return false;
      }
    }

    // Check search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      if (!task.title.toLowerCase().contains(query) &&
          !task.description.toLowerCase().contains(query)) {
        return false;
      }
    }

    return true;
  }

  // Helper method to refresh current view context
  Future<void> _refreshCurrentView() async {
    // Only refresh if not already loading to prevent multiple simultaneous calls
    if (state.isLoading) {
      print('⚠️ [TasksProvider] Already loading, skipping refresh');
      return;
    }

    // Debounce: Only refresh if last refresh was more than 1 second ago
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!).inSeconds < 1) {
      print('⚠️ [TasksProvider] Refresh too soon, skipping (debounced)');
      return;
    }
    _lastRefreshTime = now;

    // Determine which view to refresh based on current state
    if (state.selectedSectionId != null) {
      await getTasksBySection(state.selectedSectionId!);
    } else if (state.selectedSubjectId != null) {
      await getTasksBySubject(state.selectedSubjectId!);
    } else if (state.selectedImportance != null) {
      await getTasksByImportance(state.selectedImportance!);
    } else if (state.showPersonalOnly) {
      await getPersonalTasks();
    } else if (state.showCompletedOnly) {
      await getCompletedTasks();
    } else if (state.showOverdueOnly) {
      await getOverdueTasks();
    } else if (state.showTodayOnly) {
      await getTasksDueToday();
    } else if (state.searchQuery.isNotEmpty) {
      await searchTasks(state.searchQuery);
    } else {
      await getAllTasks();
    }
  }

  // Get all tasks
  Future<void> getAllTasks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tasks = await _executeWithOfflineCheck(
        operation: () => _repository.getAllTasks(),
        emptyResult: <Task>[],
      );

      // Populate subject names for tasks that don't have them
      final tasksWithSubjectNames = await _populateSubjectNames(tasks);

      state = state.copyWith(
        isLoading: false,
        tasks: tasksWithSubjectNames,
        filteredTasks: tasksWithSubjectNames,
      );
    } catch (e) {
      print('❌ [TasksProvider] Error fetching tasks: $e');
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
      final tasks = await _executeWithOfflineCheck(
        operation: () => _repository.getTasksBySection(sectionId),
        emptyResult: <Task>[],
      );
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
      final tasks = await _executeWithOfflineCheck(
        operation: () => _repository.getTasksBySubject(subjectId),
        emptyResult: <Task>[],
      );
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
      final tasks = await _executeWithOfflineCheck(
        operation: () => _repository.getTasksByImportance(importance),
        emptyResult: <Task>[],
      );
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
      final tasks = await _executeWithOfflineCheck(
        operation: () => _repository.getPersonalTasks(),
        emptyResult: <Task>[],
      );
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
      final tasks = await _executeWithOfflineCheck(
        operation: () => _repository.getCompletedTasks(),
        emptyResult: <Task>[],
      );
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
      final tasks = await _executeWithOfflineCheck(
        operation: () => _repository.getPendingTasks(),
        emptyResult: <Task>[],
      );
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
      final tasks = await _executeWithOfflineCheck(
        operation: () => _repository.getOverdueTasks(),
        emptyResult: <Task>[],
      );
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
      final tasks = await _executeWithOfflineCheck(
        operation: () => _repository.getTasksDueToday(),
        emptyResult: <Task>[],
      );
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        filteredTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Add task - NO optimistic update for data integrity
  Future<bool> addTask(Task task) async {
    print('🎯 [TasksProvider.addTask] Starting...');
    print('   Task ID: ${task.id}');
    print('   Task Title: ${task.title}');

    // Check if offline first
    final offlineService = _ref.read(offlineServiceProvider);
    print(
      '   Checking connectivity: ${offlineService.isOffline ? "OFFLINE" : "ONLINE"}',
    );

    if (offlineService.isOffline) {
      print('📴 [TasksProvider] Offline - queueing task add operation');

      try {
        print('   Converting task to JSON-safe map...');
        final taskData = task.toJsonMap(); // Use JSON-safe version!
        print('   Task data keys: ${taskData.keys.toList()}');
        print('   Task data values count: ${taskData.length}');

        print('   Creating QueuedOperation...');
        final operation = QueuedOperation(
          id: 'task_add_${task.id}',
          type: OperationType.createTask,
          data: taskData,
          timestamp: DateTime.now(),
        );
        print('   QueuedOperation created');

        print('   Calling queueOperation...');
        // Queue the operation for later sync
        await OfflineQueueService().queueOperation(operation);

        print('✅ [TasksProvider] Task add queued successfully');
        // Return true to indicate queued (not showing error to user)
        return true;
      } catch (e, stackTrace) {
        print('❌ [TasksProvider] Failed to queue task: $e');
        print('   Stack trace: $stackTrace');
        state = state.copyWith(error: e.toString());
        // Re-throw the error to ensure it's not silently ignored
        rethrow;
      }
    }

    // Online - save to Firebase first, THEN update UI
    try {
      print('🌐 [TasksProvider] Online - saving task to Firebase...');
      print('   Current state tasks count: ${state.tasks.length}');
      print(
        '   Current state filtered tasks count: ${state.filteredTasks.length}',
      );

      final success = await _repository.addTask(task);
      print('   Repository addTask returned: $success');

      if (success) {
        // Only update UI after confirmed save
        final updatedTasks = [...state.tasks, task];
        final updatedFilteredTasks =
            _shouldShowTaskInCurrentView(task)
                ? [...state.filteredTasks, task]
                : state.filteredTasks;

        print('   Updating state...');
        print('   New tasks count: ${updatedTasks.length}');
        print('   New filtered tasks count: ${updatedFilteredTasks.length}');
        print(
          '   Should show in current view: ${_shouldShowTaskInCurrentView(task)}',
        );

        state = state.copyWith(
          tasks: updatedTasks,
          filteredTasks: updatedFilteredTasks,
        );

        print('✅ [TasksProvider] Task saved and UI updated');
        print('   Final state tasks count: ${state.tasks.length}');
        print(
          '   Final state filtered tasks count: ${state.filteredTasks.length}',
        );
      } else {
        print('❌ [TasksProvider] Add failed - repository returned false');
        throw Exception('Repository returned false for task add operation');
      }

      return success;
    } catch (e) {
      print('❌ [TasksProvider] Add error: $e');
      print('   Stack trace: ${StackTrace.current}');
      state = state.copyWith(error: e.toString());
      // Re-throw the error to ensure it's not silently ignored
      rethrow;
    }
  }

  // Update task - NO optimistic update for data integrity
  Future<bool> updateTask(Task task) async {
    // Check if offline first
    final offlineService = _ref.read(offlineServiceProvider);
    if (offlineService.isOffline) {
      print('📴 [TasksProvider] Offline - queueing task update operation');

      try {
        // Queue the operation for later sync
        await OfflineQueueService().queueOperation(
          QueuedOperation(
            id: 'task_update_${task.id}',
            type: OperationType.updateTask,
            data: task.toJsonMap(), // Use JSON-safe version!
            timestamp: DateTime.now(),
          ),
        );

        print('✅ [TasksProvider] Task update queued successfully');
        return true;
      } catch (e) {
        print('❌ [TasksProvider] Failed to queue task update: $e');
        state = state.copyWith(error: e.toString());
        return false;
      }
    }

    // Online - save to Firebase first, THEN update UI
    try {
      print('🌐 [TasksProvider] Online - updating task in Firebase...');
      final success = await _repository.updateTask(task);

      if (success) {
        // Only update UI after confirmed save
        final updatedTasks =
            state.tasks.map((t) => t.id == task.id ? task : t).toList();

        // Check if updated task should be in filtered view
        final shouldShow = _shouldShowTaskInCurrentView(task);
        final updatedFilteredTasks =
            state.filteredTasks.where((t) => t.id != task.id).toList();
        if (shouldShow) {
          updatedFilteredTasks.add(task);
        }

        state = state.copyWith(
          tasks: updatedTasks,
          filteredTasks: updatedFilteredTasks,
        );

        print('✅ TasksProvider: Task updated and UI refreshed');
      } else {
        print('❌ TasksProvider: Update failed');
      }

      return success;
    } catch (e) {
      print('❌ TasksProvider: Update error: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Delete task - NO optimistic update for data integrity
  Future<bool> deleteTask(String taskId) async {
    // Check if offline first
    final offlineService = _ref.read(offlineServiceProvider);
    if (offlineService.isOffline) {
      print('📴 [TasksProvider] Offline - queueing task delete operation');

      try {
        // Queue the operation for later sync
        await OfflineQueueService().queueOperation(
          QueuedOperation(
            id: 'task_delete_$taskId',
            type: OperationType.deleteTask,
            data: {'id': taskId},
            timestamp: DateTime.now(),
          ),
        );

        print('✅ [TasksProvider] Task delete queued successfully');
        return true;
      } catch (e) {
        print('❌ [TasksProvider] Failed to queue task delete: $e');
        state = state.copyWith(error: e.toString());
        return false;
      }
    }

    // Online - delete from Firebase first, THEN update UI
    try {
      print('🌐 [TasksProvider] Online - deleting task from Firebase...');
      final success = await _repository.deleteTask(taskId);

      if (success) {
        // Only update UI after confirmed delete
        final updatedTasks = state.tasks.where((t) => t.id != taskId).toList();
        final updatedFilteredTasks =
            state.filteredTasks.where((t) => t.id != taskId).toList();

        state = state.copyWith(
          tasks: updatedTasks,
          filteredTasks: updatedFilteredTasks,
        );

        print('✅ TasksProvider: Task deleted and UI updated');
      } else {
        print('❌ TasksProvider: Delete failed');
      }

      return success;
    } catch (e) {
      print('❌ TasksProvider: Delete error: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Mark task as completed - uses optimistic toggleTaskCompletion
  Future<bool> markTaskCompleted(String taskId) async {
    try {
      await toggleTaskCompletion(taskId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mark task as not completed - uses optimistic toggleTaskCompletion
  Future<bool> markTaskNotCompleted(String taskId) async {
    try {
      await toggleTaskCompletion(taskId);
      return true;
    } catch (e) {
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
        // Refresh based on current view context
        await _refreshCurrentView();
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
        // Refresh based on current view context
        await _refreshCurrentView();
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

  // Toggle task completion status with ARCHIVE concept
  // When completed → archive (remove from active tasks)
  // When uncompleted → restore from archive (if exists)
  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      // Get current user ID from repository/service
      final currentUserId = _repository.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Find the task in current state
      final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) {
        throw Exception('Task not found in local state');
      }

      final task = state.tasks[taskIndex];
      final isCurrentlyCompleted = task.completedBy.contains(currentUserId);

      if (isCurrentlyCompleted) {
        // Task is currently completed → UNCOMPLETE and restore from archive
        print(
          '🔄 TasksProvider: Uncompleting task - will remain in active tasks',
        );

        // Update completedBy array in Firebase
        await _repository.toggleTaskCompletion(taskId);

        // Refresh to get updated task
        await _refreshCurrentView();

        print('✅ TasksProvider: Task unmarked as completed');
      } else {
        // Task is NOT completed → COMPLETE and ARCHIVE
        print('📦 TasksProvider: Completing task - will archive');
        print('   Task ID: ${task.id}');
        print('   Task Title: ${task.title}');
        print('   Current completedBy: ${task.completedBy}');

        // OPTIMISTIC UPDATE: Remove from local state immediately
        final updatedTasks = state.tasks.where((t) => t.id != taskId).toList();
        final updatedFilteredTasks =
            state.filteredTasks.where((t) => t.id != taskId).toList();

        state = state.copyWith(
          tasks: updatedTasks,
          filteredTasks: updatedFilteredTasks,
        );

        print('✅ TasksProvider: Task removed from UI instantly');

        // Create task with completion status for archiving
        final taskWithCompletion = Task(
          id: task.id,
          title: task.title,
          description: task.description,
          dueDate: task.dueDate,
          importance: task.importance,
          completedBy: [...task.completedBy, currentUserId],
          sectionId: task.sectionId,
          subjectId: task.subjectId,
          assistantId: task.assistantId,
          isPersonal: task.isPersonal,
          attachments: task.attachments,
          notes: task.notes,
        );

        print(
          '   Updated completedBy for archive: ${taskWithCompletion.completedBy}',
        );

        // Archive the task (this will move it from tasks to archived_tasks)
        // The archiveTask method handles everything in one atomic operation
        try {
          final archived = await _repository.archiveTask(taskWithCompletion);
          if (archived) {
            print('✅ TasksProvider: Task archived successfully');
          } else {
            print('❌ TasksProvider: Failed to archive task');
            throw Exception('Failed to archive task');
          }
        } catch (archiveError) {
          print('❌ TasksProvider: Archive error - $archiveError');
          rethrow;
        }
      }
    } catch (e) {
      print('❌ TasksProvider: Toggle failed - $e');
      // Revert optimistic update by refreshing from server
      await _refreshCurrentView();
      state = state.copyWith(error: e.toString());
    }
  }

  // Archive a task manually (without toggling completion)
  Future<bool> archiveTask(Task task) async {
    try {
      // OPTIMISTIC UPDATE: Remove from local state immediately
      final updatedTasks = state.tasks.where((t) => t.id != task.id).toList();
      final updatedFilteredTasks =
          state.filteredTasks.where((t) => t.id != task.id).toList();

      state = state.copyWith(
        tasks: updatedTasks,
        filteredTasks: updatedFilteredTasks,
      );

      print('✅ TasksProvider: Task removed from UI for archiving');

      // Archive in Firebase
      final success = await _repository.archiveTask(task);

      if (!success) {
        // Revert if failed
        await _refreshCurrentView();
      }

      return success;
    } catch (e) {
      print('❌ TasksProvider: Archive failed - $e');
      await _refreshCurrentView();
      return false;
    }
  }

  // Get archived tasks
  Future<List<Task>> getArchivedTasks() async {
    try {
      return await _repository.getArchivedTasks();
    } catch (e) {
      print('❌ TasksProvider: Failed to get archived tasks - $e');
      return [];
    }
  }

  // Restore archived task
  Future<bool> restoreArchivedTask(String taskId) async {
    try {
      final success = await _repository.restoreArchivedTask(taskId);
      if (success) {
        // Refresh to show restored task
        await _refreshCurrentView();
      }
      return success;
    } catch (e) {
      print('❌ TasksProvider: Failed to restore archived task - $e');
      return false;
    }
  }

  // Delete archived task permanently
  Future<bool> deleteArchivedTask(String taskId) async {
    try {
      return await _repository.deleteArchivedTask(taskId);
    } catch (e) {
      print('❌ TasksProvider: Failed to delete archived task - $e');
      return false;
    }
  }

  // Clean up old archived tasks
  Future<bool> cleanupOldArchivedTasks({int daysToKeep = 30}) async {
    try {
      return await _repository.cleanupOldArchivedTasks(daysToKeep: daysToKeep);
    } catch (e) {
      print('❌ TasksProvider: Failed to cleanup archived tasks - $e');
      return false;
    }
  }

  // Background refresh - updates data without blocking UI
  Future<void> backgroundRefresh() async {
    try {
      // Only refresh if not currently loading to avoid conflicts
      if (!state.isLoading) {
        print('🔄 TasksProvider: Background refresh started');
        await getAllTasks();
        print('✅ TasksProvider: Background refresh completed');
      }
    } catch (e) {
      print('❌ TasksProvider: Background refresh failed - $e');
      // Don't update error state for background refresh failures
    }
  }

  // Check if data is stale and needs refresh
  bool get isDataStale {
    // Consider data stale if it's older than 5 minutes
    // This is a simple implementation - you could add timestamp tracking
    return state.tasks.isEmpty;
  }

  // Helper method to populate subject names for tasks that don't have them
  Future<List<Task>> _populateSubjectNames(List<Task> tasks) async {
    try {
      final subjectState = _ref.read(SubjectProviderProvider);
      final subjects = subjectState.allSubjects;

      if (subjects.isEmpty) {
        // If no subjects are loaded, return tasks as-is
        return tasks;
      }

      final updatedTasks = <Task>[];
      bool hasUpdates = false;

      for (final task in tasks) {
        if (task.subjectName == null && task.subjectId != null) {
          // Find the subject name for this task
          final subject = subjects.firstWhere(
            (s) => s.id == task.subjectId,
            orElse: () => throw Exception('Subject not found'),
          );

          // Create updated task with subject name
          final updatedTask = task.copyWith(subjectName: subject.name);
          updatedTasks.add(updatedTask);
          hasUpdates = true;
        } else {
          updatedTasks.add(task);
        }
      }

      // If we updated any tasks, save them back to the database
      if (hasUpdates) {
        for (final task in updatedTasks) {
          if (task.subjectName != null &&
              tasks.firstWhere((t) => t.id == task.id).subjectName == null) {
            try {
              await _repository.updateTask(task);
            } catch (e) {
              print(
                '⚠️ Failed to update task ${task.id} with subject name: $e',
              );
            }
          }
        }
      }

      return updatedTasks;
    } catch (e) {
      print('⚠️ Error populating subject names: $e');
      return tasks; // Return original tasks if there's an error
    }
  }

  // Reset provider state (called on logout/account switch)
  void resetState() {
    print('🗑️ TasksProvider: Resetting state');
    state = const TasksState();
  }
}

// ============================================================================
// MAIN TASKS PROVIDER - Permanent provider for user's tasks (used in week_tasks.dart)
// This provider should NEVER be modified when viewing specific assistant/subject tasks
// ============================================================================
final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  final repository = ref.watch(tasksRepositoryProvider);
  return TasksNotifier(repository, ref);
});

// ============================================================================
// VIEW TASKS PROVIDER - Temporary provider for viewing specific tasks
// Use this when viewing assistant tasks, subject tasks, or any filtered view
// This keeps the main tasksProvider clean and unmodified
// ============================================================================
final viewTasksProvider =
    StateNotifierProvider.autoDispose<TasksNotifier, TasksState>((ref) {
      final repository = ref.watch(tasksRepositoryProvider);
      return TasksNotifier(repository, ref);
    });

// Convenience providers for specific data from MAIN provider
final tasksListProvider = Provider<List<Task>>((ref) {
  final state = ref.watch(tasksProvider);
  return state.tasks;
});

final filteredTasksProvider = Provider<List<Task>>((ref) {
  final state = ref.watch(tasksProvider);
  return state.filteredTasks;
});

final taskStatisticsProvider = Provider<Map<String, dynamic>?>((ref) {
  final state = ref.watch(tasksProvider);
  return state.statistics;
});

final tasksSearchQueryProvider = Provider<String>((ref) {
  final state = ref.watch(tasksProvider);
  return state.searchQuery;
});

final tasksSelectedSectionProvider = Provider<String?>((ref) {
  final state = ref.watch(tasksProvider);
  return state.selectedSectionId;
});

final tasksSelectedSubjectProvider = Provider<String?>((ref) {
  final state = ref.watch(tasksProvider);
  return state.selectedSubjectId;
});

final tasksSelectedImportanceProvider = Provider<TaskImportance?>((ref) {
  final state = ref.watch(tasksProvider);
  return state.selectedImportance;
});

// Convenience providers for VIEW provider
final viewTasksListProvider = Provider.autoDispose<List<Task>>((ref) {
  final state = ref.watch(viewTasksProvider);
  return state.tasks;
});

final viewFilteredTasksProvider = Provider.autoDispose<List<Task>>((ref) {
  final state = ref.watch(viewTasksProvider);
  return state.filteredTasks;
});
