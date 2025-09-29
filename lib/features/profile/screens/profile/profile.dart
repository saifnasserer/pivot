import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_screen.dart';

class Profile extends ConsumerWidget {
  final int? initialTabIndex;

  const Profile({super.key, this.initialTabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfileScreen(initialTabIndex: initialTabIndex);
  }
}
