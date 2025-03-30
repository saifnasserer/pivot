import 'package:flutter/material.dart';
import 'package:pivot/screens/models/task_model.dart';

// --- Data defined outside the function ---
final List<Color> _taskColors = [
  Color.fromARGB(255, 93, 148, 66),
  Color.fromARGB(255, 165, 92, 93),
  Color.fromARGB(255, 218, 198, 68),
];
final List<String> _taskTitles = [
  'قرار الدكتورة فاطمة بشير',
  'مؤسس العلم الحديث',
  'ابن عمي انس',
];
final List<String> _taskDescriptions = [
  'الدكتورة فاطمة بشير قررت وهذا قرار نابع من قلبها انها هتسقط الدفعه',
  'الطالب سيف ناصر محمود يوسف محم... هو صاحب ومؤسس ومصمم ومدير وقائد ومبرمج وصاحب اسم وفكرة اللوجو وصاحب ومؤسس العلم الحديث هو منشئ هذا التطبيق',
  'انس بشير الطفل زو الشعر الاجعد هو الاشقي في تاريخ المجرات اللتي نعلم بها',
];
// --- End Data ---

// --- Refactored Function returning Slivers ---
List<Widget> buildWeekTasksSlivers(BuildContext context) {
  // Determine the number of tasks (should be consistent across lists)
  final int taskCount = _taskTitles.length; 

  if (taskCount == 0) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No tasks for the week.')),
      )
    ];
  }

  return [
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return TaskModel(
            // Make sure date logic is appropriate, maybe pass as argument?
            date: DateTime.now().add(Duration(days: index + 1)), // Example: days increment
            color: _taskColors[index % _taskColors.length], // Use modulo for safety
            title: _taskTitles[index],
            description: _taskDescriptions[index],
          );
        },
        childCount: taskCount,
      ),
    ),
  ];
}
// --- End Refactored Function ---
