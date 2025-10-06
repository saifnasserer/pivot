import 'package:pivot/features/tasks/services/task_service.dart';
import 'package:pivot/screens/models/task.dart';

class TaskRepository {
  TaskRepository(this._service);

  final TaskService _service;

  Future<List<Task>> fetchTasks({bool force = false}) =>
      _service.fetchTasks(force: force);

  Future<void> addTask(Task task) => _service.addTask(task);

  Future<void> updateTask(String id, Task task) =>
      _service.updateTask(id, task);

  Future<void> deleteTask(String id) => _service.deleteTask(id);

  Future<void> toggleTaskCompletion(String id) =>
      _service.toggleTaskCompletion(id);

  Future<void> setTaskPriority(String id, TaskImportance importance) =>
      _service.setTaskPriority(id, importance);

  Future<void> setTaskDueDate(String id, DateTime? dueDate) =>
      _service.setTaskDueDate(id, dueDate);

  Future<List<TaskNote>> getTaskNotes(String taskId) =>
      _service.getTaskNotes(taskId);

  Future<void> addTaskNote(String id, String note) =>
      _service.addTaskNote(id, note);

  Future<void> deleteTaskNote(String id, String noteId) =>
      _service.deleteTaskNote(id, noteId);

  Future<void> scheduleTaskReminder(String id, DateTime reminderTime) =>
      _service.scheduleTaskReminder(id, reminderTime);

  Future<void> cancelTaskReminder(String id) => _service.cancelTaskReminder(id);
}
