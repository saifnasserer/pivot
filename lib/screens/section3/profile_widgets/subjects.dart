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

  void _showProfessorSelectionDialog(
    BuildContext context,
    List<UserProfile> professors,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.medium),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: Responsive.space(context, size: Space.medium),
                    spreadRadius: Responsive.space(context, size: Space.small),
                  ),
                ],
              ),
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.large),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'اختار دكتور المادة',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.text(
                        context,
                        size: TextSize.heading,
                      ),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  ...professors.map((prof) {
                    return Card(
                      elevation: 0,
                      color: Colors.transparent,
                      margin: EdgeInsets.only(
                        bottom: Responsive.space(context, size: Space.small),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(
                            context,
                            DoctorProfile.id,
                            arguments: prof,
                          );
                        },
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.small),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                            Responsive.space(context, size: Space.medium),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                radius: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  prof.name,
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Divider(height: Responsive.space(context, size: Space.small)),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.medium),
                        ),
                        side: BorderSide(
                          color: Colors.redAccent.withOpacity(0.5),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.space(context, size: Space.medium),
                      ),
                    ),
                    child: Text(
                      'إلغاء',
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
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final professors =
        instructors?.where((prof) => prof.role == 'Professor').toList() ?? [];
    final hasProfessors = professors.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.medium),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: Responsive.space(context, size: Space.medium),
              offset: Offset(0, Responsive.space(context, size: Space.small)),
              spreadRadius: Responsive.space(context, size: Space.small) / 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (!hasProfessors) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.white),
                        SizedBox(
                          width: Responsive.space(context, size: Space.medium),
                        ),
                        Text('لا يوجد دكاترة مسجلين لهذه المادة بعد'),
                      ],
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.small),
                      ),
                    ),
                    margin: EdgeInsets.all(
                      Responsive.space(context, size: Space.medium),
                    ),
                  ),
                );
                return;
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
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Colors.white, Theme.of(context).colorScheme.surface],
                ),
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: Responsive.space(context, size: Space.small),
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.medium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.medium),
                            ),
                          ),
                          padding: EdgeInsets.all(
                            Responsive.space(context, size: Space.small),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: Responsive.text(
                              context,
                              size: TextSize.heading,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                subject.name,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.heading,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              // SizedBox(
                              //   height: Responsive.space(
                              //     context,
                              //     size: Space.small,
                              //   ),
                              // ),
                              // Container(
                              //   padding: EdgeInsets.symmetric(
                              //     horizontal: Responsive.space(
                              //       context,
                              //       size: Space.medium,
                              //     ),
                              //     vertical: Responsive.space(
                              //       context,
                              //       size: Space.small,
                              //     ),
                              //   ),
                              //   decoration: BoxDecoration(
                              //     color:
                              //         Theme.of(
                              //           context,
                              //         ).colorScheme.primaryContainer,
                              //     borderRadius: BorderRadius.circular(
                              //       Responsive.space(
                              //         context,
                              //         size: Space.medium,
                              //       ),
                              //     ),
                              //   ),
                              //   child: Text(
                              //     '${subject.department} - ${subject.year}',
                              //     textAlign: TextAlign.right,
                              //     style: TextStyle(
                              //       color:
                              //           Theme.of(context).colorScheme.primary,
                              //       fontWeight: FontWeight.bold,
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (hasProfessors) ...[
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: Responsive.space(context, size: Space.medium),
                        runSpacing: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
                        children:
                            professors
                                .map(
                                  (p) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.space(
                                        context,
                                        size: Space.medium,
                                      ),
                                      vertical: Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(
                                        Responsive.space(
                                          context,
                                          size: Space.medium,
                                        ),
                                      ),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          p.name,
                                          style: TextStyle(
                                            fontSize:
                                                Responsive.text(
                                                  context,
                                                  size: TextSize.small,
                                                ) *
                                                1.1,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(
                                          width: Responsive.space(
                                            context,
                                            size: Space.small,
                                          ),
                                        ),
                                        Icon(
                                          Icons.person_outline,
                                          size: Responsive.text(
                                            context,
                                            size: TextSize.small,
                                          ),
                                          color: Colors.grey.shade700,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
