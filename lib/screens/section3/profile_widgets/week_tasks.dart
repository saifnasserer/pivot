import 'package:flutter/material.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/screens/models/task_model.dart';
import 'package:pivot/models/section_model.dart';
import 'package:provider/provider.dart';

import 'add_edit_task_dialog.dart';

/// Enhanced WeekTasks with analytics, smart organization, and modern UI
class WeekTasks extends StatefulWidget {
  const WeekTasks({super.key});

  @override
  State<WeekTasks> createState() => _WeekTasksState();
}

class _WeekTasksState extends State<WeekTasks> with TickerProviderStateMixin {
  bool _isCompletedTasksExpanded = false;
  final List<Task> _personalTasks = [];
  late AnimationController _progressAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _listAnimation;

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

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressAnimationController.forward();
      _listAnimationController.forward();
      _updateAssistantPreferencesIfNeeded(); // This is now async
    });
  }

  void _updateAssistantPreferencesIfNeeded() async {
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final loggedInUser = userProfileProvider.loggedInUserProfile;

    if (loggedInUser == null) return;

    final userEnrolledSubjectIds = loggedInUser.enrolledSubjects;
    final assistantPreferences = loggedInUser.assistantPreferences;
    final updatedPreferences = <String, String>{...assistantPreferences};

    for (final subjectId in userEnrolledSubjectIds) {
      final instructors =
          subjectProvider.instructorsBySubject[subjectId]
              ?.where((prof) => prof.role == 'miniProfessor')
              .toList() ??
          [];

      if (instructors.length == 1 &&
          !assistantPreferences.containsKey(subjectId)) {
        // Auto-select if only one instructor and no preference set
        updatedPreferences[subjectId] = instructors.first.id;
      }
    }

    // Only update if there are changes
    if (updatedPreferences.length != assistantPreferences.length ||
        updatedPreferences.entries.any(
          (entry) => assistantPreferences[entry.key] != entry.value,
        )) {
      try {
        await userProfileProvider.updateAssistantPreferences(
          updatedPreferences,
        );
        print(
          'Successfully updated assistant preferences: $updatedPreferences',
        );
      } catch (e) {
        print('Failed to update assistant preferences: $e');
      }
    }
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final sectionProvider = Provider.of<SectionProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final loggedInUser = userProfileProvider.loggedInUserProfile;
    final allTasks = [...taskProvider.tasks, ..._personalTasks];

    if (loggedInUser == null) {
      return Scaffold(body: Center(child: Text('User profile not found')));
    }

    final userEnrolledSubjectIds = loggedInUser.enrolledSubjects;
    final userSection = loggedInUser.section;
    final assistantPreferences = loggedInUser.assistantPreferences;

    // Step 1: Check default instructors for each registered subject
    final relevantSections = <Section>[];

    for (final subjectId in userEnrolledSubjectIds) {
      // Get all instructors for this subject
      final instructors =
          subjectProvider.instructorsBySubject[subjectId]
              ?.where((prof) => prof.role == 'miniProfessor')
              .toList() ??
          [];

      if (instructors.isEmpty) {
        // No instructors available for this subject - skip
        continue;
      }

      // Get the default instructor (selected preference or first instructor)
      String? defaultAssistantId = assistantPreferences[subjectId];
      if (defaultAssistantId == null && instructors.length == 1) {
        // Auto-select if only one instructor
        defaultAssistantId = instructors.first.id;
        // Note: We'll handle preference updates separately to avoid async issues in build
      } else if (defaultAssistantId == null) {
        // Multiple instructors but none selected - skip this subject
        continue;
      }

      // Step 2: Find the user's specific section for this subject and default instructor
      final userSubjectSection =
          sectionProvider.sections.where((section) {
            return section.subjectId == subjectId &&
                section.assistantId == defaultAssistantId &&
                userSection != null &&
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

    final groupedTasks = _groupTasks(pendingTasks);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          if (pendingTasks.isEmpty && completedTasks.isEmpty)
            _buildEmptyState()
          else ...[
            // Grouped Task Lists
            ..._buildGroupedTaskLists(groupedTasks, taskProvider),

            // Completed Tasks Section
            if (completedTasks.isNotEmpty)
              _buildCompletedTasksSection(completedTasks, taskProvider),
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
  List<Widget> _buildGroupedTaskLists(
    Map<String, List<Task>> groupedTasks,
    TaskProvider taskProvider,
  ) {
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
            taskProvider,
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
    TaskProvider taskProvider,
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
                      ...tasks.map(
                        (task) => _buildEnhancedTaskItem(task, taskProvider),
                      ),
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

  /// Build enhanced task item with swipe actions
  Widget _buildEnhancedTaskItem(Task task, TaskProvider taskProvider) {
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
                title: const Text('حذف المهمة'),
                content: const Text('هل أنت متأكد من حذف هذه المهمة؟'),
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
        if (task.isPersonal) {
          setState(() {
            _personalTasks.removeWhere((t) => t.id == task.id);
          });
        } else {
          taskProvider.deleteTask(task.id);
        }
      },
      child: TaskModel(
        task: task,
        admin: false,
        onStatusChanged: () => _handleTaskStatusChange(task, taskProvider),
        onEdit: () => _showAddEditTaskDialog(context, task: task),
        onDelete: () => _handleTaskDelete(task, taskProvider),
      ),
    );
  }

  void _handleTaskStatusChange(Task task, TaskProvider taskProvider) {
    if (task.isPersonal) {
      final user =
          Provider.of<UserProfileProvider>(context, listen: false).userProfile;
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
  }

  void _handleTaskDelete(Task task, TaskProvider taskProvider) {
    if (task.isPersonal) {
      setState(() {
        _personalTasks.removeWhere((t) => t.id == task.id);
      });
    } else {
      taskProvider.deleteTask(task.id);
    }
  }

  /// Check if section name matches user's section
  bool _matchesUserSection(String sectionName, String userSection) {
    final cleanSectionName = sectionName.trim().toLowerCase();
    final cleanUserSection = userSection.trim().toLowerCase();

    // Try different patterns to match the section
    final patterns = [
      // Pattern 1: "سكشن A" or "Section A"
      cleanUserSection,
      // Pattern 2: "A" (just the letter)
      cleanUserSection,
      // Pattern 3: "سكشن" + userSection
      'سكشن $cleanUserSection',
      // Pattern 4: "section" + userSection
      'section $cleanUserSection',
    ];

    // Check if any pattern matches
    for (int i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final matches = cleanSectionName.contains(pattern);
      if (matches) {
        return true;
      }
    }

    // Additional check: if section name ends with the user section
    final endsWithMatch = cleanSectionName.endsWith(cleanUserSection);
    if (endsWithMatch) {
      return true;
    }

    // Additional check: if section name contains the user section as a word
    final words = cleanSectionName.split(RegExp(r'[\s\-_]+'));
    final wordMatch = words.contains(cleanUserSection);
    if (wordMatch) {
      return true;
    }

    return false;
  }

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
  Widget _buildCompletedTasksSection(
    List<Task> completedTasks,
    TaskProvider taskProvider,
  ) {
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
                          onStatusChanged:
                              () => _handleTaskStatusChange(task, taskProvider),
                          onEdit:
                              () => _showAddEditTaskDialog(context, task: task),
                          onDelete: () => _handleTaskDelete(task, taskProvider),
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
      onPressed: () => _showAddEditTaskDialog(context),
      backgroundColor: Colors.black,
      elevation: 4,
      icon: const Icon(Icons.add, color: Colors.white, size: 20),
      label: const Text(
        'مهمة جديدة',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
