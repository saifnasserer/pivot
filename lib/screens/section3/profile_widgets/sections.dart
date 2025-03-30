import 'package:flutter/material.dart';
import 'package:pivot/screens/models/subject.dart';

// --- Data defined outside the function (Consider if this data is specific to Sections or shared)
// --- If this is the same data as Subjects, consider moving it to a shared location or model.
final List<SubjectModel> _sectionsData = [
  SubjectModel(doctor: 'احمد حجاج', title: 'Modeling Section'), 
  SubjectModel(doctor: 'ايمان منير', title: 'HPC Section'),
  SubjectModel(doctor: 'محمد العربي', title: 'Big data Section'),
  SubjectModel(doctor: 'مصطفي زغلول', title: 'NN Section'),
  SubjectModel(doctor: 'تامر عباسي', title: 'Numeric Section'),
  SubjectModel(doctor: 'سارة سويدان', title: 'ML Section'),
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
      )
    ];
  }

  // Return a list containing a SliverList
  return [
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Assuming SubjectModel is a Widget or has a builder method
          return _sectionsData[index]; 
        },
        childCount: _sectionsData.length,
      ),
    ),
  ];
}
// --- End Refactored Function ---
