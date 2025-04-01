import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/category_model.dart';
import 'package:pivot/screens/models/section_card.dart';
import 'package:pivot/screens/models/section_info.dart'; // Import the correct model

List<Widget> buildAssistantSubjects({
  required BuildContext context,
  required List<String> subjectCategories,
  required int selectedSubjectIndex,
  required List<SectionInfo>
  sections, // New parameter: List for selected subject
  required Function(int) onCategorySelected,
}) {
  // --- Guard Clause ---
  // If there are no subject categories, return an empty state sliver
  if (subjectCategories.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('مفيش مواد حالياً')),
      ),
    ];
  }
  // --- End Guard Clause ---

  // Ensure the index is valid before accessing the list
  // Although the error was about length 0, this adds robustness
  final int validIndex = selectedSubjectIndex.clamp(
    0,
    subjectCategories.length - 1,
  );
  final String selectedCategory = subjectCategories[validIndex];

  return [
    SliverToBoxAdapter(
      child: SizedBox(height: Responsive.space(context, size: Space.medium)),
    ),
    SliverToBoxAdapter(
      child: SizedBox(
        height: Responsive.space(context, size: Space.xlarge) * 1.4,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          reverse: true,
          itemCount: subjectCategories.length,
          itemBuilder: (context, index) {
            return CategoryButton(
              selected: validIndex == index,
              title: subjectCategories[index],
              onSelected: () {
                onCategorySelected(index);
              },
            );
          },
        ),
      ),
    ),
    SliverToBoxAdapter(
      child: SizedBox(height: Responsive.space(context, size: Space.medium)),
    ),
    SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),

    // Use SliverList to display SectionCards dynamically
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final section = sections[index]; // Use the passed list directly
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.space(context, size: Space.medium),
            ),
            child: SectionCard(
              // Use the correct class name
              sectionId: section.id,
              subjectName: selectedCategory, // Pass the currently selected subject name
              title: section.title,
              days: section.days,
              location: section.location,
              time: section.time,
            ),
          );
        },
        childCount: sections.length, // Use the length of the passed list
      ),
    ),
  ];
}
