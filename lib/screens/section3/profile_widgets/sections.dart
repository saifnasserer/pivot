import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section4/assistants/assistant_profile.dart';
import 'package:provider/provider.dart';

List<Widget> buildSectionsSlivers(BuildContext context) {
  final userProfileProvider = Provider.of<UserProfileProvider>(context);
  final sectionProvider = Provider.of<SectionProvider>(context);
  final subjectProvider = Provider.of<SubjectProvider>(context);

  // Wait for all required data to be loaded.
  if (userProfileProvider.isLoading || sectionProvider.isLoading) {
    return [
      const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
    ];
  }

  final userProfile = userProfileProvider.userProfile;
  final allSections = sectionProvider.sections;
  final enrolledSubjects = subjectProvider.filteredSubjects;

  if (userProfile == null) {
    return [const SliverFillRemaining(child: Center(child: Text('User not found')))];
  }

  final userSectionName = userProfile.section;
  final enrolledSubjectIds = enrolledSubjects.map((s) => s.id).toSet();

  final relevantSections = allSections.where((section) {
    // Match if the section name (e.g., 'سكشن 3') contains the user's section number (e.g., '3')
    return enrolledSubjectIds.contains(section.subjectId) && section.name.contains(userSectionName);
  }).toList();

  if (relevantSections.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('لا توجد سكاشن مسجلة لك حالياً')),
      ),
    ];
  }

  final subjectMap = {for (var subject in enrolledSubjects) subject.id: subject};

  return [
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final section = relevantSections[index];
          final subject = subjectMap[section.subjectId];
          if (subject == null) {
            return const SizedBox.shrink();
          }
          return SectionListItem(section: section, subject: subject);
        },
        childCount: relevantSections.length,
      ),
    ),
  ];
}

class SectionListItem extends StatelessWidget {
  const SectionListItem({
    Key? key,
    required this.section,
    required this.subject,
  }) : super(key: key);

  final Section section;
  final Subject subject;

  void _showAssistantSelectionDialog(
      BuildContext context, List<UserProfile> assistants) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختار المعيد'),
          content: SingleChildScrollView(
            child: ListBody(
              children: assistants.map((assistant) {
                return ListTile(
                  title: Text(assistant.name),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(
                      context,
                      AssistantProfile.id,
                      arguments: assistant,
                    );
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final instructors = Provider.of<SubjectProvider>(context, listen: false)
        .instructorsBySubject[subject.id];
    final assistants =
        instructors?.where((prof) => prof.role == 'miniProfessor').toList() ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (assistants.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('لا يوجد معيدين مسجلين لهذه المادة بعد'),
                  backgroundColor: Colors.orange,
                ),
              );
            } else if (assistants.length == 1) {
              Navigator.pushNamed(
                context,
                AssistantProfile.id,
                arguments: assistants.first,
              );
            } else {
              _showAssistantSelectionDialog(context, assistants);
            }
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
                        vertical: 16.0, horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          subject.name,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize:
                                Responsive.text(context, size: TextSize.medium),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '${section.name} - المكان: ${section.location}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize:
                                Responsive.text(context, size: TextSize.small) *
                                    1.3,
                          ),
                        ),
                        Text(
                          'المواعيد: ${section.days} - ${section.time}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize:
                                Responsive.text(context, size: TextSize.small) *
                                    1.3,
                          ),
                        ),
                        if (assistants.isNotEmpty) ...[
                          const SizedBox(height: 12.0),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: assistants
                                .map((p) => Chip(
                                      label: Text(
                                        p.name,
                                        style: TextStyle(
                                          fontSize: Responsive.text(context,
                                                  size: TextSize.small) *
                                              1.1,
                                        ),
                                      ),
                                      backgroundColor: Colors.grey.shade200,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0, vertical: 0),
                                      labelPadding: const EdgeInsets.only(
                                          left: 4, right: 2),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ))
                                .toList(),
                          )
                        ],
                      ],
                    ),
                  ),
                ),

                // Accent bar
                Container(
                  width: 8.0,
                  color: Colors.teal, // A different color for sections
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
