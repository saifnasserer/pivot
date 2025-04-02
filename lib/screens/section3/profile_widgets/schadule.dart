import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/category_model.dart';
// import 'package:pivot/screens/models/lecture_card_model.dart'; // Unused import
import 'package:pivot/screens/models/schadule_card.dart';
import 'package:pivot/screens/models/schedule_item.dart'; // Import model

// --- Update buildCalendar signature ---
List<Widget> buildCalendar({
  required int selectedDayIndex,
  required BuildContext context,
  required List<String> days,
  required List<ScheduleItem> dayScheduleItems,
  required Function(int) onDaySelected,
  required Function(String itemId) handleDelete,
}) {
  if (days.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No schedule days found.')),
      ),
    ];
  }

  final int validIndex = selectedDayIndex.clamp(0, days.length - 1);
  // final selectedDay = days[validIndex]; // No longer needed here

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

    // --- Update SliverList/SliverFillRemaining part ---
    (dayScheduleItems.isEmpty) // Check the passed item list
        ? SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'مفيش محاضرات او سكاشن النهارده', // Updated empty message
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
              final item = dayScheduleItems[index]; // Get the current item
              // Build SchaduleCard using the ScheduleItem
              return SchaduleCard(
                item: item,
                handleDelete: () => handleDelete(item.id), // Pass the item's ID
              );
            },
            childCount: dayScheduleItems.length, // Use item list length
          ),
        ),
    // --- End Update ---
  ];
}
