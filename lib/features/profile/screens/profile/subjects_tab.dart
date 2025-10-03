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

      // Only fetch if data is not already loaded
      if (!hasData && !subjectsState.isLoading) {
        print('🔄 SubjectsTab: Fetching subjects...');
        ref
            .read(subjectsProvider.notifier)
            .fetchAndFilterSubjects(targetProfile);
      } else if (hasData) {
        print(
          '✅ SubjectsTab: Reusing data from WeekTasks (${subjectsState.filteredSubjects.length} subjects) - Zero reads',
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

      // Reload subjects if profile changes
      if (targetProfile != null && _hasInitialized) {
        final enrolledIds = targetProfile.enrolledSubjects;
        final currentFiltered =
            subjectsState.filteredSubjects.map((s) => s.id).toSet();
        final expectedFiltered = enrolledIds.toSet();

        // If the filtered subjects don't match enrolled subjects, refresh
        if (!currentFiltered.containsAll(expectedFiltered) ||
            !expectedFiltered.containsAll(currentFiltered)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              print('🔄 SubjectsTab: Profile changed, refreshing...');
              ref
                  .read(subjectsProvider.notifier)
                  .fetchAndFilterSubjects(targetProfile);
            }
          });
        }
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
