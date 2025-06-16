import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';

List<Widget> buildSectionsSlivers(
  BuildContext context,
  List<Section> sections,
  List<Subject> subjects,
) {
  if (sections.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('لا توجد سكاشن مسجلة حالياً')),
      ),
    ];
  }

  // Create a map of subjectId to subjectName for easy lookup
  final subjectMap = {for (var subject in subjects) subject.id: subject.name};

  // Group sections by subjectId
  final groupedSections = <String, List<Section>>{};
  for (var section in sections) {
    if (!groupedSections.containsKey(section.subjectId)) {
      groupedSections[section.subjectId] = [];
    }
    groupedSections[section.subjectId]!.add(section);
  }

  final List<Widget> slivers = [];

  groupedSections.forEach((subjectId, sectionList) {
    final subjectName = subjectMap[subjectId] ?? 'مادة غير معروفة';

    // Add a header for the subject
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.space(context, size: Space.medium),
            horizontal: Responsive.space(context, size: Space.small),
          ),
          child: Text(
            subjectName,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );

    // Add the list of sections for this subject
    slivers.add(
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final section = sectionList[index];
          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(
              vertical: Responsive.space(context, size: Space.small) / 2,
              horizontal: Responsive.space(context, size: Space.small),
            ),
            child: ListTile(
              title: Text(
                section.name,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'المكان: ${section.location}',
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    'المواعيد: ${section.days} - ${section.time}',
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              leading: const Icon(Icons.class_outlined),
            ),
          );
        }, childCount: sectionList.length),
      ),
    );
  });

  return slivers;
}
