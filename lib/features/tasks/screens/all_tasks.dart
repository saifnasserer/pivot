import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/screens/models/task_model.dart';
import 'package:pivot/features/tasks/providers/tasks_provider.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/services/sync_manager.dart';

import 'add_edit_task_dialog.dart';
import 'package:pivot/responsive.dart';

class TasksControl extends ConsumerStatefulWidget {
  // = 'tasks';
  const TasksControl({super.key});

  @override
  ConsumerState<TasksControl> createState() => _TasksControlState();
}

class _TasksControlState extends ConsumerState<TasksControl> {
  bool _wasOffline = false;

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

      // Initialize offline state
      _wasOffline = OfflineService().isOffline;
    });
  }

  /// Wait for sync to complete, then refresh tasks
  Future<void> _waitForSyncAndRefresh(String? sectionId) async {
    final syncManager = ref.read(syncManagerProvider);

    print('🔍 Checking if sync is in progress...');

    // Wait up to 10 seconds for sync to complete
    int attempts = 0;
    const maxAttempts = 20; // 20 * 500ms = 10 seconds

    while (syncManager.isSyncing && attempts < maxAttempts) {
      print(
        '⏳ Sync still in progress, waiting... (attempt ${attempts + 1}/$maxAttempts)',
      );
      await Future.delayed(Duration(milliseconds: 500));
      attempts++;
    }

    if (syncManager.isSyncing) {
      print('⚠️ Sync timeout - refreshing anyway after 10 seconds');
    } else {
      print('✅ Sync completed! Refreshing tasks...');
    }

    // Refresh tasks
    if (mounted) {
      if (sectionId != null) {
        await ref.read(viewTasksProvider.notifier).getTasksBySection(sectionId);
        await ref.read(tasksProvider.notifier).getTasksBySection(sectionId);
      } else {
        await ref.read(viewTasksProvider.notifier).getAllTasks();
        await ref.read(tasksProvider.notifier).getAllTasks();
      }
      print('✅ [TasksControl] Tasks refreshed after sync');

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text('تم تحديث التاسكات بنجاح ✓')),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionId = ModalRoute.of(context)?.settings.arguments as String?;

    // Watch connectivity status
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    // Refresh tasks when coming back online
    connectivityStatus.whenData((isOnline) {
      if (_wasOffline && isOnline) {
        print(
          '🔄 [TasksControl] Back online - waiting for sync to complete...',
        );

        // Show snackbar immediately
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text('تم استعادة الاتصال. جاري مزامنة التاسكات...'),
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Wait for sync to complete by checking every 500ms
        _waitForSyncAndRefresh(sectionId);
      }
      _wasOffline = !isOnline;
    });

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
                        _showDeleteConfirmation(context, task);
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

  Future<void> _showDeleteConfirmation(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => UnifiedDialog(
            title: 'حذف التاسك',
            subtitle: 'التاسك هيتم حذفة من هنا ومن عند كل الطلاب ، متأكد؟',
            content: Padding(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.space(context, size: Space.small),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  if (task.description.isNotEmpty) ...[
                    SizedBox(
                      height: Responsive.space(context, size: Space.tiny),
                    ),
                    Text(
                      task.description,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            confirmText: 'حذف',
            confirmIcon: Icons.delete,
            cancelText: 'إلغاء',
            onCancel: () => Navigator.of(context).pop(false),
            onConfirm: () => Navigator.of(context).pop(true),
          ),
    );

    if (confirmed == true && mounted) {
      final offlineService = OfflineService();
      final isOffline = offlineService.isOffline;
      final sectionId = ModalRoute.of(context)?.settings.arguments as String?;

      try {
        // Use viewTasksProvider for this view
        final success1 = await ref
            .read(viewTasksProvider.notifier)
            .deleteTask(task.id);
        // Also update main provider to keep them in sync
        final success2 = await ref
            .read(tasksProvider.notifier)
            .deleteTask(task.id);

        // Refresh list if online and successful to remove the deleted task
        if (!isOffline && (success1 || success2) && mounted) {
          print('🔄 Refreshing tasks after online delete...');
          if (sectionId != null) {
            await ref
                .read(viewTasksProvider.notifier)
                .getTasksBySection(sectionId);
          } else {
            await ref.read(viewTasksProvider.notifier).getAllTasks();
          }
        }

        if (mounted && (success1 || success2)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text(
                  isOffline
                      ? 'تم حفظ الحذف في قائمة الانتظار. سيتم الحذف عند الاتصال.'
                      : 'تم حذف التاسك بنجاح',
                ),
              ),
              backgroundColor: isOffline ? Colors.orange : Colors.green,
              duration: Duration(seconds: isOffline ? 4 : 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = e.toString();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(child: Text('حدث خطأ: $errorMessage')),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(child: Text('لا يمكن تحديد المادة'))),
      );
      return;
    }

    showAddTaskDialog(
      context: context,
      task: task,
      subjectId: subjectId,
      initialSectionId: sectionId,
      onSave: (savedTask) async {
        print('🎬 [AllTasks.onSave] Callback triggered');
        print('   Task ID: ${savedTask.id}');
        print('   Task Title: ${savedTask.title}');
        print('   Is Editing: $isEditing');

        final offlineService = OfflineService();
        final isOffline = offlineService.isOffline;
        print('   Is Offline: $isOffline');

        try {
          if (isEditing) {
            print('   📝 Updating existing task...');
            // Update in both providers to keep them in sync
            final success1 = await ref
                .read(viewTasksProvider.notifier)
                .updateTask(savedTask);
            print('   viewTasksProvider.updateTask returned: $success1');

            final success2 = await ref
                .read(tasksProvider.notifier)
                .updateTask(savedTask);
            print('   tasksProvider.updateTask returned: $success2');

            // Refresh list if online and successful
            if (!isOffline && (success1 || success2) && mounted) {
              print('🔄 Refreshing tasks after online update...');
              if (sectionId != null) {
                await ref
                    .read(viewTasksProvider.notifier)
                    .getTasksBySection(sectionId);
              } else {
                await ref.read(viewTasksProvider.notifier).getAllTasks();
              }
              print('✅ Refresh completed');
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Center(
                    child: Text(
                      isOffline
                          ? 'تم حفظ التاسك في قائمة الانتظار. سيتم إرسالها عند الاتصال.'
                          : 'تم تحديث التاسك بنجاح!',
                    ),
                  ),
                  backgroundColor: isOffline ? Colors.orange : Colors.green,
                  duration: Duration(seconds: isOffline ? 4 : 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            print('   ➕ Adding new task...');
            // Add to both providers to keep them in sync
            final success1 = await ref
                .read(viewTasksProvider.notifier)
                .addTask(savedTask);
            print('   viewTasksProvider.addTask returned: $success1');

            final success2 = await ref
                .read(tasksProvider.notifier)
                .addTask(savedTask);
            print('   tasksProvider.addTask returned: $success2');

            // Refresh list if online and successful to show the newly added task
            if (!isOffline && (success1 || success2) && mounted) {
              print('🔄 Refreshing tasks after online add...');
              print('   Section ID: $sectionId');
              print('   Mounted: $mounted');

              if (sectionId != null) {
                print('   Calling getTasksBySection($sectionId)...');
                await ref
                    .read(viewTasksProvider.notifier)
                    .getTasksBySection(sectionId);
              } else {
                print('   Calling getAllTasks()...');
                await ref.read(viewTasksProvider.notifier).getAllTasks();
              }
              print('✅ Refresh completed');
            } else {
              print('⚠️ Skipping refresh:');
              print('   isOffline: $isOffline');
              print('   success1 || success2: ${success1 || success2}');
              print('   mounted: $mounted');
            }

            if (mounted) {
              print('   Showing snackbar...');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Center(
                    child: Text(
                      isOffline
                          ? 'تم حفظ التاسك في قائمة الانتظار. سيتم إضافتها عند الاتصال.'
                          : 'تم اضافة التاسك بنجاح!',
                    ),
                  ),
                  backgroundColor: isOffline ? Colors.orange : Colors.green,
                  duration: Duration(seconds: isOffline ? 4 : 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          print('✅ [AllTasks.onSave] Completed successfully');
        } catch (e) {
          print('❌ [AllTasks.onSave] Error: $e');
          print('   Stack trace: ${StackTrace.current}');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Center(child: Text('فشل حفظ التاسك: $e')),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );
  }
}
