import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/screens/models/task_model.dart';
import 'package:pivot/features/tasks/providers/tasks_provider.dart';

import 'add_edit_task_dialog.dart';
import 'package:pivot/responsive.dart';

class TasksControl extends ConsumerStatefulWidget {
  // = 'tasks';
  const TasksControl({super.key});

  @override
  ConsumerState<TasksControl> createState() => _TasksControlState();
}

class _TasksControlState extends ConsumerState<TasksControl> {
  @override
  void initState() {
    super.initState();
    // Load tasks when the screen is first loaded
    // Use viewTasksProvider to avoid polluting the main tasksProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionId = ModalRoute.of(context)?.settings.arguments as String?;
      if (sectionId != null) {
        ref.read(viewTasksProvider.notifier).getTasksBySection(sectionId);
      } else {
        ref.read(viewTasksProvider.notifier).getAllTasks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sectionId = ModalRoute.of(context)?.settings.arguments as String?;
    // Use viewTasksProvider for viewing specific section tasks
    final tasksState = ref.watch(viewTasksProvider);
    final sectionsState = ref.watch(sectionsProvider);
    final userProfileState = ref.watch(userProfileProvider);
    final userProfile = userProfileState.loggedInUserProfile;

    final userRole = userProfile?.role ?? '';
    final canEdit =
        userRole == 'Super Admin' ||
        userRole == 'Admin' ||
        userRole == 'miniProfessor';

    String appBarTitle;
    if (sectionId != null) {
      try {
        final section = sectionsState.sections.firstWhere(
          (s) => s.id == sectionId,
        );
        appBarTitle = section.name;
      } catch (e) {
        appBarTitle = 'Section Not Found';
      }
    } else {
      appBarTitle = 'All Tasks';
    }

    final tasks = tasksState.filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        surfaceTintColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (tasks.isEmpty && !tasksState.isLoading)
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
                        _showAddEditTaskDialog(context, task: task);
                      }
                    },
                    onDelete: () {
                      if (canEdit) {
                        // Use viewTasksProvider for this view
                        ref.read(viewTasksProvider.notifier).deleteTask(task.id);
                        // Also update main provider to keep it in sync
                        ref.read(tasksProvider.notifier).deleteTask(task.id);
                      }
                    },
                    onStatusChanged: () {
                      // Use viewTasksProvider for this view
                      ref
                          .read(viewTasksProvider.notifier)
                          .markTaskCompleted(task.id);
                      // Also update main provider to keep it in sync
                      ref
                          .read(tasksProvider.notifier)
                          .markTaskCompleted(task.id);
                    },
                  );
                },
              ),
            if (tasksState.isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      floatingActionButton:
          canEdit
              ? FloatingActionButton(
                heroTag: 'all_tasks_fab',
                onPressed: () => _showAddEditTaskDialog(context),
                backgroundColor: Colors.black,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  void _showAddEditTaskDialog(BuildContext context, {Task? task}) {
    final bool isEditing = task != null;
    final sectionsState = ref.read(sectionsProvider);

    // Get sectionId from the task or from the current screen
    final sectionId =
        task?.sectionId ??
        ModalRoute.of(context)?.settings.arguments as String?;
    // Find the section and get its subjectId
    final subjectId =
        sectionId != null
            ? sectionsState.sections
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
            // Update in both providers to keep them in sync
            await ref.read(viewTasksProvider.notifier).updateTask(savedTask);
            await ref.read(tasksProvider.notifier).updateTask(savedTask);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            // Add to both providers to keep them in sync
            await ref.read(viewTasksProvider.notifier).addTask(savedTask);
            await ref.read(tasksProvider.notifier).addTask(savedTask);
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
