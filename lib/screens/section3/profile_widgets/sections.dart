import 'package:flutter/material.dart';
import 'package:pivot/screens/models/subject.dart';

class Sections extends StatelessWidget {
  Sections({super.key});
  static final id = 'sections';
  final List<SubjectModel> subjects = [
    SubjectModel(doctor: 'احمد حجاج', title: 'Modeling and Simulation'),
    SubjectModel(doctor: 'ايمان منير', title: 'High performance computing'),
    SubjectModel(doctor: 'محمد العربي', title: 'Big data'),
    SubjectModel(doctor: 'مصطفي زغلول', title: 'Neurl Networks'),
    SubjectModel(doctor: 'تامر عباسي', title: 'Numeric Methods'),
    SubjectModel(doctor: 'سارة سويدان', title: 'Machine Learning'),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return subjects[index];
        },
      ),
    );
  }
}
