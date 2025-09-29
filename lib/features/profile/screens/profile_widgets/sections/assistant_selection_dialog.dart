import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/screens/models/instructors_gate.dart';

// Assistant Selection Dialog Widget - Now using InstructorsGate
class AssistantSelectionDialog extends StatefulWidget {
  final Subject subject;
  final Section section;
  final List<UserProfile> assistants;
  final String? selectedAssistantId;
  final Function(String) onAssistantSelected;

  const AssistantSelectionDialog({
    super.key,
    required this.subject,
    required this.section,
    required this.assistants,
    required this.selectedAssistantId,
    required this.onAssistantSelected,
  });

  @override
  State<AssistantSelectionDialog> createState() =>
      _AssistantSelectionDialogState();
}

class _AssistantSelectionDialogState extends State<AssistantSelectionDialog> {
  @override
  Widget build(BuildContext context) {
    // Create a custom config for assistants with selection enabled
    final config = InstructorsGateConfig.assistants.copyWith(
      onInstructorSelected: widget.onAssistantSelected,
    );

    return InstructorsGate(
      subject: widget.subject,
      instructors: widget.assistants,
      config: config,
      selectedInstructorId: widget.selectedAssistantId,
      section: widget.section,
    );
  }
}
