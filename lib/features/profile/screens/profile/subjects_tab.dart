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
  @override
  void initState() {
    super.initState();
    // Subjects will auto-load through Riverpod
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectsProvider);
    final userProfileState = ref.watch(userProfileProvider);

    try {
      if (subjectsState.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (subjectsState.error != null) {
        return Center(child: Text('Error: ${subjectsState.error}'));
      }

      // Get the correct profile to use
      final userProfile = userProfileState.userProfile;
      final loggedInUser = userProfileState.loggedInUserProfile;

      // Determine which profile to use based on context
      final targetProfile = _getTargetProfile(userProfile, loggedInUser);
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
