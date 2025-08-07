import 'package:flutter/material.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/screens/models/task_model.dart';
import 'package:provider/provider.dart';
import 'package:pivot/responsive.dart';

import 'add_edit_task_dialog.dart';

class TasksControl extends StatefulWidget {
  // = 'tasks';
  const TasksControl({super.key});

  @override
  State<TasksControl> createState() => _TasksControlState();
}

class _TasksControlState extends State<TasksControl> {
  @override
  Widget build(BuildContext context) {
    final sectionId = ModalRoute.of(context)?.settings.arguments as String?;
    final taskProvider = Provider.of<TaskProvider>(context);
    final sectionProvider = Provider.of<SectionProvider>(context);
    final userProfile =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;

    final userRole = userProfile?.role ?? '';
    final canEdit =
        userRole == 'Super Admin' ||
        userRole == 'Admin' ||
        userRole == 'miniProfessor';

    String appBarTitle;
    if (sectionId != null) {
      try {
        final section = sectionProvider.sections.firstWhere(
          (s) => s.id == sectionId,
        );
        appBarTitle = section.name;
      } catch (e) {
        appBarTitle = 'Section Not Found';
      }
    } else {
      appBarTitle = 'All Tasks';
    }

    final tasks =
        sectionId != null
            ? taskProvider.tasksForSection(sectionId)
            : taskProvider.tasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        surfaceTintColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (tasks.isEmpty && !taskProvider.isLoading)
              Center(
                child: Text(
                  'لا توجد تاسكات حالياً',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey,
                  ),
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return TaskModel(
                    admin: canEdit,
                    task: task,
                    onEdit: () {
                      if (canEdit) {
                        _showAddEditTaskDialog(
                          context,
                          taskProvider,
                          task: task,
                        );
                      }
                    },
                    onDelete: () {
                      if (canEdit) {
                        taskProvider.deleteTask(task.id);
                      }
                    },
                    onStatusChanged: () {
                      taskProvider.toggleTaskCompletion(task.id);
                    },
                  );
                },
              ),
            if (taskProvider.isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      floatingActionButton:
          canEdit
              ? FloatingActionButton(
                heroTag: 'all_tasks_fab',
                onPressed: () => _showAddEditTaskDialog(context, taskProvider),
                backgroundColor: Colors.black,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  void _showAddEditTaskDialog(
    BuildContext context,
    TaskProvider taskProvider, {
    Task? task,
  }) {
    final bool isEditing = task != null;
    final sectionProvider = Provider.of<SectionProvider>(
      context,
      listen: false,
    );

    // Get sectionId from the task or from the current screen
    final sectionId =
        task?.sectionId ??
        ModalRoute.of(context)?.settings.arguments as String?;
    // Find the section and get its subjectId
    final subjectId =
        sectionId != null
            ? sectionProvider.sections
                .firstWhere((s) => s.id == sectionId)
                .subjectId
            : null;

    if (subjectId == null) {
      // Optionally show an error or return
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا يمكن تحديد المادة')));
      return;
    }

    showAddTaskDialog(
      context: context,
      task: task,
      subjectId: subjectId,
      initialSectionId: sectionId,
      onSave: (savedTask) async {
        try {
          if (isEditing) {
            await taskProvider.updateTask(savedTask.id, savedTask);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            await taskProvider.addTask(savedTask);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task added successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save task: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}
