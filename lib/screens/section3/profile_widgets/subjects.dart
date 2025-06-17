import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/screens/section4/doctor/doctor_profile.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/models/user_profile.dart';

List<Widget> buildSubjectsSlivers(
  BuildContext context,
  List<Subject> subjects,
) {
  if (subjects.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'You are not enrolled in any subjects yet.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      ),
    ];
  }

  final instructorsMap =
      Provider.of<SubjectProvider>(context, listen: false).instructorsBySubject;

  return [
    SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final subject = subjects[index];
        final instructors = instructorsMap[subject.id];
        return SubjectListItem(subject: subject, instructors: instructors);
      }, childCount: subjects.length),
    ),
  ];
}

class SubjectListItem extends StatelessWidget {
  const SubjectListItem({Key? key, required this.subject, this.instructors})
    : super(key: key);

  final Subject subject;
  final List<UserProfile>? instructors;

  void _showProfessorSelectionDialog(
    BuildContext context,
    List<UserProfile> professors,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SimpleDialog(
            title: const Text(
              'اختر أستاذ المادة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            children: [
              ...professors.map((prof) {
                return SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.pushNamed(
                      context,
                      DoctorProfile.id,
                      arguments: prof,
                    );
                  },
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 24.0,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Text(
                          prof.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            if (instructors == null || instructors!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('لا يوجد دكاترة مسجلين لهذه المادة بعد'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            final professors =
                instructors!.where((prof) => prof.role == 'Professor').toList();

            if (professors.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('لا يوجد دكاترة مسجلين لهذه المادة بعد'),
                  backgroundColor: Colors.orange,
                ),
              );
            } else if (professors.length == 1) {
              Navigator.pushNamed(
                context,
                DoctorProfile.id,
                arguments: professors.first,
              );
            } else {
              _showProfessorSelectionDialog(context, professors);
            }
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Chevron icon (on the left)
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.grey.shade500,
                    size: 16,
                  ),
                ),

                // Main content (in the middle)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          subject.name,
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
                        const SizedBox(height: 4.0),
                        Text(
                          '${subject.department} - ${subject.year}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize:
                                Responsive.text(context, size: TextSize.small) *
                                1.3,
                          ),
                        ),
                        if (instructors != null && instructors!.isNotEmpty) ...[
                          const SizedBox(height: 12.0),
                          Builder(
                            builder: (context) {
                              final professors =
                                  instructors!
                                      .where((i) => i.role == 'Professor')
                                      .toList();
                              if (professors.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children:
                                    professors
                                        .map(
                                          (p) => Chip(
                                            // avatar: CircleAvatar(
                                            //   backgroundColor:
                                            //       Colors.grey.shade700,
                                            //   child: Text(
                                            //     p.name.substring(0, 1),
                                            //     style: const TextStyle(
                                            //         color: Colors.white,
                                            //         fontSize: 10),
                                            //   ),
                                            // ),
                                            label: Text(
                                              p.name,
                                              style: TextStyle(
                                                fontSize:
                                                    Responsive.text(
                                                      context,
                                                      size: TextSize.small,
                                                    ) *
                                                    1.1,
                                              ),
                                            ),
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0,
                                              vertical: 0,
                                            ),
                                            labelPadding: const EdgeInsets.only(
                                              left: 4,
                                              right: 2,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        )
                                        .toList(),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Accent bar (on the right)
                Container(width: 8.0, color: Theme.of(context).primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
