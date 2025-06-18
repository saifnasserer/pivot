import 'package:flutter/material.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/screens/models/task_model.dart';
import 'package:provider/provider.dart';

import 'add_edit_task_dialog.dart';

class WeekTasks extends StatefulWidget {
  const WeekTasks({super.key});

  @override
  State<WeekTasks> createState() => _WeekTasksState();
}

class _WeekTasksState extends State<WeekTasks> {
  bool _isCompletedTasksExpanded = false;
  List<Task> _personalTasks = [];

  void _showAddEditTaskDialog(BuildContext context, {Task? task}) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (_) => AddEditTaskDialog(task: task, isPersonal: true),
    );

    if (result != null) {
      setState(() {
        if (task == null) {
          _personalTasks.add(result);
        } else {
          final index = _personalTasks.indexWhere((t) => t.id == result.id);
          if (index != -1) {
            _personalTasks[index] = result;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final sectionProvider = Provider.of<SectionProvider>(context);
    final userProfile = userProfileProvider.userProfile;
    final allTasks = [...taskProvider.tasks, ..._personalTasks];

    final userEnrolledSubjectIds = userProfile?.enrolledSubjects ?? [];
    final relevantSectionIds =
        sectionProvider.sections
            .where(
              (section) => userEnrolledSubjectIds.contains(section.subjectId),
            )
            .map((section) => section.id)
            .toSet();

    final filteredTasks =
        allTasks.where((task) {
          if (task.isPersonal) return true;
          return relevantSectionIds.contains(task.sectionId);
        }).toList();

    final userId = userProfile?.id;
    final pendingTasks =
        filteredTasks
            .where((t) => userId == null || !t.isCompletedFor(userId))
            .toList();
    final initialCompletedTasks =
        filteredTasks
            .where((t) => userId != null && t.isCompletedFor(userId))
            .toList();

    final now = DateTime.now();
    final completedTasks =
        initialCompletedTasks
            .where((task) => !task.dueDate.isBefore(now))
            .toList();

    final importanceOrder = {
      TaskImportance.high: 0,
      TaskImportance.mid: 1,
      TaskImportance.low: 2,
    };

    void sortTasks(List<Task> tasks) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      tasks.sort((a, b) {
        final aDueDate = DateTime(
          a.dueDate.year,
          a.dueDate.month,
          a.dueDate.day,
        );
        final bDueDate = DateTime(
          b.dueDate.year,
          b.dueDate.month,
          b.dueDate.day,
        );

        final aIsOverdue = aDueDate.isBefore(today);
        final bIsOverdue = bDueDate.isBefore(today);

        if (aIsOverdue && !bIsOverdue) return -1;
        if (!aIsOverdue && bIsOverdue) return 1;

        final aIsDueTomorrow = aDueDate.isAtSameMomentAs(tomorrow);
        final bIsDueTomorrow = bDueDate.isAtSameMomentAs(tomorrow);

        if (aIsDueTomorrow && !bIsDueTomorrow) return -1;
        if (!aIsDueTomorrow && bIsDueTomorrow) return 1;

        final importanceCompare = (importanceOrder[a.importance] ?? 2)
            .compareTo(importanceOrder[b.importance] ?? 2);
        if (importanceCompare != 0) return importanceCompare;

        return a.dueDate.compareTo(b.dueDate);
      });
    }

    sortTasks(pendingTasks);
    sortTasks(completedTasks);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          if (pendingTasks.isEmpty && completedTasks.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('لا توجد مهام هذا الأسبوع')),
            )
          else ...[
            _buildTaskList(context, pendingTasks, taskProvider),
            if (completedTasks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.medium),
                    vertical: Responsive.space(context, size: Space.small),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.medium),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.medium),
                      ),
                      child: Material(
                        color: Colors.white,
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(
                              horizontal: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                              vertical: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            collapsedBackgroundColor: Colors.white,
                            title: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                                vertical: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              child: Text(
                                'التسكات اللي خلصت',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: Responsive.space(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            initiallyExpanded: _isCompletedTasksExpanded,
                            onExpansionChanged: (isExpanded) {
                              setState(() {
                                _isCompletedTasksExpanded = isExpanded;
                              });
                            },
                            children:
                                completedTasks.map((task) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          task == completedTasks.last
                                              ? Responsive.space(
                                                context,
                                                size: Space.small,
                                              )
                                              : 0,
                                    ),
                                    child: TaskModel(
                                      task: task,
                                      admin: false,
                                      onStatusChanged: () {
                                        if (task.isPersonal) {
                                          final user =
                                              Provider.of<UserProfileProvider>(
                                                context,
                                                listen: false,
                                              ).userProfile;
                                          if (user == null) return;

                                          final newCompletedBy =
                                              List<String>.from(
                                                task.completedBy,
                                              );
                                          if (task.isCompletedFor(user.id)) {
                                            newCompletedBy.remove(user.id);
                                          } else {
                                            newCompletedBy.add(user.id);
                                          }

                                          final updatedTask = task.copyWith(
                                            completedBy: newCompletedBy,
                                          );

                                          setState(() {
                                            final taskIndex = _personalTasks
                                                .indexWhere(
                                                  (t) => t.id == updatedTask.id,
                                                );
                                            if (taskIndex != -1) {
                                              _personalTasks[taskIndex] =
                                                  updatedTask;
                                            }
                                          });
                                        } else {
                                          taskProvider.toggleTaskCompletion(
                                            task.id,
                                          );
                                        }
                                      },
                                      onEdit:
                                          () => _showAddEditTaskDialog(
                                            context,
                                            task: task,
                                          ),
                                      onDelete: () {
                                        if (task.isPersonal) {
                                          setState(() {
                                            _personalTasks.removeWhere(
                                              (t) => t.id == task.id,
                                            );
                                          });
                                        } else {
                                          taskProvider.deleteTask(task.id);
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditTaskDialog(context),
        label: const Text('اضافة تاسك'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.black,
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    List<Task> tasks,
    TaskProvider taskProvider,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final task = tasks[index];
        return TaskModel(
          task: task,
          admin: false, // Personal tasks are not admin-editable from this view
          onStatusChanged: () {
            if (task.isPersonal) {
              final user =
                  Provider.of<UserProfileProvider>(
                    context,
                    listen: false,
                  ).userProfile;
              if (user == null) return;

              final newCompletedBy = List<String>.from(task.completedBy);
              if (task.isCompletedFor(user.id)) {
                newCompletedBy.remove(user.id);
              } else {
                newCompletedBy.add(user.id);
              }

              final updatedTask = task.copyWith(completedBy: newCompletedBy);

              setState(() {
                final taskIndex = _personalTasks.indexWhere(
                  (t) => t.id == updatedTask.id,
                );
                if (taskIndex != -1) {
                  _personalTasks[taskIndex] = updatedTask;
                }
              });
            } else {
              taskProvider.toggleTaskCompletion(task.id);
            }
          },
          onEdit: () => _showAddEditTaskDialog(context, task: task),
          onDelete: () {
            if (task.isPersonal) {
              setState(() {
                _personalTasks.removeWhere((t) => t.id == task.id);
              });
            } else {
              taskProvider.deleteTask(task.id);
            }
          },
        );
      }, childCount: tasks.length),
    );
  }
}
