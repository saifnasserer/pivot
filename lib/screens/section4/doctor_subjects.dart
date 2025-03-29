import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/category_model.dart';
import 'package:pivot/screens/models/subject.dart';

List<Widget> buildDoctorSubjectsSlivers({
  required BuildContext context,
  required List<String> subjectCategories,
  required int selectedSubjectIndex,
  required Map<String, List<SubjectModel>> subjectsData,
  required Function(int) onCategorySelected,
}) {
  // --- Guard Clause ---
  // If there are no subject categories, return an empty state sliver
  if (subjectCategories.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No subject categories found.')),
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
  final List<SubjectModel> lectures = subjectsData[selectedCategory] ?? [];

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

    lectures.isEmpty
        ? SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'لا توجد محاضرات لهذه المادة',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey,
              ),
            ),
          ),
        )
        : SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return lectures[index];
          }, childCount: lectures.length),
        ),
  ];
}
