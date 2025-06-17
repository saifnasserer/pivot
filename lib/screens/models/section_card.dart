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
  final bool isCurrentUserSection;

  const SectionCard({
    super.key,
    required this.section,
    required this.subjectName,
    this.isCurrentUserSection = false,
  });

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: Responsive.text(context, size: TextSize.small) * 1.2,
          ),
        ),
        const SizedBox(width: 6.0),
        Icon(icon, color: Colors.grey.shade600, size: 16.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.read<SubjectProvider>().filteredSubjects;
    final userProfile =
        context.watch<UserProfileProvider>().loggedInUserProfile;

    final bool canDelete =
        userProfile != null &&
        userProfile.role != 'Student' &&
        userProfile.role != 'Professor';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chevron icon
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.grey.shade500,
                  size: 16,
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              section.name,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (canDelete)
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 22,
                              ),
                              onPressed: () => _showDeleteConfirmation(
                                context,
                                section.id,
                              ),
                              padding: const EdgeInsets.only(left: 8, right: 0),
                              constraints: const BoxConstraints(),
                              splashRadius: 22,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        subjectName,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize:
                              Responsive.text(context, size: TextSize.small) *
                                  1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      _buildDetailRow(
                        context,
                        icon: Icons.access_time_filled,
                        text: '${section.days} - ${section.time}',
                      ),
                      const SizedBox(height: 4.0),
                      _buildDetailRow(
                        context,
                        icon: Icons.location_on,
                        text: section.location,
                      ),
                    ],
                  ),
                ),
              ),

              // Accent bar
              Container(
                width: 8.0,
                color: isCurrentUserSection
                    ? Theme.of(context).primaryColor
                    : Colors.teal,
              ),
            ],
          ),
        ),
      ),
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
