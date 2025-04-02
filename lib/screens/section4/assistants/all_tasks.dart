import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/models/task_model.dart';
import 'add_edit_task_dialog.dart'; // Import the dialog
import 'package:provider/provider.dart';
import 'package:pivot/providers/task_provider.dart';

class TasksControl extends StatefulWidget {
  static const String id = 'tasks'; // Define route name
  const TasksControl({super.key});

  @override
  State<TasksControl> createState() => _TasksControlState();
}

class _TasksControlState extends State<TasksControl> {
  @override
  Widget build(BuildContext context) {
    // Get sectionId from arguments
    final sectionId = ModalRoute.of(context)?.settings.arguments as String?;

    // Access the task provider
    final taskProvider = Provider.of<TaskProvider>(context);

    // Get tasks for the current section (or show all if sectionId is null - handle as needed)
    final tasks =
        sectionId != null
            ? taskProvider.tasksForSection(sectionId)
            : taskProvider.tasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(sectionId ?? 'All Tasks'),
        surfaceTintColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: Responsive.padding(context, size: Space.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AutoSizeText(
                    'بشمهندسة الشيماء',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: Responsive.text(
                      context,
                      size: TextSize.medium,
                    ),
                    style: TextStyle(
                      fontSize: Responsive.text(
                        context,
                        size: TextSize.heading,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // List of tasks
                  Expanded(
                    child: ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index]; // Get the current task
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                          ),
                          child: TaskModel(
                            admin: true,
                            task: task,
                            onEdit: () {
                              showAddTaskDialog(
                                context: context,
                                task: task, // Pass the task to edit
                                sectionId:
                                    sectionId ??
                                    task.sectionId, // Pass sectionId
                                onSave: (updatedTask) {
                                  taskProvider.updateTask(task.id, updatedTask);
                                },
                              );
                            },
                            onDelete: () {
                              // TODO: Add confirmation dialog?
                              taskProvider.deleteTask(task.id);
                            },
                            onStatusChanged: (isCompleted) {
                              taskProvider.toggleTaskCompletion(task.id);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: Responsive.space(context),
              child: CircularButton(
                onPressed: () {
                  if (sectionId != null) {
                    showAddTaskDialog(
                      context: context,
                      sectionId: sectionId,
                      onSave: (newTask) {
                        taskProvider.addTask(newTask);
                      },
                    );
                  } else {
                    // Handle case where sectionId is null (e.g., show error or allow selecting section)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cannot add task without a section ID.'),
                      ),
                    );
                  }
                },
                icon: Icons.add_rounded,
                iconSizeMultiplier: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
