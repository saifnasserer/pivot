import 'package:flutter/material.dart';
import 'package:pivot/screens/models/subject.dart';
import 'package:pivot/screens/section4/assistants/assistant_profile.dart';

// --- Data defined outside the function (Consider if this data is specific to Sections or shared)
// --- If this is the same data as Subjects, consider moving it to a shared location or model.
final List<SubjectModel> _sectionsData = [
  SubjectModel(
    doctor: 'احمد حجاج',
    title: 'Modeling Section',
    id: AssistantProfile.id,
  ),
  SubjectModel(
    doctor: 'ايمان منير',
    title: 'HPC Section',
    id: AssistantProfile.id,
  ),
  SubjectModel(
    doctor: 'محمد العربي',
    title: 'Big data Section',
    id: AssistantProfile.id,
  ),
  SubjectModel(
    doctor: 'مصطفي زغلول',
    title: 'NN Section',
    id: AssistantProfile.id,
  ),
  SubjectModel(
    doctor: 'تامر عباسي',
    title: 'Numeric Section',
    id: AssistantProfile.id,
  ),
  SubjectModel(
    doctor: 'سارة سويدان',
    title: 'ML Section',
    id: AssistantProfile.id,
  ),
];
// --- End Data ---

// --- Refactored Function returning Slivers ---
List<Widget> buildSectionsSlivers(BuildContext context) {
  // Handle empty state
  if (_sectionsData.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No sections found.')),
      ),
    ];
  }
  return [
    SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return _sectionsData[index];
      }, childCount: _sectionsData.length),
    ),
  ];
}
