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
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'لا توجد سكاشن مسجلة لك حالياً',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w500,
                ),
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
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
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
    super.key,
    required this.section,
    required this.subject,
  });

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
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.medium),
                    vertical: Responsive.space(context, size: Space.tiny),
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
                      '/assistant-profile',
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

  void _showSectionDetails(
    BuildContext context,
    Subject subject,
    Section section,
    List<UserProfile> assistants,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
              title: Text(
                subject.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Section details
                  Container(
                    padding: Responsive.padding(context, size: Space.medium),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          context,
                          'السكاشن',
                          section.name,
                          Icons.class_,
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        _buildDetailRow(
                          context,
                          'المكان',
                          section.location,
                          Icons.location_on_outlined,
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        _buildDetailRow(
                          context,
                          'الأيام',
                          section.days,
                          Icons.calendar_today,
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        _buildDetailRow(
                          context,
                          'الوقت',
                          section.time,
                          Icons.access_time,
                        ),
                      ],
                    ),
                  ),

                  if (assistants.isNotEmpty) ...[
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'المعيدين',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    Container(
                      padding: Responsive.padding(context, size: Space.medium),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children:
                            assistants
                                .map(
                                  (assistant) => InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      Navigator.pushNamed(
                                        context,
                                        '/assistant-profile',
                                        arguments: assistant,
                                      );
                                    },
                                    child: Padding(
                                      padding: Responsive.padding(
                                        context,
                                        size: Space.small,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            color: Colors.black87,
                                            size: 20,
                                          ),
                                          SizedBox(
                                            width: Responsive.space(
                                              context,
                                              size: Space.small,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              assistant.name,
                                              style: TextStyle(
                                                fontSize: Responsive.text(
                                                  context,
                                                  size: TextSize.small,
                                                ),
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.grey[400],
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Container(
                      padding: Responsive.padding(context, size: Space.medium),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Expanded(
                            child: Text(
                              'لا يوجد معيدين مسجلين لهذه المادة بعد',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                Center(
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.black87, size: 18),
        SizedBox(width: Responsive.space(context, size: Space.small)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      child: Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          onTap: () {
            // Show more details in a dialog or navigate to details page
            _showSectionDetails(context, subject, section, assistants);
          },
          child: Padding(
            padding: Responsive.padding(context, size: Space.medium),
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios, color: Colors.grey[400], size: 16),
                // Section info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        subject.name,
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      Text(
                        section.name,
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Arrow icon
              ],
            ),
          ),
        ),
      ),
    );
  }
}
