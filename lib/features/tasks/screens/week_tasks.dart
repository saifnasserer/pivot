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

/// Enhanced WeekTasks with analytics, smart organization, and modern UI
class WeekTasks extends ConsumerStatefulWidget {
  const WeekTasks({super.key});

  @override
  ConsumerState<WeekTasks> createState() => _WeekTasksState();
}

class _WeekTasksState extends ConsumerState<WeekTasks>
    with TickerProviderStateMixin {
  bool _isCompletedTasksExpanded = false;
  final List<Task> _personalTasks = [];
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
      }
    });
  }

  /// Smart data initialization - only fetches what's not already loaded
  /// Reduces redundant Firestore reads and improves performance
  void _initializeDataSmart(UserProfile user) {
    final subjectsState = ref.read(subjectsProvider);
    final sectionsState = ref.read(sectionsProvider);
    final tasksState = ref.read(tasksProvider);

    final fetchFutures = <Future>[];

    // Only fetch subjects if not already loaded or loading
    if (subjectsState.filteredSubjects.isEmpty && !subjectsState.isLoading) {
      fetchFutures.add(
        ref.read(subjectsProvider.notifier).fetchAndFilterSubjects(user),
      );
    }

    // Only fetch sections if not already loaded or loading
    if (sectionsState.sections.isEmpty &&
        !sectionsState.isLoading &&
        user.enrolledSubjects.isNotEmpty) {
      fetchFutures.add(
        ref
            .read(sectionsProvider.notifier)
            .fetchSectionsForUserSubjects(user.enrolledSubjects),
      );
    }

    // Only fetch tasks if not already loaded or loading
    if (tasksState.tasks.isEmpty && !tasksState.isLoading) {
      fetchFutures.add(ref.read(tasksProvider.notifier).getAllTasks());
    }

    if (fetchFutures.isEmpty) {
      print(
        '✅ WeekTasks: Using cached data (S:${subjectsState.filteredSubjects.length}, Sec:${sectionsState.sections.length}, T:${tasksState.tasks.length}) - Zero reads',
      );
    } else {
      print(
        '🔄 WeekTasks: Fetching ${fetchFutures.length} data sources in parallel...',
      );
      // Fetch all in parallel for better performance
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
      onSave: (task) {
        // Handle the saved personal task
        setState(() {
          final index = _personalTasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            _personalTasks[index] = task;
          } else {
            _personalTasks.add(task);
          }
        });
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

    // Listen for when user profile loads and trigger data fetching
    ref.listen<UserProfileState>(userProfileProvider, (previous, next) {
      // When profile becomes available (was null, now has value)
      if (previous?.loggedInUserProfile == null &&
          next.loggedInUserProfile != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final loggedInUser = next.loggedInUserProfile!;

            // Fetch subjects with instructors
            ref
                .read(subjectsProvider.notifier)
                .fetchAndFilterSubjects(loggedInUser);

            // Fetch sections for enrolled subjects
            if (loggedInUser.enrolledSubjects.isNotEmpty) {
              ref
                  .read(sectionsProvider.notifier)
                  .fetchSectionsForUserSubjects(loggedInUser.enrolledSubjects);
            }

            // Fetch all tasks
            ref.read(tasksProvider.notifier).getAllTasks();

            // Update assistant preferences
            _updateAssistantPreferencesIfNeeded();
          }
        });
      }
    });

    final loggedInUser = userProfileState.loggedInUserProfile;
    final allTasks = [...tasksState.tasks, ..._personalTasks];

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

    // Optimized loading logic: Show cached data immediately
    final isLoadingData =
        subjectsState.isLoading ||
        sectionsState.isLoading ||
        tasksState.isLoading;

    // Check if we have ANY data (from cache or fresh)
    final hasAnyData =
        subjectsState.filteredSubjects.isNotEmpty ||
        sectionsState.sections.isNotEmpty ||
        tasksState.tasks.isNotEmpty;

    // Check if instructors data is ready for enrolled subjects
    final hasInstructorsData =
        userEnrolledSubjectIds.isEmpty ||
        userEnrolledSubjectIds.any(
          (subjectId) =>
              subjectsState.instructorsBySubject[subjectId]?.isNotEmpty ??
              false,
        );

    // Check if sections data has been fetched (at least once)
    final hasSectionsData =
        userEnrolledSubjectIds.isEmpty || sectionsState.sections.isNotEmpty;

    // Only show loading spinner if:
    // 1. Currently loading AND 2. No cached data available (first time load)
    final shouldShowLoading = isLoadingData && !hasAnyData;

    if (shouldShowLoading ||
        (!hasInstructorsData && !hasAnyData) ||
        (!hasSectionsData && !hasAnyData)) {
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
    final pendingTasks =
        filteredTasks.where((t) => !t.isCompletedFor(userId)).toList();
    final completedTasks =
        filteredTasks.where((t) => t.isCompletedFor(userId)).toList();

    print(
      '📊 WeekTasks: ${pendingTasks.length} pending, ${completedTasks.length} completed (${relevantSections.length} sections)',
    );

    final groupedTasks = _groupTasks(pendingTasks);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Assistant Selection Warning
          if (subjectsNeedingSelection.isNotEmpty)
            _buildAssistantSelectionWarning(
              subjectsNeedingSelection,
              subjectsState,
            ),

          if (pendingTasks.isEmpty && completedTasks.isEmpty)
            _buildEmptyState()
          else ...[
            // Grouped Task Lists
            ..._buildGroupedTaskLists(groupedTasks),

            // Completed Tasks Section
            if (completedTasks.isNotEmpty)
              _buildCompletedTasksSection(completedTasks),
          ],
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
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

  /// Build enhanced task item with swipe actions (only for personal tasks)
  Widget _buildEnhancedTaskItem(Task task) {
    // Only allow dismissible delete for personal tasks
    if (task.isPersonal) {
      return Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: EdgeInsets.only(
            bottom: Responsive.space(context, size: Space.small),
          ),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
          ),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(
            right: Responsive.space(context, size: Space.large),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 24),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('حذف المهمة الشخصية'),
                  content: const Text(
                    'هل أنت متأكد من حذف هذه المهمة الشخصية؟',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
          );
        },
        onDismissed: (direction) {
          setState(() {
            _personalTasks.removeWhere((t) => t.id == task.id);
          });
        },
        child: TaskModel(
          task: task,
          admin: false,
          onStatusChanged: () => _handleTaskStatusChange(task),
          onEdit: () => _showAddEditTaskDialog(context, task: task),
          onDelete: () => _handleTaskDelete(task),
        ),
      );
    } else {
      // For system tasks, return without dismissible wrapper
      return Container(
        margin: EdgeInsets.only(
          bottom: Responsive.space(context, size: Space.small),
        ),
        child: TaskModel(
          task: task,
          admin: false,
          onStatusChanged: () => _handleTaskStatusChange(task),
          onEdit: () {}, // Disable editing for system tasks
          onDelete: () {}, // Disable deletion for system tasks
        ),
      );
    }
  }

  void _handleTaskStatusChange(Task task) async {
    if (task.isPersonal) {
      final userProfileState = ref.read(userProfileProvider);
      final user = userProfileState.loggedInUserProfile;
      if (user == null) return;

      final wasCompleted = task.isCompletedFor(user.id);
      final newCompletedBy = List<String>.from(task.completedBy);
      if (wasCompleted) {
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

      // Play sound when personal task is completed
      if (!wasCompleted) {
        await SoundService().playCorrectSound();
      }
    } else {
      ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
    }
  }

  void _handleTaskDelete(Task task) {
    if (task.isPersonal) {
      setState(() {
        _personalTasks.removeWhere((t) => t.id == task.id);
      });
    } else {
      ref.read(tasksProvider.notifier).deleteTask(task.id);
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

  /// Build completed tasks section with enhanced design
  Widget _buildCompletedTasksSection(List<Task> completedTasks) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
          vertical: Responsive.space(context, size: Space.small),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.medium),
            ),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.medium),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.medium),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      'ضن (${completedTasks.length})',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
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
                                  ? Responsive.space(context, size: Space.small)
                                  : 0,
                        ),
                        child: TaskModel(
                          task: task,
                          admin: false,
                          onStatusChanged: () => _handleTaskStatusChange(task),
                          onEdit:
                              () => _showAddEditTaskDialog(context, task: task),
                          onDelete: () => _handleTaskDelete(task),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build enhanced floating action button
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      heroTag: 'week_tasks_fab',
      onPressed: () => _showAddEditTaskDialog(context),
      backgroundColor: Colors.black,
      elevation: 4,
      shape: CircleBorder(),
      label: const Icon(Icons.add, color: Colors.white, size: 20),
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
