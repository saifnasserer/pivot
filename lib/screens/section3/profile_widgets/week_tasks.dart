import 'package:flutter/material.dart';
import 'package:pivot/screens/models/task_model.dart';
import 'package:pivot/screens/models/task.dart'; // Import Task model
import 'package:pivot/providers/task_provider.dart'; // Import TaskProvider
import 'package:pivot/screens/section4/assistants/add_edit_task_dialog.dart'; // Import the dialog

// --- Refactored Function returning Slivers ---
List<Widget> buildWeekTasksSlivers(
  BuildContext context,
  List<Task> tasks, // Accept the list of tasks
  TaskProvider taskProvider, // Accept the provider instance
) {
  final int taskCount = tasks.length;

  if (taskCount == 0) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('مفيش تاسكات الاسبوع ده')),
      ),
    ];
  }

  return [
    SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final task = tasks[index]; // Use the passed tasks list
        return TaskModel(
          task: task,
          onEdit: () {
            // Use the actual dialog to edit via provider
            showAddTaskDialog(
              context: context,
              task: task,
              sectionId: task.sectionId, // Use task's existing sectionId
              onSave: (updatedTask) {
                taskProvider.updateTask(task.id, updatedTask);
              },
            );
          },
          onDelete: () {
            // TODO: Add confirmation dialog?
            taskProvider.deleteTask(task.id); // Delete via provider
          },
          onStatusChanged: (isCompleted) {
            // Toggle completion via provider
            taskProvider.toggleTaskCompletion(task.id);
          },
        );
      }, childCount: taskCount),
    ),
  ];
}
