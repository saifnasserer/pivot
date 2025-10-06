import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/features/subjects/providers/subjects_provider.dart';
import 'package:pivot/features/profile/screens/profile_widgets/subjects.dart';

class SubjectsTab extends ConsumerStatefulWidget {
  const SubjectsTab({super.key});

  @override
  ConsumerState<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends ConsumerState<SubjectsTab> {
  bool _hasInitialized = false;
  String? _lastProfileId; // Track profile changes
  List<String>? _lastEnrolledSubjects; // Track enrolled subjects changes

  @override
  void initState() {
    super.initState();
    // Load subjects on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _initializeSubjects();
      }
    });
  }

  void _initializeSubjects() {
    final userProfileState = ref.read(userProfileProvider);
    final subjectsState = ref.read(subjectsProvider);
    final targetProfile = _getTargetProfile(
      userProfileState.userProfile,
      userProfileState.loggedInUserProfile,
    );

    if (targetProfile != null) {
      final hasData = subjectsState.filteredSubjects.isNotEmpty;
      final hasInstructors = subjectsState.instructorsBySubject.isNotEmpty;

      print(
        '📊 SubjectsTab: hasData=$hasData, hasInstructors=$hasInstructors, isLoading=${subjectsState.isLoading}',
      );
      print(
        '📊 SubjectsTab: ${subjectsState.filteredSubjects.length} subjects, ${subjectsState.instructorsBySubject.length} instructor mappings',
      );

      // Fetch if no data OR if instructors map is empty (even if subjects are cached)
      if ((!hasData || !hasInstructors) && !subjectsState.isLoading) {
        print(
          '🔄 SubjectsTab: Fetching subjects (hasData=$hasData, hasInstructors=$hasInstructors)...',
        );
        ref
            .read(subjectsProvider.notifier)
            .fetchAndFilterSubjects(targetProfile);
      } else if (hasData && hasInstructors) {
        print(
          '✅ SubjectsTab: Reusing data (${subjectsState.filteredSubjects.length} subjects, ${subjectsState.instructorsBySubject.length} instructor mappings) - Zero reads',
        );
      }

      _hasInitialized = true;
    }
  }

  @override
  void didUpdateWidget(SubjectsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh when widget updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeSubjects();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectsProvider);
    final userProfileState = ref.watch(userProfileProvider);

    try {
      // Get the correct profile to use
      final userProfile = userProfileState.userProfile;
      final loggedInUser = userProfileState.loggedInUserProfile;
      final targetProfile = _getTargetProfile(userProfile, loggedInUser);

      // Check if profile or enrolled subjects changed (without triggering refresh in build)
      if (targetProfile != null && _hasInitialized) {
        final currentProfileId = targetProfile.id;
        final currentEnrolledSubjects = targetProfile.enrolledSubjects;

        // Only refresh if profile ID or enrolled subjects actually changed
        if (_lastProfileId != currentProfileId ||
            !_listsEqual(_lastEnrolledSubjects, currentEnrolledSubjects)) {
          // Update tracking variables FIRST to prevent infinite loop
          _lastProfileId = currentProfileId;
          _lastEnrolledSubjects = List.from(currentEnrolledSubjects);

          // Schedule refresh for next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              print('🔄 SubjectsTab: Profile changed, refreshing...');
              ref
                  .read(subjectsProvider.notifier)
                  .fetchAndFilterSubjects(targetProfile);
            }
          });
        }
      } else if (targetProfile != null) {
        // Initialize tracking on first build
        _lastProfileId = targetProfile.id;
        _lastEnrolledSubjects = List.from(targetProfile.enrolledSubjects);
      }

      if (subjectsState.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (subjectsState.error != null) {
        return Center(child: Text('Error: ${subjectsState.error}'));
      }

      final enrolledIds = targetProfile?.enrolledSubjects ?? [];

      final registeredSubjects =
          subjectsState.filteredSubjects
              .where((s) => enrolledIds.contains(s.id))
              .toList();

      // Debug logging for instructors
      print(
        '📚 SubjectsTab: Building UI with ${registeredSubjects.length} subjects and ${subjectsState.instructorsBySubject.length} instructor mappings',
      );
      if (subjectsState.instructorsBySubject.isEmpty &&
          registeredSubjects.isNotEmpty) {
        print(
          '⚠️ SubjectsTab: WARNING - No instructors mapped but subjects exist!',
        );
      }

      final subjectSlivers = buildSubjectsSlivers(
        context,
        registeredSubjects,
        subjectsState.instructorsBySubject,
      );

      return CustomScrollView(slivers: subjectSlivers);
    } catch (e) {
      print('❌ SubjectsTab: Error - $e');
      return const Center(child: Text('لا يمكن تحميل المواد حالياً'));
    }
  }

  // Helper method to compare lists
  bool _listsEqual(List<String>? list1, List<String> list2) {
    if (list1 == null) return false;
    if (list1.length != list2.length) return false;

    final set1 = list1.toSet();
    final set2 = list2.toSet();

    return set1.containsAll(set2) && set2.containsAll(set1);
  }

  UserProfile? _getTargetProfile(
    UserProfile? userProfile,
    UserProfile? loggedInUser,
  ) {
    // If we're viewing someone else's profile, show their subjects
    if (userProfile != null &&
        loggedInUser != null &&
        userProfile.id != loggedInUser.id) {
      return userProfile;
    }

    // Otherwise, show logged-in user's subjects
    return loggedInUser;
  }
}
