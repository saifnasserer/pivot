import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/administration/screens/assistants/profile/assistant_profile_main.dart';
import 'package:pivot/features/administration/screens/doctor/profile/doctor_profile.dart';

import 'package:pivot/features/bookmarks/screens/bookmarks_screen.dart';
import 'package:pivot/features/tasks/screens/week_tasks.dart';
import 'profile_app_bar.dart';
import 'profile_details_tab.dart';
import 'schedule_tab.dart';
import 'subjects_tab.dart';
import 'sections_tab.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final int? initialTabIndex;

  const ProfileScreen({super.key, this.initialTabIndex});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  Timer? _debounceTimer;
  final bool _isRefreshingData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Riverpod handles state automatically now
    // Individual tabs manage their own data loading
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
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addObserver(this);

    // Note: Data loading is now handled by individual tabs (WeekTasks, SectionsTab, etc.)
    // This eliminates redundant fetches and improves performance
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
      // Riverpod providers handle refresh automatically
      // Individual tabs will reload their data as needed
    }
  }

  void _onDaySelected(int index) {
    // Day selection is now handled within the tab itself
    // No need for separate provider update
  }

  void _onTabChanged() {
    // Filters are now handled automatically by Riverpod
    // No manual reset needed
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);
    final userProfile = userProfileState.loggedInUserProfile;

    // Check for special user roles first
    if (userProfile != null) {
      final lowerCaseRole = userProfile.role.toLowerCase();
      if (lowerCaseRole == 'professor') return const DoctorProfile();
      if (lowerCaseRole == 'miniprofessor') return const AssistantProfileMain();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ProfileAppBar(tabController: _tabController),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // Profile Details Tab
              const ProfileDetailsTab(),

              // Bookmarks Tab
              const BookmarksScreen(),

              // Sections Tab
              _isRefreshingData
                  ? const Center(child: CircularProgressIndicator())
                  : const SectionsTab(),

              // Subjects Tab
              _isRefreshingData
                  ? const Center(child: CircularProgressIndicator())
                  : const SubjectsTab(),

              // Schedule Tab
              ScheduleTab(onDaySelected: _onDaySelected),

              // Week Tasks Tab
              const WeekTasks(),
            ],
          ),
          if (_isRefreshingData)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.blue.withOpacity(0.1),
                child: const Center(
                  child: Text(
                    'جاري تحديث البيانات...',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
