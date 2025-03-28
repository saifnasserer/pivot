import 'package:flutter/material.dart';
import 'package:pivot/screens/models/task_model.dart';

class WeekTasksSection extends StatelessWidget {
  WeekTasksSection({super.key});
  final List<Color> colors = [
    Color(0xff99F16C),
    Color(0xfff5bbbc),
    Color(0xffffef86),
  ];
  List<String> tasks = [
    'قرار الدكتورة فاطمة بشير',
    'مؤسس العلم الحديث',
    'ابن عمي انس',
  ];
  List<String> descriptions = [
    'الدكتورة فاطمة بشير قررت وهذا قرار نابع من قلبها انها هتسقط الدفعه',
    'الطالب سيف ناصر محمود يوسف محم... هو صاحب ومؤسس ومصمم ومدير وقائد ومبرمج وصاحب اسم وفكرة اللوجو وصاحب ومؤسس العلم الحديث هو منشئ هذا التطبيق',
    'انس بشير الطفل زو الشعر الاجعد هو الاشقي في تاريخ المجرات اللتي نعلم بها',
  ];
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return TaskModel(
          date: DateTime.now().add(Duration(days: 7)),
          color: colors[index],
          title: tasks[index],
          description: descriptions[index],
        );
      },
    );
  }
}
