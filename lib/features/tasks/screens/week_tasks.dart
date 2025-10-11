import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/subjects/providers/subjects_provider.dart';
import 'package:pivot/features/tasks/providers/tasks_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/screens/models/task_model.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'add_personal_task_dialog.dart';

import 'package:pivot/services/sound_service.dart';
import 'package:pivot/services/data_preloader_service.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/features/home/screens/adminstration/animated_route.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'archived_tasks_screen.dart';

/// Enhanced WeekTasks with analytics, smart organization, and modern UI
class WeekTasks extends ConsumerStatefulWidget {
  const WeekTasks({super.key});

  @override
  ConsumerState<WeekTasks> createState() => _WeekTasksState();
}

class _WeekTasksState extends ConsumerState<WeekTasks>
    with TickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _listAnimation;

  // Note: New task notifications are now handled in task_provider.dart when tasks are actually created

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressAnimationController.forward();
      _listAnimationController.forward();

      // Initialize providers with user profile using smart loading
      final userProfileState = ref.read(userProfileProvider);
      final loggedInUser = userProfileState.loggedInUserProfile;
      if (loggedInUser != null) {
        _initializeDataSmart(loggedInUser);

        // Trigger background refresh to keep data fresh
        DataPreloaderService.backgroundRefresh(ref);
      }
    });
  }

  /// Smart data initialization - uses local-first approach with cache
  /// Providers now load from cache automatically, so we only fetch if cache is empty
  void _initializeDataSmart(UserProfile user) {
    final subjectsState = ref.read(subjectsProvider);
    final sectionsState = ref.read(sectionsProvider);
    final tasksState = ref.read(tasksProvider);
    final offlineService = ref.read(offlineServiceProvider);

    // Ensure the main tasks provider has ALL tasks (not filtered by section/subject)
    // The viewTasksProvider is used for viewing specific filtered tasks in other screens
    final hasFiltersSet = tasksState.selectedSectionId != null || 
                          tasksState.selectedSubjectId != null;
    
    if (hasFiltersSet) {
      print('🔄 WeekTasks: Main provider has filters set - reloading all tasks');
      // Reload all tasks to ensure we have the complete list
      ref.read(tasksProvider.notifier).getAllTasks();
      return; // Return early since getAllTasks will load the data
    }

    // Check if we have cached data
    final hasSubjects = subjectsState.filteredSubjects.isNotEmpty;
    final hasSections = sectionsState.sections.isNotEmpty;
    final hasTasks = tasksState.tasks.isNotEmpty;

    if (hasSubjects && hasSections && hasTasks) {
      print(
        '✅ WeekTasks: Using cached data (S:${subjectsState.filteredSubjects.length}, Sec:${sectionsState.sections.length}, T:${tasksState.tasks.length}) - Zero server reads',
      );
      return;
    }

    // Only fetch missing data if we're online
    if (!offlineService.hasConnection) {
      print('📡 WeekTasks: Offline - using available cached data');
      return;
    }

    // Fetch missing data (providers will check cache first)
    final fetchFutures = <Future>[];

    if (!hasSubjects && !subjectsState.isLoading) {
      print('📦 WeekTasks: Fetching subjects...');
      fetchFutures.add(
        ref.read(subjectsProvider.notifier).fetchAndFilterSubjects(user),
      );
    }

    if (!hasSections &&
        !sectionsState.isLoading &&
        user.enrolledSubjects.isNotEmpty) {
      print('📦 WeekTasks: Fetching sections...');
      fetchFutures.add(
        ref
            .read(sectionsProvider.notifier)
            .loadSectionsForUser(user.id, user.enrolledSubjects),
      );
    }

    if (!hasTasks && !tasksState.isLoading) {
      print('📦 WeekTasks: Fetching all tasks...');
      fetchFutures.add(ref.read(tasksProvider.notifier).getAllTasks());
    }

    if (fetchFutures.isNotEmpty) {
      Future.wait(fetchFutures).catchError((error) {
        print('❌ WeekTasks: Fetch error - $error');
        return <dynamic>[];
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update assistant preferences when dependencies change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateAssistantPreferencesIfNeeded();
      }
    });
  }

  // Method to trigger assistant preferences update when user profile changes
  void _checkAndUpdateAssistantPreferences() {
    final userProfileState = ref.read(userProfileProvider);
    final subjectsState = ref.read(subjectsProvider);

    // Only run if both providers are ready
    if (!subjectsState.isLoading &&
        userProfileState.loggedInUserProfile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateAssistantPreferencesIfNeeded();
        }
      });
    }
  }

  void _updateAssistantPreferencesIfNeeded() async {
    try {
      final userProfileState = ref.read(userProfileProvider);
      final subjectsState = ref.read(subjectsProvider);
      final loggedInUser = userProfileState.loggedInUserProfile;

      // Silently return if profile is still loading (this is expected during login)
      if (loggedInUser == null) {
        return;
      }

      // Check if subject provider is ready
      if (subjectsState.isLoading) {
        print(
          'WeekTasks: Subject provider is still loading, skipping assistant preferences update',
        );
        return;
      }

      final userEnrolledSubjectIds = loggedInUser.enrolledSubjects;
      final assistantPreferences = loggedInUser.assistantPreferences;
      final updatedPreferences = <String, String>{...assistantPreferences};

      bool hasChanges = false;

      for (final subjectId in userEnrolledSubjectIds) {
        final instructors =
            subjectsState.instructorsBySubject[subjectId]
                ?.where((prof) => prof.role == 'miniProfessor')
                .toList() ??
            [];

        if (instructors.length == 1 &&
            !assistantPreferences.containsKey(subjectId)) {
          // Auto-select if only one instructor and no preference set
          final selectedAssistantId = instructors.first.id;
          updatedPreferences[subjectId] = selectedAssistantId;
          hasChanges = true;
          print(
            '🎯 WeekTasks: Auto-selected assistant for ${instructors.first.name}',
          );
        }
      }

      // Only update if there are changes
      if (hasChanges) {
        await ref
            .read(userProfileProvider.notifier)
            .updateAssistantPreferences(updatedPreferences);
        print('✅ WeekTasks: Updated assistant preferences');
      }
    } catch (e) {
      print('WeekTasks: Failed to update assistant preferences: $e');
    }
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  void _showAddEditTaskDialog(BuildContext context, {Task? task}) async {
    await showAddPersonalTaskDialog(
      context: context,
      task: task,
      onSave: (savedTask) async {
        // ✅ Personal tasks are saved to Firebase at: users/{userId}/tasks/{taskId}
        // This ensures tasks are tied to the logged-in user's account
        // When logging out and switching accounts, old tasks are cleared
        // and only the new user's tasks are fetched
        try {
          final success = await ref
              .read(tasksProvider.notifier)
              .addTask(savedTask);
          if (success) {
            print('✅ WeekTasks: Personal task saved to cloud successfully');
            // Refresh tasks to get updated list from cloud
            await ref.read(tasksProvider.notifier).getAllTasks();
          } else {
            print('❌ WeekTasks: Failed to save personal task to cloud');
          }
        } catch (e) {
          print('❌ WeekTasks: Error saving personal task - $e');
        }
      },
    );
  }

  /// Group tasks by priority and due date
  Map<String, List<Task>> _groupTasks(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final grouped = <String, List<Task>>{};

    for (final task in tasks) {
      final taskDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );

      String category;
      if (taskDate.isBefore(today)) {
        category = 'overdue';
      } else if (taskDate.isAtSameMomentAs(today)) {
        category = 'today';
      } else if (taskDate.isAtSameMomentAs(tomorrow)) {
        category = 'tomorrow';
      } else if (taskDate.isBefore(weekEnd)) {
        category = 'thisWeek';
      } else {
        category = 'later';
      }

      grouped.putIfAbsent(category, () => []).add(task);
    }

    // Sort tasks within each category by importance and due date
    for (final category in grouped.keys) {
      grouped[category]!.sort((a, b) {
        final importanceOrder = {
          TaskImportance.high: 0,
          TaskImportance.mid: 1,
          TaskImportance.low: 2,
        };

        final importanceCompare = (importanceOrder[a.importance] ?? 2)
            .compareTo(importanceOrder[b.importance] ?? 2);
        if (importanceCompare != 0) return importanceCompare;

        return a.dueDate.compareTo(b.dueDate);
      });
    }

    return grouped;
  }

  /// Check for subjects that need assistant selection
  List<String> _getSubjectsNeedingAssistantSelection(
    List<String> userEnrolledSubjectIds,
    Map<String, String> assistantPreferences,
    Map<String, List<UserProfile>> instructorsBySubject,
  ) {
    final subjectsNeedingSelection = <String>[];

    for (final subjectId in userEnrolledSubjectIds) {
      // Get instructors for this subject
      final instructors =
          instructorsBySubject[subjectId]
              ?.where((prof) => prof.role == 'miniProfessor')
              .toList() ??
          [];

      // Show warning if there are instructors but no default assistant selected
      if (instructors.length > 1 &&
          !assistantPreferences.containsKey(subjectId)) {
        subjectsNeedingSelection.add(subjectId);
      }
    }
    return subjectsNeedingSelection;
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final userProfileState = ref.watch(userProfileProvider);
    final sectionsState = ref.watch(sectionsProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final offlineService = ref.watch(offlineServiceProvider);

    // Listen for when user profile loads
    ref.listen<UserProfileState>(userProfileProvider, (previous, next) {
      // When profile becomes available (was null, now has value)
      if (previous?.loggedInUserProfile == null &&
          next.loggedInUserProfile != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final loggedInUser = next.loggedInUserProfile!;

            // Providers now load from cache automatically on startup
            // We only need to fetch if cache is empty (handled by _initializeDataSmart)
            _initializeDataSmart(loggedInUser);

            // Update assistant preferences
            _updateAssistantPreferencesIfNeeded();
          }
        });
      }
    });

    final loggedInUser = userProfileState.loggedInUserProfile;
    final allTasks =
        tasksState
            .tasks; // All tasks now come from cloud (including personal tasks)

    // Check and update assistant preferences when build is called
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndUpdateAssistantPreferences();
      }
    });

    if (loggedInUser == null) {
      // Show loading instead of error when profile is still loading
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.black),
              SizedBox(height: 16),
              Text('جاري تحميل البيانات...'),
            ],
          ),
        ),
      );
    }

    final userEnrolledSubjectIds = loggedInUser.enrolledSubjects;
    final userSection = loggedInUser.section;
    final assistantPreferences = loggedInUser.assistantPreferences;

    // Check if data is ready using preloader service
    final isDataReady = DataPreloaderService.isWeekTasksDataReady(
      ref,
      loggedInUser,
    );

    // Only show loading if data is not ready and no cached data available
    if (!isDataReady) {
      // Check if we have ANY cached data to show immediately
      final hasAnyData =
          subjectsState.filteredSubjects.isNotEmpty ||
          sectionsState.sections.isNotEmpty ||
          tasksState.tasks.isNotEmpty;

      // Only show loading spinner if no cached data is available
      if (!hasAnyData) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.black),
                SizedBox(height: 16),
                Text('جاري تحميل المهام...'),
              ],
            ),
          ),
        );
      } else {
        // Show cached data immediately while fresh data loads in background
        print(
          '📱 WeekTasks: Showing cached data while fresh data loads in background',
        );
      }
    } else {
      print('⚡ WeekTasks: Data is ready - showing instant UI');
    }

    // If we have cached data, show it immediately even if fetching fresh data
    // This provides instant UI response using stale-while-revalidate pattern

    // Check for subjects that need assistant selection
    final subjectsNeedingSelection = _getSubjectsNeedingAssistantSelection(
      userEnrolledSubjectIds,
      assistantPreferences,
      subjectsState.instructorsBySubject,
    );

    // Step 1: Check default instructors for each registered subject
    final relevantSections = <Section>[];

    for (final subjectId in userEnrolledSubjectIds) {
      // Get all instructors for this subject
      final instructors =
          subjectsState.instructorsBySubject[subjectId]
              ?.where((prof) => prof.role == 'miniProfessor')
              .toList() ??
          [];

      if (instructors.isEmpty) {
        continue; // No instructors available - skip
      }

      // Get the default instructor (selected preference or first instructor)
      String? defaultAssistantId = assistantPreferences[subjectId];
      if (defaultAssistantId == null && instructors.length == 1) {
        defaultAssistantId =
            instructors.first.id; // Auto-select single instructor
      } else if (defaultAssistantId == null) {
        continue; // Multiple instructors but none selected - skip
      }

      // Step 2: Find the user's specific section for this subject and default instructor
      final userSubjectSection =
          sectionsState.sections.where((section) {
            return section.subjectId == subjectId &&
                section.assistantId == defaultAssistantId &&
                _matchesUserSectionNumber(section.name, userSection);
          }).firstOrNull;

      // Add the user's specific section if found
      if (userSubjectSection != null) {
        relevantSections.add(userSubjectSection);
      }
    }

    // Filter tasks based on the relevant sections
    final filteredTasks =
        allTasks.where((task) {
          // Personal tasks are always included
          if (task.isPersonal) {
            return true;
          }

          // Check if the task's section exists in our relevant sections
          final taskSection =
              relevantSections.where((s) => s.id == task.sectionId).firstOrNull;

          // Include task if its section is in our relevant sections
          return taskSection != null;
        }).toList();

    final userId = loggedInUser.id;

    // Since completed tasks are now archived, we only show pending tasks
    final pendingTasks =
        filteredTasks.where((t) => !t.isCompletedFor(userId)).toList();

    print(
      '📊 WeekTasks: ${pendingTasks.length} pending (${relevantSections.length} sections) - Completed tasks are archived',
    );

    final groupedTasks = _groupTasks(pendingTasks);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Offline Indicator
          if (!offlineService.hasConnection) _buildOfflineIndicator(),

          // Assistant Selection Warning
          if (subjectsNeedingSelection.isNotEmpty)
            _buildAssistantSelectionWarning(
              subjectsNeedingSelection,
              subjectsState,
            ),

          if (pendingTasks.isEmpty)
            _buildEmptyState()
          else ...[
            // Grouped Task Lists
            ..._buildGroupedTaskLists(groupedTasks),
          ],
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  /// Build offline indicator banner
  Widget _buildOfflineIndicator() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
          vertical: Responsive.space(context, size: Space.small),
        ),
        padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: Colors.grey.shade600, size: 20),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Text(
              'تعمل دلوقتي أوفلاين - بتستخدم البيانات المحفوظة',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: Responsive.text(context, size: TextSize.small),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state with enhanced design
  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.task_alt_outlined,
            size: 64,
            color: Colors.green.shade400,
          ),
        ),
      ),
    );
  }

  /// Build grouped task lists with enhanced organization
  List<Widget> _buildGroupedTaskLists(Map<String, List<Task>> groupedTasks) {
    final widgets = <Widget>[];
    final categoryLabels = {
      'overdue': 'متأخرة',
      'today': 'اليوم',
      'tomorrow': 'غداً',
      'thisWeek': 'هذا الأسبوع',
      'later': 'لاحقاً',
    };

    final categoryColors = {
      'overdue': Colors.red,
      'today': Colors.orange,
      'tomorrow': Colors.blue,
      'thisWeek': Colors.green,
      'later': Colors.grey,
    };

    for (final entry in groupedTasks.entries) {
      if (entry.value.isNotEmpty) {
        widgets.add(
          _buildTaskGroup(
            entry.key,
            entry.value,
            categoryLabels[entry.key] ?? entry.key,
            categoryColors[entry.key] ?? Colors.grey,
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildTaskGroup(
    String category,
    List<Task> tasks,
    String label,
    Color color,
  ) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _listAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - _listAnimation.value)),
            child: Opacity(
              opacity: _listAnimation.value,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.medium),
                  vertical: Responsive.space(context, size: Space.small),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: Responsive.space(context, size: Space.medium),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                              vertical: Responsive.space(
                                context,
                                size: Space.tiny,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.small),
                              ),
                            ),
                            child: Text(
                              '${tasks.length}',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),

                      // Task List
                      ...tasks.map((task) => _buildEnhancedTaskItem(task)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build enhanced task item
  Widget _buildEnhancedTaskItem(Task task) {
    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      child: TaskModel(
        task: task,
        admin: false,
        onStatusChanged: () => _handleTaskStatusChange(task),
        onEdit:
            task.isPersonal
                ? () => _showAddEditTaskDialog(context, task: task)
                : () {}, // Disable editing for system tasks
        onDelete:
            task.isPersonal
                ? () => _handleTaskDelete(task)
                : () {}, // Disable deletion for system tasks
      ),
    );
  }

  void _handleTaskStatusChange(Task task) {
    // Use the tasks provider for all task status changes (both personal and system tasks)
    // Don't await - let optimistic update handle UI instantly
    final userProfileState = ref.read(userProfileProvider);
    final user = userProfileState.loggedInUserProfile;

    // Check if task will be completed after toggle
    final willBeCompleted = user != null && !task.isCompletedFor(user.id);

    // Trigger toggle (optimistic update happens inside provider)
    ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id).catchError((
      e,
    ) {
      print('❌ WeekTasks: Error toggling task completion - $e');
    });

    // Play sound immediately if task is being completed
    if (willBeCompleted) {
      SoundService().playCorrectSound().catchError((e) {
        print('❌ WeekTasks: Error playing sound - $e');
      });
    }
  }

  void _handleTaskDelete(Task task) {
    // Use the tasks provider for all task deletions (both personal and system tasks)
    try {
      ref.read(tasksProvider.notifier).deleteTask(task.id);
      print('✅ WeekTasks: Task deleted from cloud');
    } catch (e) {
      print('❌ WeekTasks: Error deleting task - $e');
    }
  }

  /// Check if section name matches user's section

  /// Check if section number matches user's section number
  bool _matchesUserSectionNumber(String sectionName, String userSection) {
    // Extract number from section name (e.g., "سكشن 1" -> "1", "Section A" -> "A")
    final sectionNumber = _extractSectionNumber(sectionName);

    // Clean user section
    final cleanUserSection = userSection.trim();

    // Compare the numbers
    final matches = sectionNumber == cleanUserSection;

    return matches;
  }

  /// Extract section number from section name
  String _extractSectionNumber(String sectionName) {
    // Remove common prefixes and extract the number/letter
    final cleanName = sectionName.trim().toLowerCase();

    // Try to extract number after "سكشن" or "section"
    final arabicMatch = RegExp(r'سكشن\s*(\w+)').firstMatch(cleanName);
    if (arabicMatch != null) {
      return arabicMatch.group(1) ?? '';
    }

    final englishMatch = RegExp(r'section\s*(\w+)').firstMatch(cleanName);
    if (englishMatch != null) {
      return englishMatch.group(1) ?? '';
    }

    // If no prefix found, try to extract the last word/number
    final words = cleanName.split(RegExp(r'[\s\-_]+'));
    if (words.isNotEmpty) {
      return words.last;
    }

    return '';
  }

  /// Build speed dial with add task and archive options
  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      activeBackgroundColor: Colors.black,
      activeForegroundColor: Colors.white,
      visible: true,
      closeManually: false,
      elevation: 4,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      direction: SpeedDialDirection.up,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.archive_outlined),
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
          label: 'الأرشيف',
          labelStyle: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          labelBackgroundColor: Colors.white,
          onTap: () {
            Navigator.of(context).push(
              AnimatedAddRoute(
                startPosition: Offset.zero,
                child: const ArchivedTasksScreen(),
              ),
            );
          },
          elevation: 4,
          shape: const CircleBorder(),
        ),
        SpeedDialChild(
          child: const Icon(Icons.add),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          label: 'إضافة تاسك',
          labelStyle: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          labelBackgroundColor: Colors.white,
          onTap: () => _showAddEditTaskDialog(context),
          elevation: 4,
          shape: const CircleBorder(),
        ),
      ],
    );
  }

  /// Build assistant selection warning
  Widget _buildAssistantSelectionWarning(
    List<String> subjectsNeedingSelection,
    SubjectsState subjectsState,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
          vertical: Responsive.space(context, size: Space.small),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Padding(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        child: Text(
                          'اختار المُعيد بتاعك',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),

                  // Description
                  Text(
                    'محتاج تختار المُعيد للمواد التالية عشان تظهرلك التاسكات. تقدر تعمل كدا من صفحة السكاشن.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: Responsive.text(context, size: TextSize.small),
                    ),
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),

                  // Subject list
                  ...subjectsNeedingSelection.map((subjectId) {
                    final subject =
                        subjectsState.filteredSubjects
                            .where((s) => s.id == subjectId)
                            .firstOrNull;
                    final instructors =
                        subjectsState.instructorsBySubject[subjectId]
                            ?.where((prof) => prof.role == 'miniProfessor')
                            .toList() ??
                        [];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: Responsive.space(context, size: Space.small),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.small),
                          ),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.school, color: Colors.orange, size: 16),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject?.name ?? 'Subject $subjectId',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${instructors.length} أستاذ متاح',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
