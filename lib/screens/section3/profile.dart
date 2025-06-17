import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section3/profile_categories_section.dart';
import 'package:pivot/screens/section3/profile_details.dart';
import 'package:pivot/screens/section3/profile_widgets/schadule.dart'
    show buildCalendar;
import 'package:pivot/screens/section3/profile_widgets/sections.dart';
import 'package:pivot/screens/section3/profile_widgets/subjects.dart'
    show buildSubjectsSlivers;
import 'package:pivot/screens/section3/profile_widgets/week_tasks.dart'
    show buildWeekTasksSlivers;
import 'package:provider/provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section4/assistants/assistant_profile.dart';
import 'package:pivot/screens/section4/doctor/doctor_profile.dart';
import 'package:pivot/models/user_profile.dart';
import 'add_edit_schedule_dialog.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/screens/section3/bookmarks_screen.dart';

class Profile extends StatefulWidget {
  static const String id = 'profile';
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  int _selectedDayIndex = 0;
  String _currentCategory = 'تاسكات الاسبوع';
  UserProfile? _previousUserProfile; // To track profile changes

  @override
  void initState() {
    super.initState();
    // Data fetching is now handled in didChangeDependencies to ensure
    // providers are available and to react to user profile changes.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = Provider.of<UserProfileProvider>(context).userProfile;

    if (userProfile != null && userProfile != _previousUserProfile) {
      _previousUserProfile = userProfile;
      _fetchProfileData(userProfile);
    }
  }

  void _fetchProfileData(UserProfile userProfile) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        Provider.of<ScheduleProvider>(context, listen: false).fetchSchedule();
        Provider.of<TaskProvider>(context, listen: false).fetchTasks();

        final userProfileProvider =
            Provider.of<UserProfileProvider>(context, listen: false);
        final subjectProvider =
            Provider.of<SubjectProvider>(context, listen: false);
        final sectionProvider =
            Provider.of<SectionProvider>(context, listen: false);

        await userProfileProvider.fetchAllUsers();
        if (!mounted) return;

        subjectProvider.buildInstructorsMap(userProfileProvider.allUsers);
        await subjectProvider.fetchAndFilterSubjects(userProfile);
        if (!mounted) return;

        final subjectIds =
            subjectProvider.filteredSubjects.map((s) => s.id).toList();
        sectionProvider.fetchSectionsForUserSubjects(subjectIds);
      }
    });
  }

  void _onDaySelected(int index) {
    setState(() {
      _selectedDayIndex = index;
    });
  }

  List<Widget> _getCategoryContentSlivers() {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    switch (_currentCategory) {
      case 'تاسكات الاسبوع':
        final userProfile =
            Provider.of<UserProfileProvider>(context, listen: false)
                .userProfile;
        final sectionProvider = Provider.of<SectionProvider>(context);

        if (taskProvider.isLoading || sectionProvider.isLoading) {
          return [
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ];
        }

        if (taskProvider.error != null || sectionProvider.error != null) {
          return [
            SliverFillRemaining(
              child: Center(
                child: Text(
                    'An error occurred: ${taskProvider.error ?? sectionProvider.error}'),
              ),
            ),
          ];
        }

        final enrolledSubjectIds = userProfile?.enrolledSubjects ?? [];
        final relevantSections = sectionProvider.sections
            .where((section) => enrolledSubjectIds.contains(section.subjectId))
            .toList();
        final relevantSectionIds =
            relevantSections.map((section) => section.id).toSet();

        final allTasks = taskProvider.tasks;
        final now = DateTime.now();

        final upcomingTasks = allTasks.where((task) {
          final taskDueDate = DateTime(
            task.dueDate.year,
            task.dueDate.month,
            task.dueDate.day,
          );
          final today = DateTime(now.year, now.month, now.day);
          final isUpcoming = !taskDueDate.isBefore(today);
          final isInRelevantSection =
              relevantSectionIds.contains(task.sectionId);
          return isUpcoming && isInRelevantSection;
        }).toList();

        // If there are no tasks, log diagnostic info for debugging.
        if (upcomingTasks.isEmpty) {
          debugPrint('--- Task Debug Info ---');
          debugPrint('User Profile Loaded: ${userProfile != null}');
          debugPrint('Enrolled Subject IDs: ${enrolledSubjectIds.toString()}');
          debugPrint('Relevant Sections Found: ${relevantSections.length}');
          debugPrint('Total Tasks in Provider: ${allTasks.length}');
          debugPrint('Section IDs for Filtering: ${relevantSectionIds.isEmpty ? "None" : relevantSectionIds.toString()}');
          debugPrint('Final Upcoming Task Count: ${upcomingTasks.length}');
          debugPrint('--- End Task Debug Info ---');
        }

        return buildWeekTasksSlivers(context, upcomingTasks, taskProvider);
      case 'الجدول':
        if (scheduleProvider.isLoading) {
          return [
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ];
        }

        if (scheduleProvider.error != null) {
          return [
            SliverFillRemaining(
              child: Center(
                child: Text('An error occurred: ${scheduleProvider.error}'),
              ),
            ),
          ];
        }

        final days = scheduleProvider.days;
        final validIndex = _selectedDayIndex.clamp(
          0,
          days.isEmpty ? 0 : days.length - 1,
        );
        final currentDay = days.isEmpty ? '' : days[validIndex];
        final itemsForSelectedDay = scheduleProvider.getScheduleForDay(
          currentDay,
        );

        return buildCalendar(
          selectedDayIndex: validIndex,
          context: context,
          days: days,
          dayScheduleItems: itemsForSelectedDay,
          onDaySelected: _onDaySelected,
          handleDelete: (String itemId) {
            scheduleProvider.removeScheduleItem(currentDay, itemId);
          },
        );
      case 'مواد الترم':
        final subjectProvider = Provider.of<SubjectProvider>(context);
        if (subjectProvider.isLoading) {
          return [
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ];
        }

        if (subjectProvider.error != null) {
          return [
            SliverFillRemaining(
              child: Center(
                child: Text('An error occurred: ${subjectProvider.error}'),
              ),
            ),
          ];
        }

        return buildSubjectsSlivers(context, subjectProvider.filteredSubjects);
      case 'السكاشن':
        final sectionProvider = Provider.of<SectionProvider>(context);

        if (sectionProvider.isLoading) {
          return [
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ];
        }

        if (sectionProvider.error != null) {
          return [
            SliverFillRemaining(
              child: Center(
                child: Text('An error occurred: ${sectionProvider.error}'),
              ),
            ),
          ];
        }

        return buildSectionsSlivers(context);
      case 'المحفوظات':
        return [const SliverFillRemaining(child: BookmarksScreen())];
      default:
        return [
          const SliverFillRemaining(
            child: Center(child: Text('Unknown Category')),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfileProvider>(context).userProfile;

    final appBar = AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_sharp, color: Colors.black),
          onPressed: () => profile_options(context),
        ),
      ],
    );

    if (userProfile != null) {
      final lowerCaseRole = userProfile.role.toLowerCase();
      if (lowerCaseRole == 'professor') {
        return const DoctorProfile();
      }
      if (lowerCaseRole == 'miniprofessor') {
        return const AssistantProfile();
      }
    }

    // Default view for students and other roles
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final days = scheduleProvider.days;
    final currentSelectedDay =
        days.isNotEmpty &&
                _selectedDayIndex >= 0 &&
                _selectedDayIndex < days.length
            ? days[_selectedDayIndex]
            : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      floatingActionButton:
          _currentCategory == 'الجدول' && currentSelectedDay != null
              ? FloatingActionButton(
                backgroundColor: Colors.black,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AddEditScheduleDialog(day: currentSelectedDay);
                    },
                  );
                },
                tooltip: 'اضافة محاضرة/سكشن',
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      body: SafeArea(
        child: Padding(
          padding: Responsive.paddingHorizontal(context),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.small),
                ),
              ),
              SliverToBoxAdapter(
                child: Consumer<UserProfileProvider>(
                  builder: (context, userProfileProvider, child) {
                    final userProfile = userProfileProvider.loggedInUserProfile;
                    if (userProfile == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ProfileDetails(userProfile: userProfile);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.large),
                ),
              ),
              SliverToBoxAdapter(
                child: ProfileCategories(
                  onCategoryChanged: (category) {
                    setState(() {
                      _currentCategory = category;
                      if (category == 'الجدول') {
                        _selectedDayIndex = 0;
                      }
                    });
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.large),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
              ..._getCategoryContentSlivers(),
            ],
          ),
        ),
      ),
    );
  }
}
