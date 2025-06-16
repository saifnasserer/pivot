import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section4/assistants/add_edit_section_dialog.dart';
import 'package:pivot/screens/section4/assistants/all_tasks.dart';
import 'package:provider/provider.dart';

class SectionCard extends StatelessWidget {
  final Section section;
  final String subjectName;

  const SectionCard({
    super.key,
    required this.section,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    final subjects = context.read<SubjectProvider>().filteredSubjects;
    final userProfile =
        context.watch<UserProfileProvider>().loggedInUserProfile;

    final bool canDelete =
        userProfile != null &&
        userProfile.role != 'Student' &&
        userProfile.role != 'Professor';

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              TasksControl.id,
              arguments: section.id, // Pass sectionId as an argument
            );
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AddEditSectionDialog(
                  subjects: subjects,
                  sectionToEdit: section,
                  initialSubjectId: section.subjectId,
                );
              },
            );
          },
          child: Container(
            margin: EdgeInsets.only(bottom: Responsive.space(context)),
            padding: EdgeInsets.all(Responsive.space(context)),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                Responsive.space(context) * 0.8,
              ),
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Section Title (Prominent)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: Responsive.text(context),
                      color: Colors.black54,
                    ),
                    SizedBox(width: Responsive.space(context) * 0.5),
                    Text(
                      section.location,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: Responsive.text(context) * 0.95,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      section.name, // Use section.name for the title
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: Responsive.text(context) * 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed:
                            () => _showDeleteConfirmation(context, section.id),
                      ),
                  ],
                ),
                SizedBox(height: Responsive.space(context) * 0.75),

                // Days Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: Responsive.text(context),
                      color: Colors.black54,
                    ),
                    SizedBox(width: Responsive.space(context) * 0.5),
                    Text(
                      section.time,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: Responsive.text(context) * 0.95,
                      ),
                    ),
                    SizedBox(width: Responsive.space(context)),
                    Expanded(
                      child: Text(
                        textAlign: TextAlign.right,
                        section.days,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: Responsive.text(context) * 0.95,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, String sectionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Section'),
          content: const Text('Are you sure you want to delete this section?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                context.read<SectionProvider>().deleteSection(sectionId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
