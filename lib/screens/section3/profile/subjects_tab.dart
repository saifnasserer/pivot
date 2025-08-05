import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section3/profile_widgets/subjects.dart';

class SubjectsTab extends StatelessWidget {
  const SubjectsTab({super.key});

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

          // Filter subjects to only those registered/enrolled by the user
          // Use context.read to avoid unnecessary rebuilds
          final userProfile = context.read<UserProfileProvider>().userProfile;
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
        } catch (e) {
          print('Warning: SubjectProvider disposed in SubjectsTab: $e');
          return const Center(child: Text('لا يمكن تحميل المواد حالياً'));
        }
      },
    );
  }
}
