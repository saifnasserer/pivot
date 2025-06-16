import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/models/task_model.dart';
import 'add_edit_task_dialog.dart'; // Import the dialog
import 'package:provider/provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/section_provider.dart';

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

    // Access providers
    final taskProvider = Provider.of<TaskProvider>(context);
    final sectionProvider = Provider.of<SectionProvider>(context);

    // Determine the AppBar title
    String appBarTitle;
    if (sectionId != null) {
      try {
        final section = sectionProvider.sections.firstWhere((s) => s.id == sectionId);
        appBarTitle = section.name;
      } catch (e) {
        appBarTitle = 'Section Not Found'; // Fallback title
      }
    } else {
      appBarTitle = 'All Tasks';
    }

    // Get tasks for the current section
    final tasks =
        sectionId != null ? taskProvider.tasksForSection(sectionId) : taskProvider.tasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
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
                                onSave: (updatedTask) async {
                                  try {
                                    await taskProvider.updateTask(task.id, updatedTask);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Task updated successfully!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
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
                                await taskProvider.deleteTask(task.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Task deleted successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
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
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update task status: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
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
                  showAddTaskDialog(
                    context: context,
                    onSave: (newTask) async {
                      try {
                        await taskProvider.addTask(newTask);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add task: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  );
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
