import 'package:flutter/material.dart';
import 'package:pivot/providers/settings_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';

import 'edit_profile_provider.dart';
import 'edit_profile_screen.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => EditProfileProvider(
            userProfileProvider: context.read<UserProfileProvider>(),
            settingsProvider: context.read<SettingsProvider>(),
          ),
      child: const EditProfileScreen(),
    );
  }
}
