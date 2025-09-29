import 'package:flutter/material.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/screens/models/category_model.dart';
import 'package:pivot/screens/models/section_card.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';

List<Widget> buildDoctorSubjectsSlivers({
  required BuildContext context,
  required List<Subject> subjects,
  required int selectedSubjectIndex,
  required Function(int) onCategorySelected,
  required SectionProvider sectionProvider,
}) {
  if (subjects.isEmpty) {
    return [
      const SliverFillRemaining(
        child: Center(child: Text('No subjects available.')),
      ),
    ];
  }

  final selectedSubject = subjects[selectedSubjectIndex];
  final sections =
      sectionProvider.sections
          .where((s) => s.subjectId == selectedSubject.id)
          .toList();

  final int validIndex = selectedSubjectIndex.clamp(0, subjects.length - 1);

  return [
    SliverToBoxAdapter(
      child: SizedBox(
        height: Responsive.space(context, size: Space.xlarge) * 1.4,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          reverse: true,
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            return CategoryButton(
              selected: validIndex == index,
              title: subjects[index].name,
              onSelected: () => onCategorySelected(index),
            );
          },
        ),
      ),
    ),
    SliverToBoxAdapter(
      child: SizedBox(height: Responsive.space(context, size: Space.medium)),
    ),
    if (sectionProvider.isLoading)
      const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      )
    else if (sections.isEmpty)
      const SliverFillRemaining(
        child: Center(child: Text('No sections for this subject.')),
      )
    else
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final section = sections[index];
          return SectionCard(
            section: section,
            subjectName: selectedSubject.name,
          );
        }, childCount: sections.length),
      ),
  ];
}
