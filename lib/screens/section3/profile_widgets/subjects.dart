import 'package:flutter/material.dart';
import 'package:pivot/screens/models/subject.dart';
import 'package:pivot/screens/section4/doctor/doctor_profile.dart';

final List<SubjectModel> _subjectsData = [
  SubjectModel(
    doctor: 'احمد حجاج',
    title: 'Modeling and Simulation',
    id: DoctorProfile.id,
  ),
  SubjectModel(
    doctor: 'ايمان منير',
    title: 'High performance computing',
    id: DoctorProfile.id,
  ),
  SubjectModel(doctor: 'محمد العربي', title: 'Big data', id: DoctorProfile.id),
  SubjectModel(
    doctor: 'مصطفي زغلول',
    title: 'Neurl Networks',
    id: DoctorProfile.id,
  ),
  SubjectModel(
    doctor: 'تامر عباسي',
    title: 'Numeric Methods',
    id: DoctorProfile.id,
  ),
  SubjectModel(
    doctor: 'سارة سويدان',
    title: 'Machine Learning',
    id: DoctorProfile.id,
  ),
];

List<Widget> buildSubjectsSlivers(BuildContext context) {
  if (_subjectsData.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No subjects found.')),
      ),
    ];
  }

  return [
    SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return _subjectsData[index];
      }, childCount: _subjectsData.length),
    ),
  ];
}
