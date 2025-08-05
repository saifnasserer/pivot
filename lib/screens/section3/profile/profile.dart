import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'profile_provider.dart';
import 'profile_screen.dart';

class Profile extends StatefulWidget {
  final int? initialTabIndex;

  const Profile({super.key, this.initialTabIndex});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => ProfileProvider(
            userProfileProvider: context.read<UserProfileProvider>(),
            scheduleProvider: context.read<ScheduleProvider>(),
            taskProvider: context.read<TaskProvider>(),
            subjectProvider: context.read<SubjectProvider>(),
            sectionProvider: context.read<SectionProvider>(),
          ),
      child: ProfileScreen(initialTabIndex: widget.initialTabIndex),
    );
  }
}
