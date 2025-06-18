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
    return [
      const SliverFillRemaining(child: Center(child: Text('User not found'))),
    ];
  }

  final userSectionName = userProfile.section;
  final enrolledSubjectIds = enrolledSubjects.map((s) => s.id).toSet();

  final relevantSections =
      allSections.where((section) {
        return enrolledSubjectIds.contains(section.subjectId) &&
            section.name.contains(userSectionName);
      }).toList();

  if (relevantSections.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد سكاشن مسجلة لك حالياً',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  final subjectMap = {
    for (var subject in enrolledSubjects) subject.id: subject,
  };

  return [
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final section = relevantSections[index];
          final subject = subjectMap[section.subjectId];
          if (subject == null) {
            return const SizedBox.shrink();
          }
          return SectionListItem(section: section, subject: subject);
        }, childCount: relevantSections.length),
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
    BuildContext context,
    List<UserProfile> assistants,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('اختار المعيد', textAlign: TextAlign.center),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: assistants.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final assistant = assistants[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  title: Text(
                    assistant.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(
                      context,
                      AssistantProfile.id,
                      arguments: assistant,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
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
    final instructors =
        Provider.of<SubjectProvider>(
          context,
          listen: false,
        ).instructorsBySubject[subject.id];
    final assistants =
        instructors?.where((prof) => prof.role == 'miniProfessor').toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (assistants.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('لا يوجد معيدين مسجلين لهذه المادة بعد'),
                  backgroundColor: Colors.orange.shade800,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(12),
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
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.teal.shade400, width: 5.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.chevron_left,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      Expanded(
                        child: Text(
                          subject.name,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${section.name} - المكان: ${section.location}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize:
                              Responsive.text(context, size: TextSize.small) *
                              1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${section.days} - ${section.time}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize:
                              Responsive.text(context, size: TextSize.small) *
                              1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  if (assistants.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          assistants.length == 1
                              ? assistants.first.name
                              : '${assistants.length} معيد',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize:
                                Responsive.text(context, size: TextSize.small) *
                                1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.teal.shade700,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
