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
            color: Colors.grey.shade600,
            fontSize: Responsive.text(context, size: TextSize.small) * 1.1,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: Responsive.space(context, size: Space.small)),
        Icon(
          icon,
          color: Colors.grey.shade500,
          size: Responsive.text(context, size: TextSize.small) * 1.2,
        ),
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

    final accentColor =
        isCurrentUserSection
            ? Theme.of(context).primaryColor
            : Colors.teal.shade400;

    return Card(
      margin: EdgeInsets.symmetric(
        vertical: Responsive.space(context, size: Space.small),
        horizontal: Responsive.space(context, size: Space.small),
      ),
      elevation: 0.8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        side: BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, TasksControl.id, arguments: section.id);
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Chevron container
                Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.small),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.grey.shade400,
                      size:
                          Responsive.text(context, size: TextSize.small) * 0.8,
                    ),
                  ),
                ),
                // Main content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: Responsive.space(context, size: Space.medium),
                      horizontal: Responsive.space(context, size: Space.medium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (canDelete)
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade300,
                                  size: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                ),
                                onPressed:
                                    () => _showDeleteConfirmation(
                                      context,
                                      section.id,
                                    ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
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
                          ],
                        ),

                        SizedBox(
                          height:
                              Responsive.space(context, size: Space.small) *
                              1.2,
                        ),
                        _buildDetailRow(
                          context,
                          icon: Icons.access_time_rounded,
                          text: '${section.days} - ${section.time}',
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        _buildDetailRow(
                          context,
                          icon: Icons.location_on_rounded,
                          text: section.location,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: Responsive.space(context, size: Space.small),
                  color: accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String sectionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final borderRadius = BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        );
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          elevation: 8,
          backgroundColor: Colors.white,
          titlePadding: EdgeInsets.only(
            top: Responsive.space(context, size: Space.large),
            left: Responsive.space(context, size: Space.large),
            right: Responsive.space(context, size: Space.large),
            bottom: Responsive.space(context, size: Space.small),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'حذف السكشن',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.text(context, size: TextSize.heading),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              Divider(
                thickness: 1,
                height: Responsive.space(context, size: Space.tiny),
              ),
            ],
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.medium),
            vertical: Responsive.space(context, size: Space.small),
          ),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'هل أنت متأكد من رغبتك في حذف هذا السكشن؟',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
              ),
            ),
          ),
          actionsPadding: EdgeInsets.only(
            left: Responsive.space(context, size: Space.large),
            right: Responsive.space(context, size: Space.large),
            bottom: Responsive.space(context, size: Space.large),
            top: Responsive.space(context, size: Space.small),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.medium),
                    ),
                  ),
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.space(context, size: Space.small),
                  ),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                  ),
                ),
                child: const Text('لا'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.medium),
                    ),
                  ),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.space(context, size: Space.small),
                  ),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                  ),
                  elevation: 0,
                ),
                child: const Text('متأكد'),
                onPressed: () {
                  context.read<SectionProvider>().deleteSection(sectionId);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
