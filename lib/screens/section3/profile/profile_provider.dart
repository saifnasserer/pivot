import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileProvider with ChangeNotifier {
  final UserProfileProvider _userProfileProvider;
  final ScheduleProvider _scheduleProvider;
  final TaskProvider _taskProvider;
  final SubjectProvider _subjectProvider;
  final SectionProvider _sectionProvider;

  ProfileProvider({
    required UserProfileProvider userProfileProvider,
    required ScheduleProvider scheduleProvider,
    required TaskProvider taskProvider,
    required SubjectProvider subjectProvider,
    required SectionProvider sectionProvider,
  }) : _userProfileProvider = userProfileProvider,
       _scheduleProvider = scheduleProvider,
       _taskProvider = taskProvider,
       _subjectProvider = subjectProvider,
       _sectionProvider = sectionProvider;

  UserProfile? _previousUserProfile;
  int _selectedDayIndex = 0;

  // Getters
  UserProfile? get previousUserProfile => _previousUserProfile;
  int get selectedDayIndex => _selectedDayIndex;

  // Update selected day index
  void updateSelectedDayIndex(int index) {
    if (_selectedDayIndex != index) {
      _selectedDayIndex = index;
      notifyListeners();
    }
  }

  // Check if user profile has changed
  bool hasUserProfileChanged(UserProfile? currentProfile) {
    if (currentProfile != null && currentProfile != _previousUserProfile) {
      _previousUserProfile = currentProfile;
      return true;
    }
    return false;
  }

  // Fetch profile data
  Future<void> fetchProfileData(UserProfile userProfile) async {
    try {
      // Check if providers are still valid before proceeding
      if (!areProvidersValid()) {
        return;
      }

      // Only fetch if we don't have data or if user profile changed
      final currentUserProfile = _userProfileProvider.userProfile;
      if (currentUserProfile?.id == userProfile.id &&
          _scheduleProvider.days.isNotEmpty &&
          _subjectProvider.filteredSubjects.isNotEmpty) {
        // Data already loaded for this user, skip fetching
        return;
      }

      // Reset all providers first
      _scheduleProvider.fetchSchedule();
      _taskProvider.fetchTasks();

      // Fetch all users and then filter subjects for current user
      await _userProfileProvider.fetchAllUsers(
        forceAll: true,
        roleFilter: ['Professor', 'miniProfessor'],
      );

      // Safely call buildInstructorsMap with error handling
      try {
        _subjectProvider.buildInstructorsMap(_userProfileProvider.allUsers);
      } catch (e) {
        return; // Exit early if SubjectProvider is disposed
      }

      // Fetch all subjects first, then filter for current user
      try {
        await _subjectProvider.fetchAllSubjectsWithoutFilter();
      } catch (e) {
        return; // Exit early if SubjectProvider is disposed
      }

      // Filter subjects for the current user based on their role
      try {
        if (userProfile.role == 'Student') {
          // For students, use enrolled subjects
          final enrolledIds = userProfile.enrolledSubjects ?? [];
          _subjectProvider.updateFilteredSubjectsOnly(userProfile);
          _sectionProvider.fetchSectionsForUserSubjects(enrolledIds);
        } else if (userProfile.role == 'Professor' ||
            userProfile.role == 'miniProfessor') {
          // For professors/assistants, use teaching subjects
          final teachingIds = userProfile.teachingSubjects ?? [];
          _subjectProvider.updateFilteredSubjectsOnly(userProfile);
          _sectionProvider.fetchSectionsForUserSubjects(teachingIds);
        } else {
          // For admins, show all subjects
          final allSubjectIds =
              _subjectProvider.filteredSubjects.map((s) => s.id).toList();
          _sectionProvider.fetchSectionsForUserSubjects(allSubjectIds);
        }
      } catch (e) {
      }
    } catch (e) {
    }
  }

  // Logout functionality
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // Notification settings
  Future<Map<String, bool>> loadNotificationPreferences() async {
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

    return prefs;
  }

  // Save notification preferences
  Future<void> saveNotificationPreferences({
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

  // Check notification permissions
  Future<bool> checkNotificationPermissions() async {
    return await NotificationService().areNotificationsEnabled();
  }

  // Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    final notificationService = NotificationService();
    return await notificationService.requestPermissionsExplicitly();
  }

  // Check if all providers are still valid
  bool areProvidersValid() {
    try {
      // Try to access a simple property from each provider to check if they're disposed
      _userProfileProvider.userProfile;
      _scheduleProvider.days;
      _taskProvider.tasks;
      _subjectProvider.filteredSubjects;
      _sectionProvider.sections;
      return true;
    } catch (e) {
      return false;
    }
  }
}
