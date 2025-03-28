import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/category_model.dart';
import 'package:pivot/screens/models/lecture_card_model.dart';

class Schadule extends StatefulWidget {
  const Schadule({super.key});
  static const String id = 'schadule';

  @override
  State<Schadule> createState() => _SchaduleState();
}

class _SchaduleState extends State<Schadule> {
  // Map to store lectures for each day
  final Map<String, List<LectureCardModel>> dayLectures = {
    'السبت': [
      LectureCardModel(
        section: false,
        title: 'الحوسبة عالية الاداء',
        description: 'مدرج 2 الساعه 1ونص',
      ),
      LectureCardModel(
        section: true,
        title: 'سكشن الحوسبة',
        description: 'معمل 3 الساعه 3',
      ),
    ],
    'الاحد': [
      LectureCardModel(
        section: false,
        title: 'هندسة البرمجيات',
        description: 'مدرج 1 الساعه 9 صباحا',
      ),
    ],
    'الاثنين': [
      LectureCardModel(
        section: true,
        title: 'سكشن هندسة البرمجيات',
        description: 'معمل 2 الساعه 11 صباحا',
      ),
    ],
    'الثلاثاء': [],
    'الاربعاء': [
      LectureCardModel(
        section: false,
        title: 'نظم التشغيل',
        description: 'مدرج 3 الساعه 2 ظهرا',
      ),
    ],
    'الخميس': [
      LectureCardModel(
        section: false,
        title: 'نظم التشغيل',
        description: 'مدرج 3 الساعه 2 ظهرا',
      ),
    ],
  };

  // List of days in order (right to left for Arabic)
  final List<String> days = [
    'السبت',
    'الاحد',
    'الاثنين',
    'الثلاثاء',
    'الاربعاء',
    'الخميس',
  ];

  // Currently selected day
  int selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedDay = days[selectedDayIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Days selector
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            SizedBox(
              height: Responsive.space(context, size: Space.xlarge) * 1.4,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                reverse: true, // Right to left for Arabic
                itemCount: days.length,
                itemBuilder: (context, index) {
                  return CategoryButton(
                    selected: selectedDayIndex == index,
                    title: days[index],
                    onSelected: () {
                      setState(() {
                        selectedDayIndex = index;
                      });
                    },
                  );
                },
              ),
            ),

            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Divider(indent: 4, endIndent: 1),

            // Lectures for the selected day
            Expanded(
              child:
                  dayLectures[selectedDay]!.isEmpty
                      ? Center(
                        child: Text(
                          'مفيش محاضرات النهارده',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            color: Colors.grey,
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: dayLectures[selectedDay]!.length,
                        itemBuilder: (context, index) {
                          return dayLectures[selectedDay]![index];
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
