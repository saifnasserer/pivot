import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/schadule_card.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/screens/section3/add_edit_schedule_dialog.dart';
import 'package:pivot/providers/schadule_provider.dart';

/// Enhanced schedule calendar builder with better UX and performance
class ScheduleCalendarBuilder {
  /// Builds a complete schedule calendar with enhanced features
  static List<Widget> buildCalendar({
    required int selectedDayIndex,
    required BuildContext context,
    required List<String> days,
    required List<ScheduleItem> dayScheduleItems,
    required Function(int) onDaySelected,
    required Function(String itemId) handleDelete,
    Function(String itemId)? onNotificationToggle,
    bool showEmptyState = true,
    bool enableAnimations = true,
    bool showFloatingActionButton = true,
    String? selectedDay,
  }) {
    if (days.isEmpty) {
      return [_buildEmptyState(context, 'لا توجد أيام في الجدول')];
    }

    final int validIndex = selectedDayIndex.clamp(0, days.length - 1);
    final currentDay = selectedDay ?? days[validIndex];

    return [
      _buildTopSpacing(context),
      _buildDaySelector(
        context,
        days,
        validIndex,
        onDaySelected,
        enableAnimations,
      ),
      _buildDivider(context),
      _buildScheduleItems(
        context,
        dayScheduleItems,
        handleDelete,
        onNotificationToggle,
        showEmptyState,
      ),
    ];
  }

  /// Builds a complete schedule widget with Scaffold and proper FAB
  static Widget buildScheduleWithScaffold({
    required int selectedDayIndex,
    required BuildContext context,
    required List<String> days,
    required List<ScheduleItem> dayScheduleItems,
    required Function(int) onDaySelected,
    required Function(String itemId) handleDelete,
    Function(String itemId)? onNotificationToggle,
    bool showEmptyState = true,
    bool enableAnimations = true,
    bool showFloatingActionButton = true,
    String? selectedDay,
  }) {
    final int validIndex = selectedDayIndex.clamp(0, days.length - 1);
    final currentDay = selectedDay ?? days[validIndex];

    return Scaffold(
      body: CustomScrollView(
        slivers: buildCalendar(
          selectedDayIndex: selectedDayIndex,
          context: context,
          days: days,
          dayScheduleItems: dayScheduleItems,
          onDaySelected: onDaySelected,
          handleDelete: handleDelete,
          onNotificationToggle: onNotificationToggle,
          showEmptyState: showEmptyState,
          enableAnimations: enableAnimations,
          showFloatingActionButton: false, // Don't show FAB in slivers
          selectedDay: selectedDay,
        ),
      ),
      floatingActionButton:
          showFloatingActionButton && currentDay.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: () => _showAddScheduleDialog(context, currentDay),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 6,
                label: Icon(
                  Icons.add,
                  size: Responsive.text(context, size: TextSize.medium),
                ),
              )
              : null,
    );
  }

  /// Builds the day selector with enhanced styling and today highlighting
  static Widget _buildDaySelector(
    BuildContext context,
    List<String> days,
    int selectedIndex,
    Function(int) onDaySelected,
    bool enableAnimations,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        height: Responsive.space(context, size: Space.xlarge) * 1.4,
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.small),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          reverse: true,
          itemCount: days.length,
          itemBuilder: (context, index) {
            final isSelected = selectedIndex == index;
            final isToday = _isToday(days[index]);

            return AnimatedContainer(
              duration:
                  enableAnimations
                      ? const Duration(milliseconds: 300)
                      : Duration.zero,
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                right: Responsive.space(context, size: Space.small),
              ),
              child: _buildEnhancedDayButton(
                context,
                days[index],
                isSelected,
                isToday,
                () => onDaySelected(index),
                enableAnimations,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds enhanced day button with today indicator
  static Widget _buildEnhancedDayButton(
    BuildContext context,
    String day,
    bool isSelected,
    bool isToday,
    VoidCallback onTap,
    bool enableAnimations,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            enableAnimations
                ? const Duration(milliseconds: 200)
                : Duration.zero,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
          vertical: Responsive.space(context, size: Space.small),
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          border: Border.all(
            color:
                isToday
                    ? Colors.orange.shade600
                    : isSelected
                    ? Colors.black
                    : Colors.grey.shade300,
            width: isToday ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isToday) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
            ],
            Text(
              day,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: Responsive.text(context, size: TextSize.medium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds schedule items with enhanced empty state
  static Widget _buildScheduleItems(
    BuildContext context,
    List<ScheduleItem> items,
    Function(String itemId) handleDelete,
    Function(String itemId)? onNotificationToggle,
    bool showEmptyState,
  ) {
    if (items.isEmpty) {
      return showEmptyState
          ? _buildEmptyState(context, 'لا توجد محاضرات أو سكاشن لهذا اليوم')
          : SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        return _buildScheduleCard(
          context,
          item,
          handleDelete,
          onNotificationToggle,
        );
      }, childCount: items.length),
    );
  }

  /// Builds individual schedule card with enhanced features
  static Widget _buildScheduleCard(
    BuildContext context,
    ScheduleItem item,
    Function(String itemId) handleDelete,
    Function(String itemId)? onNotificationToggle,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
        left: Responsive.space(context, size: Space.small),
        right: Responsive.space(context, size: Space.small),
      ),
      child: SchaduleCard(
        item: item,
        handleDelete: () => handleDelete(item.id),
        onNotificationToggle:
            onNotificationToggle != null
                ? () => onNotificationToggle(item.id)
                : null,
      ),
    );
  }

  /// Shows the add schedule dialog
  static void _showAddScheduleDialog(BuildContext context, String selectedDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddEditScheduleDialog(day: selectedDay);
      },
    ).then((_) {
      // Refresh schedule data after dialog is closed
      final scheduleProvider = Provider.of<ScheduleProvider>(
        context,
        listen: false,
      );
      scheduleProvider.fetchSchedule();
    });
  }

  /// Builds enhanced empty state with action button
  static Widget _buildEmptyState(BuildContext context, String message) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.large),
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_outlined,
                size: Responsive.text(context, size: TextSize.heading) * 1.5,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),
            Text(
              message,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds top spacing
  static Widget _buildTopSpacing(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(height: Responsive.space(context, size: Space.medium)),
    );
  }

  /// Builds divider with enhanced styling
  static Widget _buildDivider(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
          vertical: Responsive.space(context, size: Space.small),
        ),
        child: Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
      ),
    );
  }

  /// Checks if the given day is today
  static bool _isToday(String day) {
    final now = DateTime.now();
    final today = _getDayName(now.weekday);
    return day.toLowerCase() == today.toLowerCase();
  }

  /// Gets day name from weekday number
  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'الاثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      case 7:
        return 'الأحد';
      default:
        return '';
    }
  }
}

// Keep the original function for backward compatibility
List<Widget> buildCalendar({
  required int selectedDayIndex,
  required BuildContext context,
  required List<String> days,
  required List<ScheduleItem> dayScheduleItems,
  required Function(int) onDaySelected,
  required Function(String itemId) handleDelete,
  Function(String itemId)? onNotificationToggle,
}) {
  return ScheduleCalendarBuilder.buildCalendar(
    selectedDayIndex: selectedDayIndex,
    context: context,
    days: days,
    dayScheduleItems: dayScheduleItems,
    onDaySelected: onDaySelected,
    handleDelete: handleDelete,
    onNotificationToggle: onNotificationToggle,
  );
}
