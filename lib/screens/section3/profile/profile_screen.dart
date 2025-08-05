import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/screens/section4/assistants/assistant_profile.dart';
import 'package:pivot/screens/section4/doctor/doctor_profile.dart';
import 'package:pivot/screens/section3/bookmarks_screen.dart';
import 'package:pivot/screens/section3/profile_widgets/week_tasks.dart';
import 'profile_provider.dart';
import 'profile_app_bar.dart';
import 'profile_details_tab.dart';
import 'schedule_tab.dart';
import 'subjects_tab.dart';
import 'sections_tab.dart';

class ProfileScreen extends StatefulWidget {
  final int? initialTabIndex;

  const ProfileScreen({super.key, this.initialTabIndex});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  UserProfile? _previousUserProfile;
  Timer? _debounceTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = context.read<UserProfileProvider>().userProfile;
    final provider = context.read<ProfileProvider>();

    if (userProfile != null && provider.hasUserProfileChanged(userProfile)) {
      // Cancel previous timer if it exists
      _debounceTimer?.cancel();
      // Use debounce to avoid multiple rapid calls
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _fetchProfileData(userProfile);
        }
      });
    }
  }

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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reset filters when app is resumed (user returns from another screen)
      final userProfile = context.read<UserProfileProvider>().userProfile;
      if (userProfile != null) {
        _fetchProfileData(userProfile);
      }
    }
  }

  void _fetchProfileData(UserProfile userProfile) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final provider = context.read<ProfileProvider>();
        provider.fetchProfileData(userProfile);
      } catch (e) {
        print('Warning: Error fetching profile data: $e');
      }
    });
  }

  void _onDaySelected(int index) {
    final provider = context.read<ProfileProvider>();
    provider.updateSelectedDayIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.read<UserProfileProvider>().userProfile;

    // Check for special user roles first
    if (userProfile != null) {
      final lowerCaseRole = userProfile.role.toLowerCase();
      if (lowerCaseRole == 'professor') return const DoctorProfile();
      if (lowerCaseRole == 'miniprofessor') return const AssistantProfile();
    }

    // Reset filters when user profile changes (e.g., when returning from another profile)
    if (userProfile != null && userProfile != _previousUserProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchProfileData(userProfile);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ProfileAppBar(
        tabController: _tabController,
        onLogoutPressed: () {
          // Logout is handled in the ProfileAppBar
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Profile Details Tab
          const ProfileDetailsTab(),

          // Bookmarks Tab
          const BookmarksScreen(),

          // Sections Tab
          const SectionsTab(),

          // Subjects Tab
          const SubjectsTab(),

          // Schedule Tab
          ScheduleTab(onDaySelected: _onDaySelected),

          // Week Tasks Tab
          const WeekTasks(),
        ],
      ),
    );
  }
}
