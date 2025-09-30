import 'package:flutter/material.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';

import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/features/profile/screens/profile_widgets/subjects.dart';

class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key});

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  @override
  void initState() {
    super.initState();
    // Set up profile restoration listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProfileProvider = context.read<UserProfileProvider>();
        userProfileProvider.setOnProfileRestored(() {
          if (mounted) {
            final loggedInUser = userProfileProvider.loggedInUserProfile;
            if (loggedInUser != null) {
              final subjectProvider = context.read<SubjectProvider>();
              subjectProvider.updateFilteredSubjectsOnly(loggedInUser);
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, child) {
        try {
          if (subjectProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (subjectProvider.error != null) {
            return Center(child: Text('Error: ${subjectProvider.error}'));
          }

          // Get the correct profile to use
          final userProfileProvider = context.read<UserProfileProvider>();
          final userProfile = userProfileProvider.userProfile;
          final loggedInUser = userProfileProvider.loggedInUserProfile;

          // Determine which profile to use based on context
          final targetProfile = _getTargetProfile(userProfile, loggedInUser);
          final enrolledIds = targetProfile?.enrolledSubjects ?? [];

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
        } catch (e) {
          return const Center(child: Text('لا يمكن تحميل المواد حالياً'));
        }
      },
    );
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
