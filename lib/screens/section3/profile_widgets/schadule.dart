import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/category_model.dart';
import 'package:pivot/screens/models/lecture_card_model.dart';

List<Widget> buildCalendar({
  required int selectedDayIndex,
  required BuildContext context,
  required List<String> days, 
  required Map<String, List<LectureCardModel>> dayLectures, 
  required Function(int) onDaySelected, 
}) {
  if (days.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No schedule days found.')),
      )
    ];
  }
  
  final int validIndex = selectedDayIndex.clamp(0, days.length - 1);
  final selectedDay = days[validIndex];

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
          itemCount: days.length,
          itemBuilder: (context, index) {
            return CategoryButton(
              selected: validIndex == index, 
              title: days[index],
              onSelected: () {
                onDaySelected(index);     
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
    
    (dayLectures[selectedDay] == null || dayLectures[selectedDay]!.isEmpty)
        ? SliverFillRemaining( 
            hasScrollBody: false,
            child: Center(
              child: Text(
                'مفيش محاضرات النهارده',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return dayLectures[selectedDay]![index]; 
              }, 
              childCount: dayLectures[selectedDay]!.length
            ),
          ),
  ];
}
