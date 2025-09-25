import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/screens/models/section_card.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/material_link.dart';


List<Widget> buildAssistantSubjects({
  required BuildContext context,
  required List<Subject> subjects,
  required int selectedSubjectIndex,
  required List<Section> sections,
  required Function(int) onCategorySelected,
  required UserProfile loggedInUser,
}) {
  if (subjects.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('لا توجد مواد متاحة حالياً')),
      ),
    ];
  }

  final int validIndex = selectedSubjectIndex.clamp(0, subjects.length - 1);
  final Subject selectedSubject = subjects[validIndex];

  return [
    SliverToBoxAdapter(
      child: SizedBox(height: Responsive.space(context, size: Space.medium)),
    ),
    // SliverToBoxAdapter(
    //   child: SizedBox(
    //     height: Responsive.space(context, size: Space.xlarge) * 1.4,
    //     child: ListView.builder(
    //       scrollDirection: Axis.horizontal,
    //       physics: const BouncingScrollPhysics(),
    //       reverse: true,
    //       itemCount: subjects.length,
    //       itemBuilder: (context, index) {
    //         return CategoryButton(
    //           selected: validIndex == index,
    //           title: subjects[index].name, // Use subject name
    //           onSelected: () {
    //             onCategorySelected(index);
    //           },
    //         );
    //       },
    //     ),
    //   ),
    // ),
    SliverToBoxAdapter(
      child: SizedBox(height: Responsive.space(context, size: Space.medium)),
    ),
    const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
    SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final section = sections[index];
        final sectionNumberFromName = section.name.split(' ').last;
        final bool isCurrentUserSection =
            loggedInUser.section.isNotEmpty &&
            loggedInUser.section.toLowerCase() ==
                sectionNumberFromName.toLowerCase();
        return SectionCard(
          section: section,
          subjectName: selectedSubject.name,
          isCurrentUserSection: isCurrentUserSection,
        );
      }, childCount: sections.length),
    ),
  ];
}
