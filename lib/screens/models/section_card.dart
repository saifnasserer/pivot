import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/features/administration/screens/assistants/add_edit_section_dialog.dart';
import 'package:provider/provider.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:pivot/responsive.dart';


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

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required BuildContext context,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
        vertical: Responsive.space(context, size: Space.tiny) * 1.2,
      ),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isCurrentUserSection
                ? const Color(0xFF4158D0).withOpacity(0.08)
                : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(
          color:
              isCurrentUserSection
                  ? const Color(0xFF4158D0).withOpacity(0.2)
                  : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                textColor ??
                (isCurrentUserSection
                    ? const Color(0xFF4158D0)
                    : Colors.grey.shade600),
            size: Responsive.text(context, size: TextSize.small) * 1.1,
          ),
          SizedBox(width: Responsive.space(context, size: Space.tiny)),
          Text(
            text,
            style: TextStyle(
              color:
                  textColor ??
                  (isCurrentUserSection
                      ? const Color(0xFF4158D0)
                      : Colors.grey.shade700),
              fontSize: Responsive.text(context, size: TextSize.small) * 0.95,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: Responsive.space(context, size: Space.small) * 0.6,
        horizontal: Responsive.space(context, size: Space.small),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border:
            isCurrentUserSection
                ? const GradientBoxBorder(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                  ),
                  width: 2,
                )
                : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color:
                isCurrentUserSection
                    ? const Color(0xFF4158D0).withOpacity(0.08)
                    : Colors.black.withOpacity(0.04),
            blurRadius: isCurrentUserSection ? 12 : 8,
            offset: const Offset(0, 3),
            spreadRadius: isCurrentUserSection ? 1 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/tasks-control',
                    arguments: section.id,
                  );
                },
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AddEditSectionDialog(
                        subjects: subjects,
                        sectionToEdit: section,
                        autoSelectedSubjectId: section.subjectId,
                        targetAssistantId: section.assistantId,
                      );
                    },
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium) * 1.1,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Header with title and actions
                      Row(
                        children: [
                          // Status indicator
                          if (isCurrentUserSection) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF4158D0),
                                    Color(0xFFC850C0),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                          ],

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  section.name,
                                  style: TextStyle(
                                    fontSize:
                                        Responsive.text(
                                          context,
                                          size: TextSize.medium,
                                        ) *
                                        1.15,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isCurrentUserSection
                                            ? const Color(0xFF2D3748)
                                            : Colors.grey.shade800,
                                    height: 1.2,
                                  ),
                                ),
                                if (isCurrentUserSection) ...[
                                  SizedBox(
                                    height:
                                        Responsive.space(
                                          context,
                                          size: Space.tiny,
                                        ) *
                                        0.5,
                                  ),
                                  Text(
                                    'سكشنك',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.text(
                                            context,
                                            size: TextSize.small,
                                          ) *
                                          0.9,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF4158D0),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          if (canDelete) ...[
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.large),
                              ),
                              onTap:
                                  () => _showDeleteConfirmation(
                                    context,
                                    section.id,
                                  ),
                              child: Container(
                                padding: EdgeInsets.all(
                                  Responsive.space(context, size: Space.small) *
                                      0.8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),
                                  border: Border.all(
                                    color: Colors.red.shade100,
                                    width: 0.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red.shade400,
                                  size:
                                      Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ) *
                                      1.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Info chips
                      Wrap(
                        spacing:
                            Responsive.space(context, size: Space.small) * 0.8,
                        runSpacing:
                            Responsive.space(context, size: Space.small) * 0.6,
                        children: [
                          _buildInfoChip(
                            icon: Icons.access_time_rounded,
                            text: '${section.days} - ${section.time}',
                            context: context,
                          ),
                          _buildInfoChip(
                            icon: Icons.location_on_rounded,
                            text: section.location,
                            context: context,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String sectionId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.large) * 1.2,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: Responsive.space(context, size: Space.large) * 1.2,
                  height: Responsive.space(context, size: Space.large) * 1.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade50, Colors.red.shade100],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade200, width: 2),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade500,
                    size: Responsive.space(context, size: Space.large) * 1.2,
                  ),
                ),

                SizedBox(
                  height: Responsive.space(context, size: Space.medium) * 1.2,
                ),

                // Title
                Text(
                  'حذف السكشن',
                  style: TextStyle(
                    fontSize:
                        Responsive.text(context, size: TextSize.heading) * 1.1,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),

                SizedBox(
                  height: Responsive.space(context, size: Space.small) * 1.2,
                ),

                // Content
                Text(
                  'هل إنت متأكد إنك عايز تمسح السكشن ده؟\nمش هتقدر ترجعه تاني',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),

                SizedBox(
                  height: Responsive.space(context, size: Space.large) * 1.2,
                ),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                          ),
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical:
                                Responsive.space(context, size: Space.medium) *
                                1.1,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'لأ، إلغاء',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize:
                                Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ) *
                                0.95,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small) * 1.2,
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                          ),
                          backgroundColor: Colors.red.shade500,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.red.shade200,
                          padding: EdgeInsets.symmetric(
                            vertical:
                                Responsive.space(context, size: Space.medium) *
                                1.1,
                          ),
                        ),
                        onPressed: () {
                          context.read<SectionProvider>().deleteSection(
                            sectionId,
                          );
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'امسح',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize:
                                Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ) *
                                0.95,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
