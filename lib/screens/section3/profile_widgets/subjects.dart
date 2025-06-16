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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      onPressed:
          () => Navigator.pushNamed(
            context,
            DoctorProfile.id,
            arguments: subject.id,
          ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    subject.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: Responsive.text(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (instructors != null && instructors!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'المدرسون: ${instructors!.map((i) => i.name).join(', ')}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize:
                              Responsive.text(context, size: TextSize.small) *
                              1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Text(
                    '${subject.department} - ${subject.year}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize:
                          Responsive.text(context, size: TextSize.small) * 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: Responsive.space(context)),
            Container(
              width: Responsive.space(context, size: Space.large) * 3,
              height: Responsive.space(context, size: Space.large) * 3,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: Responsive.space(context, size: Space.xlarge),
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
