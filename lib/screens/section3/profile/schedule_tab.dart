import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/screens/section3/profile_widgets/schadule.dart';
import 'profile_provider.dart';

class ScheduleTab extends StatelessWidget {
  final Function(int) onDaySelected;

  const ScheduleTab({super.key, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, child) {
        if (scheduleProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (scheduleProvider.error != null) {
          return Center(child: Text('Error: ${scheduleProvider.error}'));
        }

        final days = scheduleProvider.days;
        // Use context.read instead of Consumer for ProfileProvider to avoid unnecessary rebuilds
        final provider = context.read<ProfileProvider>();
        final validIndex = provider.selectedDayIndex.clamp(
          0,
          days.isEmpty ? 0 : days.length - 1,
        );
        final currentDay = days.isEmpty ? '' : days[validIndex];
        final itemsForSelectedDay = scheduleProvider.getScheduleForDay(
          currentDay,
        );

        return ScheduleCalendarBuilder.buildScheduleWithScaffold(
          selectedDayIndex: validIndex,
          context: context,
          days: days,
          dayScheduleItems: itemsForSelectedDay,
          onDaySelected: onDaySelected,
          handleDelete: (String itemId) {
            scheduleProvider.removeScheduleItem(currentDay, itemId);
          },
          onNotificationToggle: (String itemId) {
            scheduleProvider.toggleNotificationForItem(currentDay, itemId);
          },
          showFloatingActionButton: true,
          selectedDay: currentDay,
          enableAnimations: true,
        );
      },
    );
  }
}
