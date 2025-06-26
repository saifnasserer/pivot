import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/screens/section4/doctor/doctor_profile.dart';

import 'package:pivot/models/user_profile.dart';

List<Widget> buildSubjectsSlivers(
  BuildContext context,
  List<Subject> subjects,
  Map<String, List<UserProfile>> instructorsMap,
) {
  if (subjects.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: Responsive.text(context, size: TextSize.heading) * 2,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'لا يوجد مواد بعد.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  return [
    SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final subject = subjects[index];
          final instructors = instructorsMap[subject.id];
          return SubjectListItem(subject: subject, instructors: instructors);
        }, childCount: subjects.length),
      ),
    ),
  ];
}

class SubjectListItem extends StatelessWidget {
  const SubjectListItem({super.key, required this.subject, this.instructors});

  final Subject subject;
  final List<UserProfile>? instructors;

  void _showSubjectDetails(
    BuildContext context,
    Subject subject,
    List<UserProfile> professors,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
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
                  // Subject details
                  Container(
                    padding: Responsive.padding(context, size: Space.medium),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          'القسم',
                          subject.departments.join(', '),
                          Icons.business,
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        _buildDetailRow(
                          'الترم',
                          subject.year.toString(),
                          Icons.school,
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        _buildDetailRow(
                          'الساعات',
                          subject.hours.toString(),
                          Icons.tag,
                        ),
                      ],
                    ),
                  ),

                  if (professors.isNotEmpty) ...[
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'دكاترة المادة',
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children:
                            professors
                                .map(
                                  (professor) => InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      Navigator.pushNamed(
                                        context,
                                        DoctorProfile.id,
                                        arguments: professor,
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
                                              professor.name,
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
                        borderRadius: BorderRadius.circular(12),
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
                              'لا يوجد دكاترة مسجلين لهذه المادة بعد',
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.black87, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
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
    final professors =
        instructors?.where((prof) => prof.role == 'Professor').toList() ?? [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      child: Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showSubjectDetails(context, subject, professors);
          },
          child: Padding(
            padding: Responsive.padding(context, size: Space.medium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.arrow_back_ios, color: Colors.grey[400], size: 16),
                // Subject info
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
