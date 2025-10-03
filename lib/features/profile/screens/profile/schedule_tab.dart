import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/schedule/screens/add_edit_schedule_dialog.dart';
import 'package:pivot/features/schedule/screens/schadule.dart';
import 'package:pivot/features/schedule/providers/schedule_provider.dart';
import 'package:pivot/features/schedule/widgets/share_schedule_dialog.dart';
import 'package:pivot/screens/models/schedule_item.dart';

class ScheduleTab extends ConsumerStatefulWidget {
  final Function(int) onDaySelected;

  const ScheduleTab({super.key, required this.onDaySelected});

  @override
  ConsumerState<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends ConsumerState<ScheduleTab>
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
    // Local-first: Only refresh if no data exists
    // This prevents unnecessary fetches when switching tabs
    _refreshScheduleData();
  }

  void _refreshScheduleData() {
    final scheduleState = ref.read(scheduleProvider);

    // Local-first strategy: Only fetch if no data exists (first time load)
    if (scheduleState.schedule.isEmpty && !scheduleState.isLoading) {
      print('🔄 ScheduleTab: Fetching schedule (first load)...');
      try {
        ref.read(scheduleProvider.notifier).fetchSchedule();
      } catch (e) {
        print('❌ ScheduleTab: Fetch error - $e');
      }
    } else if (scheduleState.schedule.isNotEmpty) {
      print(
        '✅ ScheduleTab: Using local schedule (${scheduleState.schedule.length} days) - Zero reads',
      );
      // Auto-select today if available
      _autoSelectTodayIfAvailable();
    }
  }

  void _autoSelectTodayIfAvailable() {
    final scheduleState = ref.read(scheduleProvider);
    final days = scheduleState.days;

    if (days.isNotEmpty) {
      final todayIndex = ScheduleCalendarBuilder.getTodayIndex(days);

      // For now, just call onDaySelected with today's index or 0
      final targetIndex = todayIndex != -1 ? todayIndex : 0;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onDaySelected(targetIndex);
        }
      });
    }
  }

  Future<void> _refreshSchedule() async {
    print('🔄 ScheduleTab: Manual refresh...');
    try {
      // Manual refresh: Force fetch from remote
      await ref.read(scheduleProvider.notifier).fetchSchedule();

      // Auto-select today after refreshing schedule data
      final scheduleState = ref.read(scheduleProvider);
      if (scheduleState.days.isNotEmpty) {
        _autoSelectTodayIfAvailable();
        print('✅ ScheduleTab: Refreshed ${scheduleState.days.length} days');
      }
    } catch (e) {
      print('❌ ScheduleTab: Refresh error - $e');
    }
  }

  void _handleDaySelected(int index) {
    // Validate index before proceeding
    final scheduleState = ref.read(scheduleProvider);
    if (index < 0 || index >= scheduleState.days.length) {
      return;
    }

    widget.onDaySelected(index);
  }

  void _handleDelete(String itemId) {
    ref.read(scheduleProvider.notifier).deleteScheduleItem(itemId);
  }

  void _handleNotificationToggle(String itemId) {
    // Toggle notification logic would go here
    // For now, this is a placeholder
  }

  void _handleReorder(int oldIndex, int newIndex) {
    try {
      final scheduleState = ref.read(scheduleProvider);
      final currentDay =
          scheduleState.days.isNotEmpty ? scheduleState.days[0] : '';

      if (currentDay.isNotEmpty &&
          oldIndex != newIndex &&
          oldIndex >= 0 &&
          newIndex >= 0) {
        final items = scheduleState.schedule[currentDay] ?? [];
        ref
            .read(scheduleProvider.notifier)
            .reorderScheduleItems(currentDay, items);
      }
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

  void _handleShareSchedule() {
    final scheduleState = ref.read(scheduleProvider);
    if (scheduleState.schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن مشاركة جدول فارغ'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShareScheduleDialog(schedule: scheduleState.schedule);
      },
    );
  }

  void _showAddScheduleDialog(BuildContext context, String selectedDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddEditScheduleDialog(day: selectedDay);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final scheduleState = ref.watch(scheduleProvider);
    final days = scheduleState.days;
    final selectedDayIndex = 0; // Default to first day
    if (scheduleState.isLoading) {
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

    if (scheduleState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Error: ${scheduleState.error}',
                style: TextStyle(color: Colors.red.shade600),
                textAlign: TextAlign.center,
              ),
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

    final validIndex = selectedDayIndex.clamp(0, days.length - 1);
    final currentDay = days[validIndex];
    final itemsForSelectedDay = ref
        .read(scheduleProvider.notifier)
        .getScheduleForDay(currentDay);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refreshSchedule,
          child: CustomScrollView(
            slivers: ScheduleCalendarBuilder.buildCalendar(
              selectedDayIndex: validIndex,
              context: context,
              days: days,
              dayScheduleItems: itemsForSelectedDay,
              onDaySelected: _handleDaySelected,
              handleDelete: _handleDelete,
              onNotificationToggle: _handleNotificationToggle,
              onEditItem: _handleEditItem,
              showEmptyState: true,
              enableAnimations: true,
              onReorder: _handleReorder,
            ),
          ),
        ),
        // Share button positioned at top right
        Positioned(
          top: 8,
          left: 8,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 2,
            child: InkWell(
              onTap: _handleShareSchedule,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.share_outlined,
                  color: Colors.black87,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        // Add button positioned at bottom right
        Positioned(
          bottom: 16,
          left: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddScheduleDialog(context, currentDay),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            icon: Icon(Icons.add),
            label: Text('إضافة حصة'),
            elevation: 4,
          ),
        ),
      ],
    );
  }
}
