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
            showAddTaskDialog(
              context: context,
              task: task,
              onSave: (updatedTask) async {
                try {
                  await taskProvider.updateTask(task.id, updatedTask);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update task: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            );
          },
          onDelete: () async {
            try {
              // Optional: Add a confirmation dialog here
              await taskProvider.deleteTask(task.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete task: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          onStatusChanged: () async {
            try {
              await taskProvider.toggleTaskCompletion(task.id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update task status: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      }, childCount: taskCount),
    ),
  ];
}
