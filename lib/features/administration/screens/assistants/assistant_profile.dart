import 'package:flutter/material.dart';
import 'profile/assistant_profile_main.dart';

class AssistantProfile extends StatefulWidget {
  final bool isAdmin;

  const AssistantProfile({super.key, this.isAdmin = false});

  @override
  State<AssistantProfile> createState() => _AssistantProfileState();
}

class _AssistantProfileState extends State<AssistantProfile> {
  @override
  Widget build(BuildContext context) {
    return AssistantProfileMain(isAdmin: widget.isAdmin);
  }
}
