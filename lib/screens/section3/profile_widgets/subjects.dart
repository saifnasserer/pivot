import 'package:flutter/material.dart';
import 'package:pivot/screens/models/subject.dart';

final List<SubjectModel> _subjectsData = [
  SubjectModel(doctor: 'احمد حجاج', title: 'Modeling and Simulation'),
  SubjectModel(doctor: 'ايمان منير', title: 'High performance computing'),
  SubjectModel(doctor: 'محمد العربي', title: 'Big data'),
  SubjectModel(doctor: 'مصطفي زغلول', title: 'Neurl Networks'),
  SubjectModel(doctor: 'تامر عباسي', title: 'Numeric Methods'),
  SubjectModel(doctor: 'سارة سويدان', title: 'Machine Learning'),
];

List<Widget> buildSubjectsSlivers(BuildContext context) {
  if (_subjectsData.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No subjects found.')),
      )
    ];
  }

  return [
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return _subjectsData[index]; 
        },
        childCount: _subjectsData.length,
      ),
    ),
  ];
}
