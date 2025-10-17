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

import 'add_edit_task_screen.dart';
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
      _wasOffline = ref.read(offlineServiceProvider).isOffline;
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

    // Refresh tasks - only refresh the view provider to avoid double operations
    if (mounted) {
      if (sectionId != null) {
        await ref.read(viewTasksProvider.notifier).getTasksBySection(sectionId);
      } else {
        await ref.read(viewTasksProvider.notifier).getAllTasks();
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

    // Watch connectivity status only when needed
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    // Refresh tasks when coming back online (only once per transition)
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

    // Use read for providers that don't need to trigger rebuilds
    final sectionsState = ref.read(sectionsProvider);
    final userProfileState = ref.read(userProfileProvider);
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
                      // Only update the view provider since this is a view-specific action
                      ref
                          .read(viewTasksProvider.notifier)
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
      final offlineService = ref.read(offlineServiceProvider);
      final isOffline = offlineService.isOffline;
      final sectionId = ModalRoute.of(context)?.settings.arguments as String?;

      try {
        // Capture provider references before any async operations
        // This prevents "ref disposed" errors
        final viewTasksNotifier = ref.read(viewTasksProvider.notifier);
        final currentContext = context;

        // Use viewTasksProvider for this view
        final success = await viewTasksNotifier.deleteTask(task.id);

        // Only refresh if the delete was successful and we're online
        if (!isOffline && success && mounted) {
          print('🔄 Refreshing tasks after online delete...');
          if (sectionId != null) {
            await viewTasksNotifier.getTasksBySection(sectionId);
          } else {
            await viewTasksNotifier.getAllTasks();
          }
        }

        if (mounted && success) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
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

    showAddTaskScreen(
      context: context,
      task: task,
      subjectId: subjectId,
      initialSectionId: sectionId,
      onSave: (savedTask) async {
        // The screen handles the save internally, so we don't need to refresh here
        // The viewTasksProvider will automatically update when the screen saves
        // This prevents unnecessary refresh calls
      },
    );
  }
}
