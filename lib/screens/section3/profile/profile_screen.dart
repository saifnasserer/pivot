import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pivot/screens/section4/assistants/profile/assistant_profile_main.dart';
import 'package:pivot/screens/section4/doctor/profile/doctor_profile.dart';
import 'package:provider/provider.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/section_provider.dart';

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
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addObserver(this);

    // Load sections when profile screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProfile = context.read<UserProfileProvider>().userProfile;
        if (userProfile != null && userProfile.enrolledSubjects.isNotEmpty) {
          context.read<SectionProvider>().fetchSectionsForUserSubjects(
            userProfile.enrolledSubjects,
          );
        }
      }
    });
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
      // Only refresh profile data when app is resumed, don't reset sections
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final userProfile = context.read<UserProfileProvider>().userProfile;
          if (userProfile != null) {
            // Only fetch profile data, don't reset sections
            final provider = context.read<ProfileProvider>();
            provider.fetchProfileData(userProfile);
          }
        }
      });
    }
  }

  void _fetchProfileData(UserProfile userProfile) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        // Only reset SubjectProvider filter, not SectionProvider
        // Use additional post-frame callback to ensure these happen after current build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<SubjectProvider>().resetFilter();
            // Removed SectionProvider.resetFilter() to prevent sections from disappearing
          }
        });

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

  void _onTabChanged() {
    // Reset filters when switching to subjects tab only
    if (_tabController.index == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Use additional post-frame callback to ensure these happen after current build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<SubjectProvider>().resetFilter();
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.read<UserProfileProvider>().userProfile;

    // Check for special user roles first
    if (userProfile != null) {
      final lowerCaseRole = userProfile.role.toLowerCase();
      if (lowerCaseRole == 'professor') return const DoctorProfile();
      if (lowerCaseRole == 'miniprofessor') return const AssistantProfileMain();
    }

    // Update profile data when user profile changes (e.g., when returning from another profile)
    if (userProfile != null && userProfile != _previousUserProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Only fetch profile data, don't reset sections
          final provider = context.read<ProfileProvider>();
          provider.fetchProfileData(userProfile);
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
