import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section3/bookmarks_screen.dart';
import 'package:pivot/screens/section3/profile_details.dart';
import 'package:pivot/screens/section3/profile_widgets/week_tasks.dart';
import 'package:pivot/screens/section3/profile_widgets/schadule.dart';
import 'package:pivot/screens/section3/profile_widgets/sections.dart';
import 'package:pivot/screens/section3/profile_widgets/subjects.dart';
import 'package:pivot/screens/section4/assistants/assistant_profile.dart';
import 'package:pivot/screens/section4/doctor/doctor_profile.dart';
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/services/notification_service.dart';

class Profile extends StatefulWidget {
  final int? initialTabIndex;

  const Profile({super.key, this.initialTabIndex});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayIndex = 0;
  UserProfile? _previousUserProfile;

  @override
  void initState() {
    super.initState();
    final initialIndex =
        widget.initialTabIndex ?? 5; // Default to week tasks tab
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      userProfileProvider
          .fetchAllUsers(
            forceAll: true,
            roleFilter: ['Professor', 'miniProfessor'],
          )
          .then((_) {
            if (!mounted) return;
            subjectProvider.buildInstructorsMap(userProfileProvider.allUsers);
            subjectProvider.fetchAllSubjectsWithoutFilter().then((_) {
              if (!mounted) return;
              final subjectIds =
                  subjectProvider.filteredSubjects.map((s) => s.id).toList();
              sectionProvider.fetchSectionsForUserSubjects(subjectIds);
            });
          });
    });
  }

  void _onDaySelected(int index) {
    setState(() {
      _selectedDayIndex = index;
    });
  }

  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل الخروج؟', textAlign: TextAlign.center),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/auth-wrapper',
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: Text(
                        'تأكيد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  TextButton(
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
        title: Text(
          'المطبخ',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.heading),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _showLogoutConfirmationDialog,
            tooltip: 'تسجيل الخروج',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            color: Colors.black,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          labelStyle: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSansArabic',
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.w500,
            fontFamily: 'NotoSansArabic',
          ),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.medium),
          ),
          tabs: const [
            Tab(text: 'الملف الشخصي'),
            Tab(text: 'المحفوظات'),
            Tab(text: 'السكاشن'),
            Tab(text: 'مواد الترم'),
            Tab(text: 'الجدول'),
            Tab(text: 'تاسكات الاسبوع'),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(currentSelectedDay),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Profile Details Tab
          _buildProfileDetailsTab(),
          // Bookmarks Tab
          const BookmarksScreen(),

          // Sections Tab
          _buildSectionsTab(),

          // Subjects Tab
          _buildSubjectsTab(),

          // Schedule Tab
          _buildScheduleTab(),

          // Week Tasks Tab
          const WeekTasks(),
        ],
      ),
    );
  }

  Widget _buildProfileDetailsTab() {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        final userProfile = userProfileProvider.loggedInUserProfile;
        if (userProfile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: Responsive.padding(context),
          child: Column(
            children: [
              // Quick Actions Section at the top
              ProfileDetails(userProfile: userProfile),
              SizedBox(height: Responsive.space(context, size: Space.large)),
              Directionality(
                textDirection: TextDirection.rtl,
                child: _buildQuickActionsSection(userProfile),
              ),

              // Profile Details at the bottom
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsSection(UserProfile userProfile) {
    return Container(
      padding: Responsive.padding(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.grey.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              // First row
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'تعديل البيانات',
                      Icons.edit_outlined,
                      Colors.blue.shade600,
                      () => Navigator.pushNamed(context, '/edit-profile'),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child: _buildActionCard(
                      'الإشعارات',
                      Icons.notifications_outlined,
                      Colors.black,
                      () => _showNotificationSettingsDialog(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Second row
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'إرسال ملاحظات',
                      Icons.feedback_outlined,
                      Colors.black,
                      () => Navigator.pushNamed(context, '/feedback'),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child:
                        userProfile.role == 'Student' ||
                                userProfile.role == 'Admin'
                            ? _buildActionCard(
                              'تسجيل المواد',
                              Icons.school_outlined,
                              Colors.purple.shade600,
                              () => _navigateToSubjectSelection(
                                userProfile.enrolledSubjects ?? [],
                              ),
                            )
                            : userProfile.role == 'Professor' ||
                                userProfile.role == 'miniProfessor'
                            ? _buildActionCard(
                              'المواد الخاصة بي',
                              Icons.book_outlined,
                              Colors.indigo.shade600,
                              () => _navigateToSubjectSelection(
                                userProfile.teachingSubjects ?? [],
                              ),
                            )
                            : _buildActionCard(
                              'إعدادات متقدمة',
                              Icons.settings_outlined,
                              Colors.grey.shade600,
                              () => Navigator.pushNamed(
                                context,
                                '/advanced-settings',
                              ),
                            ),
                  ),
                ],
              ),

              // Third row (if needed for Super Admin)
              if (userProfile.role == 'Super Admin') ...[
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'ادارة المستخدمين',
                        Icons.admin_panel_settings_outlined,
                        Colors.red.shade600,
                        () => Navigator.pushNamed(context, '/user-management'),
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.medium),
                    ),
                    Expanded(
                      child: _buildActionCard(
                        'ادارة المواد',
                        Icons.class_outlined,
                        Colors.teal.shade600,
                        () => Navigator.pushNamed(
                          context,
                          '/global-subject-management',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(
            Responsive.space(context, size: Space.medium),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.medium),
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.medium),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: Responsive.text(context, size: TextSize.heading),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToSubjectSelection(
    List<String> previouslySelectedIds,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SubjectSelectionScreen(
              previouslySelectedIds: previouslySelectedIds,
            ),
      ),
    );
    // Reset subject filter after returning
    final userProfile =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;
    if (userProfile != null) {
      Provider.of<SubjectProvider>(
        context,
        listen: false,
      ).fetchAndFilterSubjects(userProfile);
    }
  }

  Future<void> _showNotificationSettingsDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    Map<String, bool> prefs = {
      'classNotifications': true,
      'taskNotifications': true,
      'announcementNotifications': true,
    };

    // Load preferences from Firestore if user is logged in
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data != null && data['notificationPreferences'] != null) {
        final np = data['notificationPreferences'];
        prefs = {
          'classNotifications': np['classNotifications'] ?? true,
          'taskNotifications': np['taskNotifications'] ?? true,
          'announcementNotifications': np['announcementNotifications'] ?? true,
        };
      }
    }

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
                title: Text(
                  'إعدادات الإشعارات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    color: Colors.black,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FutureBuilder<bool>(
                        future: NotificationService().areNotificationsEnabled(),
                        builder: (context, snapshot) {
                          final hasPermission = snapshot.data ?? false;
                          return Container(
                            padding: EdgeInsets.all(
                              Responsive.space(context, size: Space.small),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      hasPermission
                                          ? Icons.notifications_active
                                          : Icons.notifications_off,
                                      color:
                                          hasPermission
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                    SizedBox(
                                      width: Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        hasPermission
                                            ? 'الإشعارات مفعلة'
                                            : 'الإشعارات معطلة',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              hasPermission
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                    ),
                                    if (!hasPermission)
                                      TextButton(
                                        onPressed: () async {
                                          final notificationService =
                                              NotificationService();
                                          final granted =
                                              await notificationService
                                                  .requestPermissionsExplicitly();
                                          if (!granted) {
                                            // Show permission dialog
                                          }
                                          setState(() {});
                                        },
                                        child: Text(
                                          'تفعيل',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Notification switches
                      SwitchListTile(
                        title: Text('إشعارات المحاضرات'),
                        subtitle: Text('تنبيهات بمواعيد المحاضرات'),
                        value: prefs['classNotifications']!,
                        onChanged:
                            (value) => setState(
                              () => prefs['classNotifications'] = value,
                            ),
                        activeColor: Colors.green,
                      ),
                      SwitchListTile(
                        title: Text('إشعارات المهام'),
                        subtitle: Text('تنبيهات بمواعيد تسليم المهام'),
                        value: prefs['taskNotifications']!,
                        onChanged:
                            (value) => setState(
                              () => prefs['taskNotifications'] = value,
                            ),
                        activeColor: Colors.green,
                      ),
                      SwitchListTile(
                        title: Text('إشعارات الإعلانات'),
                        subtitle: Text('تنبيهات بالإعلانات الجديدة'),
                        value: prefs['announcementNotifications']!,
                        onChanged:
                            (value) => setState(
                              () => prefs['announcementNotifications'] = value,
                            ),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  ElevatedButton(
                    onPressed: () async {
                      await _saveNotificationPreferences(
                        classNotifications: prefs['classNotifications']!,
                        taskNotifications: prefs['taskNotifications']!,
                        announcementNotifications:
                            prefs['announcementNotifications']!,
                      );
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم حفظ إعدادات الإشعارات'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.space(context, size: Space.small),
                      ),
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                      ),
                    ),
                    child: Text('حفظ'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveNotificationPreferences({
    required bool classNotifications,
    required bool taskNotifications,
    required bool announcementNotifications,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'notificationPreferences': {
            'classNotifications': classNotifications,
            'taskNotifications': taskNotifications,
            'announcementNotifications': announcementNotifications,
          },
        },
      );
    }
  }

  Widget _buildScheduleTab() {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, child) {
        if (scheduleProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (scheduleProvider.error != null) {
          return Center(child: Text('Error: ${scheduleProvider.error}'));
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

        return ScheduleCalendarBuilder.buildScheduleWithScaffold(
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
          showFloatingActionButton: true,
          selectedDay: currentDay,
          enableAnimations: true,
        );
      },
    );
  }

  Widget _buildSubjectsTab() {
    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, child) {
        if (subjectProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (subjectProvider.error != null) {
          return Center(child: Text('Error: ${subjectProvider.error}'));
        }

        // Filter subjects to only those registered/enrolled by the user
        final userProfile =
            Provider.of<UserProfileProvider>(
              context,
              listen: false,
            ).userProfile;
        final enrolledIds = userProfile?.enrolledSubjects ?? [];
        final registeredSubjects =
            subjectProvider.filteredSubjects
                .where((s) => enrolledIds.contains(s.id))
                .toList();
        final subjectSlivers = buildSubjectsSlivers(
          context,
          registeredSubjects,
          subjectProvider.instructorsBySubject,
        );

        return CustomScrollView(slivers: subjectSlivers);
      },
    );
  }

  Widget _buildSectionsTab() {
    return Consumer<SectionProvider>(
      builder: (context, sectionProvider, child) {
        if (sectionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (sectionProvider.error != null) {
          return Center(child: Text('Error: ${sectionProvider.error}'));
        }

        final sectionSlivers = buildSectionsSlivers(context);

        return CustomScrollView(slivers: sectionSlivers);
      },
    );
  }

  Widget? _buildFloatingActionButton(String? currentSelectedDay) {
    // Floating action button is now handled within the schedule tab
    return null;
  }
}
