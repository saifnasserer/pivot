import 'package:flutter/material.dart';

import 'edit_profile_screen.dart';

/// Edit Profile entry point
/// Uses Riverpod provider (editProfileProvider) defined in
/// lib/features/profile/providers/edit_profile_provider.dart
class EditProfile extends StatelessWidget {
  const EditProfile({super.key});

  @override
  Widget build(BuildContext context) {
    // The EditProfileScreen is a ConsumerStatefulWidget that directly
    // accesses the editProfileProvider, so no provider wrapping needed
    return Directionality(
      textDirection: TextDirection.rtl,
      child: const EditProfileScreen(),
    );
  }
}
