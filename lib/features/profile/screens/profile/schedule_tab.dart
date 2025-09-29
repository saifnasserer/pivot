import 'package:flutter/material.dart';
import 'package:pivot/features/schedule/screens/add_edit_schedule_dialog.dart';
import 'package:pivot/features/schedule/screens/schadule.dart';
import 'package:provider/provider.dart';

import 'package:pivot/providers/schadule_provider.dart';

import 'package:pivot/screens/models/schedule_item.dart';
import 'profile_provider.dart';

class ScheduleTab extends StatefulWidget {
  final Function(int) onDaySelected;

  const ScheduleTab({super.key, required this.onDaySelected});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep the tab alive when switching

  @override
  void initState() {
    super.initState();
    // Ensure schedule data is loaded when tab is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduleData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when dependencies change (e.g., when returning to this tab)
    _refreshScheduleData();
  }

  void _refreshScheduleData() {
    final scheduleProvider = context.read<ScheduleProvider>();

    if (scheduleProvider.days.isEmpty && !scheduleProvider.isLoading) {
      scheduleProvider.fetchSchedule();
    } else if (scheduleProvider.days.isNotEmpty) {
      // Auto-select today if available
      _autoSelectTodayIfAvailable();
    }
  }

  void _autoSelectTodayIfAvailable() {
    final scheduleProvider = context.read<ScheduleProvider>();
    final profileProvider = context.read<ProfileProvider>();

    if (scheduleProvider.days.isNotEmpty) {
      final todayIndex = ScheduleCalendarBuilder.getTodayIndex(
        scheduleProvider.days,
      );

      // Validate current selected index
      final currentIndex = profileProvider.selectedDayIndex;
      final validCurrentIndex = currentIndex.clamp(
        0,
        scheduleProvider.days.length - 1,
      );

      // If current index is invalid or today is available and different
      if (currentIndex != validCurrentIndex ||
          (todayIndex != -1 && validCurrentIndex != todayIndex)) {
        final targetIndex = todayIndex != -1 ? todayIndex : validCurrentIndex;

        // Auto-select today if it exists, otherwise use valid current index
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            profileProvider.updateSelectedDayIndex(targetIndex);
            widget.onDaySelected(targetIndex);
          }
        });
      }
    }
  }

  Future<void> _refreshSchedule() async {
    final scheduleProvider = context.read<ScheduleProvider>();
    await scheduleProvider.fetchSchedule();

    // Auto-select today after refreshing schedule data
    if (scheduleProvider.days.isNotEmpty) {
      _autoSelectTodayIfAvailable();
    }
  }

  void _handleDaySelected(int index) {
    // Validate index before proceeding
    final scheduleProvider = context.read<ScheduleProvider>();
    if (index < 0 || index >= scheduleProvider.days.length) {
      return;
    }

    widget.onDaySelected(index);
    // Also update the provider directly for immediate UI update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profileProvider = context.read<ProfileProvider>();
        profileProvider.updateSelectedDayIndex(index);
      }
    });
  }

  void _handleDelete(String itemId) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final currentDay =
        scheduleProvider.days.isNotEmpty
            ? scheduleProvider.days[profileProvider.selectedDayIndex.clamp(
              0,
              scheduleProvider.days.length - 1,
            )]
            : '';

    scheduleProvider.removeScheduleItem(currentDay, itemId);
  }

  void _handleNotificationToggle(String itemId) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final currentDay =
        scheduleProvider.days.isNotEmpty
            ? scheduleProvider.days[profileProvider.selectedDayIndex.clamp(
              0,
              scheduleProvider.days.length - 1,
            )]
            : '';

    scheduleProvider.toggleNotificationForItem(currentDay, itemId);
  }

  void _handleReorder(int oldIndex, int newIndex) {
    try {
      final scheduleProvider = context.read<ScheduleProvider>();
      final profileProvider = context.read<ProfileProvider>();
      final currentDay =
          scheduleProvider.days.isNotEmpty
              ? scheduleProvider.days[profileProvider.selectedDayIndex.clamp(
                0,
                scheduleProvider.days.length - 1,
              )]
              : '';

      if (currentDay.isNotEmpty &&
          oldIndex != newIndex &&
          oldIndex >= 0 &&
          newIndex >= 0) {
        scheduleProvider.reorderScheduleItems(currentDay, oldIndex, newIndex);
      } else {}
    } catch (e) {}
  }

  void _handleEditItem(ScheduleItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddEditScheduleDialog(day: item.day, itemToEdit: item);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Consumer2<ScheduleProvider, ProfileProvider>(
      builder: (context, scheduleProvider, profileProvider, child) {
        if (scheduleProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري تحميل الجدول...'),
              ],
            ),
          );
        }

        if (scheduleProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                SizedBox(height: 16),
                Text(
                  'Error: ${scheduleProvider.error}',
                  style: TextStyle(color: Colors.red.shade600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshSchedule,
                  child: Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final days = scheduleProvider.days;
        if (days.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'لا توجد أيام في الجدول',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshSchedule,
                  child: Text('تحديث الجدول'),
                ),
              ],
            ),
          );
        }

        final validIndex = profileProvider.selectedDayIndex.clamp(
          0,
          days.length - 1,
        );
        final currentDay = days[validIndex];
        final itemsForSelectedDay = scheduleProvider.getScheduleForDay(
          currentDay,
        );

        return RefreshIndicator(
          onRefresh: _refreshSchedule,
          child: ScheduleCalendarBuilder.buildScheduleWithScaffold(
            selectedDayIndex: validIndex,
            context: context,
            days: days,
            dayScheduleItems: itemsForSelectedDay,
            onDaySelected: _handleDaySelected,
            handleDelete: _handleDelete,
            onNotificationToggle: _handleNotificationToggle,
            onEditItem: _handleEditItem,
            showFloatingActionButton: true,
            selectedDay: currentDay,
            enableAnimations: true,
            onReorder: _handleReorder,
          ),
        );
      },
    );
  }
}
