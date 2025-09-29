import 'package:pivot/features/tasks/services/tasks_service.dart';
import 'package:pivot/screens/models/task.dart';

class TasksRepository {
  final TasksService _tasksService;

  TasksRepository(this._tasksService);

  // Get all tasks for current user
  Future<List<Task>> getAllTasks() async {
    return await _tasksService.getAllTasks();
  }

  // Get tasks by section
  Future<List<Task>> getTasksBySection(String sectionId) async {
    return await _tasksService.getTasksBySection(sectionId);
  }

  // Get tasks by subject
  Future<List<Task>> getTasksBySubject(String subjectId) async {
    return await _tasksService.getTasksBySubject(subjectId);
  }

  // Get tasks by importance
  Future<List<Task>> getTasksByImportance(TaskImportance importance) async {
    return await _tasksService.getTasksByImportance(importance);
  }

  // Get personal tasks
  Future<List<Task>> getPersonalTasks() async {
    return await _tasksService.getPersonalTasks();
  }

  // Get completed tasks
  Future<List<Task>> getCompletedTasks() async {
    return await _tasksService.getCompletedTasks();
  }

  // Get pending tasks
  Future<List<Task>> getPendingTasks() async {
    return await _tasksService.getPendingTasks();
  }

  // Get overdue tasks
  Future<List<Task>> getOverdueTasks() async {
    return await _tasksService.getOverdueTasks();
  }

  // Get tasks due today
  Future<List<Task>> getTasksDueToday() async {
    return await _tasksService.getTasksDueToday();
  }

  // Add task
  Future<bool> addTask(Task task) async {
    return await _tasksService.addTask(task);
  }

  // Update task
  Future<bool> updateTask(Task task) async {
    return await _tasksService.updateTask(task);
  }

  // Delete task
  Future<bool> deleteTask(String taskId) async {
    return await _tasksService.deleteTask(taskId);
  }

  // Mark task as completed
  Future<bool> markTaskCompleted(String taskId) async {
    return await _tasksService.markTaskCompleted(taskId);
  }

  // Mark task as not completed
  Future<bool> markTaskNotCompleted(String taskId) async {
    return await _tasksService.markTaskNotCompleted(taskId);
  }

  // Search tasks
  Future<List<Task>> searchTasks(String query) async {
    return await _tasksService.searchTasks(query);
  }

  // Get task statistics
  Future<Map<String, dynamic>> getTaskStatistics() async {
    return await _tasksService.getTaskStatistics();
  }

  // Get tasks by date range
  Future<List<Task>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _tasksService.getTasksByDateRange(startDate, endDate);
  }

  // Bulk update tasks
  Future<bool> bulkUpdateTasks(List<Task> tasks) async {
    return await _tasksService.bulkUpdateTasks(tasks);
  }

  // Bulk delete tasks
  Future<bool> bulkDeleteTasks(List<String> taskIds) async {
    return await _tasksService.bulkDeleteTasks(taskIds);
  }
}
