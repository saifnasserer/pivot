import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section3/add_edit_schedule_dialog.dart';
import 'package:pivot/screens/section3/bookmarks_screen.dart';
import 'package:pivot/screens/section3/profile_categories_section.dart';
import 'package:pivot/screens/section3/profile_details.dart';
import 'package:pivot/screens/section3/profile_widgets/week_tasks.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section3/profile_widgets/schadule.dart';
import 'package:pivot/screens/section3/profile_widgets/sections.dart';
import 'package:pivot/screens/section3/profile_widgets/subjects.dart';
import 'package:pivot/screens/section4/assistants/assistant_profile.dart';
import 'package:pivot/screens/section4/doctor/doctor_profile.dart';
import 'package:provider/provider.dart';

class Profile extends StatefulWidget {
  static const String id = 'profile';
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _profileDetailsKey = GlobalKey();
  int _selectedDayIndex = 0;
  String _currentCategory = 'تاسكات الاسبوع';
  UserProfile? _previousUserProfile;

  @override
  void initState() {
    super.initState();
    // Initial data fetch is triggered by didChangeDependencies
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scheduleProvider = Provider.of<ScheduleProvider>(
        context,
        listen: false,
      );
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final subjectProvider = Provider.of<SubjectProvider>(
        context,
        listen: false,
      );
      final sectionProvider = Provider.of<SectionProvider>(
        context,
        listen: false,
      );
      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );

      scheduleProvider.fetchSchedule();
      taskProvider.fetchTasks();
      userProfileProvider.fetchAllUsers().then((_) {
        if (!mounted) return;
        subjectProvider.buildInstructorsMap(userProfileProvider.allUsers);
        subjectProvider.fetchAndFilterSubjects(userProfile).then((_) {
          if (!mounted) return;
          final subjectIds =
              subjectProvider.filteredSubjects.map((s) => s.id).toList();
          sectionProvider.fetchSectionsForUserSubjects(subjectIds);
        });
      });
    });
  }

  void _handleCategoryChanged(String category) {
    Future.delayed(const Duration(milliseconds: 50), () {
      final context = _profileDetailsKey.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox;
        _scrollController.animateTo(
          box.size.height + Responsive.space(context, size: Space.large),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });

    setState(() {
      _currentCategory = category;
      if (category == 'الجدول') {
        _selectedDayIndex = 0;
      }
    });
  }

  void _onDaySelected(int index) {
    setState(() {
      _selectedDayIndex = index;
    });
  }

  List<Widget> _getCategoryContentSlivers() {
    switch (_currentCategory) {
      case 'تاسكات الاسبوع':
        return [const SliverFillRemaining(child: WeekTasks())];

      case 'الجدول':
        final scheduleProvider = Provider.of<ScheduleProvider>(context);
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
              child: Center(child: Text('Error: ${scheduleProvider.error}')),
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
          onNotificationToggle: (String itemId) {
            scheduleProvider.toggleNotificationForItem(currentDay, itemId);
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
              child: Center(child: Text('Error: ${subjectProvider.error}')),
            ),
          ];
        }
        return buildSubjectsSlivers(
          context,
          subjectProvider.filteredSubjects,
          subjectProvider.instructorsBySubject,
        );

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
              child: Center(child: Text('Error: ${sectionProvider.error}')),
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

    if (userProfile != null) {
      final lowerCaseRole = userProfile.role.toLowerCase();
      if (lowerCaseRole == 'professor') return const DoctorProfile();
      if (lowerCaseRole == 'miniprofessor') return const AssistantProfile();
    }

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
      appBar: AppBar(
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
      ),
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
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.small),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: _profileDetailsKey,
                  child: Consumer<UserProfileProvider>(
                    builder: (context, userProfileProvider, child) {
                      final userProfile =
                          userProfileProvider.loggedInUserProfile;
                      if (userProfile == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ProfileDetails(userProfile: userProfile);
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.large),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  height: Responsive.space(context, size: Space.large) * 2,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: ProfileCategories(
                            onCategoryChanged: _handleCategoryChanged,
                          ),
                        ),
                        const Divider(height: 1, indent: 4, endIndent: 4),
                      ],
                    ),
                  ),
                ),
              ),
              ..._getCategoryContentSlivers(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, this.height = 60.0});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
