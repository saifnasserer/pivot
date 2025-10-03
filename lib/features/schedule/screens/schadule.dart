import 'package:flutter/material.dart';
import 'package:pivot/screens/models/schadule_card.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/features/schedule/screens/add_edit_schedule_dialog.dart';
import 'package:pivot/responsive.dart';

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
    Function(ScheduleItem item)? onEditItem,
    bool showEmptyState = true,
    bool enableAnimations = true,
    bool showFloatingActionButton = true,
    String? selectedDay,
    Function(int oldIndex, int newIndex)? onReorder,
  }) {
    if (days.isEmpty) {
      return [_buildEmptyState(context, 'لا توجد أيام في الجدول')];
    }

    final int validIndex = selectedDayIndex.clamp(0, days.length - 1);

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
        onEditItem,
        showEmptyState,
        onReorder: onReorder,
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
    Function(ScheduleItem item)? onEditItem,
    bool showEmptyState = true,
    bool enableAnimations = true,
    bool showFloatingActionButton = true,
    String? selectedDay,
    Function(int oldIndex, int newIndex)? onReorder,
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
          onEditItem: onEditItem,
          showEmptyState: showEmptyState,
          enableAnimations: enableAnimations,
          showFloatingActionButton: false, // Don't show FAB in slivers
          selectedDay: selectedDay,
          onReorder: onReorder,
        ),
      ),
      floatingActionButton:
          showFloatingActionButton && currentDay.isNotEmpty
              ? _buildEnhancedFloatingActionButton(context, currentDay)
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
        height: Responsive.space(context, size: Space.xlarge) * 1.8,
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: _buildEnhancedTabBar(
          context,
          days,
          selectedIndex,
          onDaySelected,
          enableAnimations,
        ),
      ),
    );
  }

  /// Builds enhanced tab bar with today detection and better integration
  static Widget _buildEnhancedTabBar(
    BuildContext context,
    List<String> days,
    int selectedIndex,
    Function(int) onDaySelected,
    bool enableAnimations,
  ) {
    // Ensure selectedIndex is within bounds
    final validSelectedIndex = selectedIndex.clamp(0, days.length - 1);

    // Try to find today's index, fallback to validSelectedIndex
    final todayIndex = getTodayIndex(days);
    final initialIndex = todayIndex != -1 ? todayIndex : validSelectedIndex;

    return DefaultTabController(
      length: days.length,
      initialIndex: initialIndex,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBar(
          isScrollable: true,
          physics: const BouncingScrollPhysics(),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.medium),
            ),
            color: Colors.black,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.small),
            vertical: Responsive.space(context, size: Space.small) * 0.5,
          ),
          labelPadding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.small),
          ),
          onTap: (index) {
            // Validate index before calling onDaySelected
            if (index >= 0 && index < days.length) {
              onDaySelected(index);
            }
          },
          tabs:
              days.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                final isToday = _isToday(day);
                final isSelected = validSelectedIndex == index;

                return Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.medium),
                      vertical: Responsive.space(context, size: Space.small),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isToday) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(
                            width:
                                Responsive.space(context, size: Space.small) *
                                0.5,
                          ),
                        ],
                        Text(
                          day,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.w600,
                            color:
                                isSelected
                                    ? Colors.white
                                    : isToday
                                    ? Colors.orange.shade700
                                    : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  /// Builds schedule items with enhanced empty state and reordering
  static Widget _buildScheduleItems(
    BuildContext context,
    List<ScheduleItem> items,
    Function(String itemId) handleDelete,
    Function(String itemId)? onNotificationToggle,
    Function(ScheduleItem item)? onEditItem,
    bool showEmptyState, {
    Function(int oldIndex, int newIndex)? onReorder,
  }) {
    if (items.isEmpty) {
      return showEmptyState
          ? _buildEmptyState(context, 'لا توجد محاضرات أو سكاشن لهذا اليوم')
          : SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // If reordering is enabled, use ReorderableListView
    if (onReorder != null) {
      return SliverToBoxAdapter(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            onReorder: onReorder,
            padding: EdgeInsets.zero,
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 2,
                color: Colors.transparent,
                shadowColor: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildReorderableScheduleCard(
                context,
                item,
                index,
                handleDelete,
                onNotificationToggle,
                onEditItem,
              );
            },
          ),
        ),
      );
    }

    // Default non-reorderable list
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        return _buildScheduleCard(
          context,
          item,
          handleDelete,
          onNotificationToggle,
          onEditItem,
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
    Function(ScheduleItem item)? onEditItem,
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
        onEditItem: onEditItem != null ? () => onEditItem(item) : null,
      ),
    );
  }

  /// Builds reorderable schedule card with drag handle
  static Widget _buildReorderableScheduleCard(
    BuildContext context,
    ScheduleItem item,
    int index,
    Function(String itemId) handleDelete,
    Function(String itemId)? onNotificationToggle,
    Function(ScheduleItem item)? onEditItem,
  ) {
    return Container(
      key: ValueKey(item.id),
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small) * 0.8,
        left: Responsive.space(context, size: Space.small) * 0.8,
        right: Responsive.space(context, size: Space.small) * 0.8,
      ),
      child: SchaduleCard(
        item: item,
        handleDelete: () => handleDelete(item.id),
        onNotificationToggle:
            onNotificationToggle != null
                ? () => onNotificationToggle(item.id)
                : null,
        onEditItem: onEditItem != null ? () => onEditItem(item) : null,
        // Pass the drag handle as a trailing widget
        trailingWidget: ReorderableDragStartListener(
          index: index,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.small) * 0.8,
              vertical: Responsive.space(context, size: Space.small) * 0.6,
            ),
            margin: EdgeInsets.only(
              left: Responsive.space(context, size: Space.small) * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.small) * 0.8,
              ),
              border: Border.all(color: Colors.grey.shade300, width: 0.8),
            ),
            child: Icon(
              Icons.drag_handle,
              color: Colors.grey.shade600,
              size: Responsive.text(context, size: TextSize.small) * 1.2,
            ),
          ),
        ),
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
    );
  }

  /// Builds enhanced floating action button with better styling
  static Widget _buildEnhancedFloatingActionButton(
    BuildContext context,
    String selectedDay,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'schedule_fab',
        onPressed: () => _showAddScheduleDialog(context, selectedDay),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: Responsive.text(context, size: TextSize.medium),
            ),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Text(
              'إضافة',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds enhanced empty state with action button
  static Widget _buildEmptyState(BuildContext context, String message) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.xlarge),
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_outlined,
                size: Responsive.text(context, size: TextSize.heading) * 1.5,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.xlarge)),
            Text(
              message,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              'اضغط على الزر أدناه لإضافة جدول جديد',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
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

    // Normalize both strings for comparison
    final normalizedDay = day.trim().toLowerCase();
    final normalizedToday = today.trim().toLowerCase();

    return normalizedDay == normalizedToday;
  }

  /// Gets the index of today in the days list, returns -1 if not found
  static int getTodayIndex(List<String> days) {
    for (int i = 0; i < days.length; i++) {
      if (_isToday(days[i])) {
        return i;
      }
    }

    // Fallback: try to find today using alternative day names
    final alternativeToday = _getAlternativeDayName();
    if (alternativeToday.isNotEmpty) {
      for (int i = 0; i < days.length; i++) {
        if (days[i].trim().toLowerCase() == alternativeToday.toLowerCase()) {
          return i;
        }
      }
    }

    return -1;
  }

  /// Gets today's day name in Arabic
  static String getTodayName() {
    final now = DateTime.now();
    return _getDayName(now.weekday);
  }

  /// Gets alternative day name formats for better matching
  static String _getAlternativeDayName() {
    final now = DateTime.now();
    final weekday = now.weekday;

    // Return alternative formats that might be used in the app
    switch (weekday) {
      case 1: // Monday
        return 'الاثنين';
      case 2: // Tuesday
        return 'الثلاثاء';
      case 3: // Wednesday
        return 'الاربعاء';
      case 4: // Thursday
        return 'الخميس';
      case 5: // Friday
        return 'الجمعة';
      case 6: // Saturday
        return 'السبت';
      case 7: // Sunday
        return 'الاحد';
      default:
        return '';
    }
  }

  /// Gets day name from weekday number
  /// DateTime.weekday: 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday, 7=Sunday
  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1: // Monday
        return 'الاثنين';
      case 2: // Tuesday
        return 'الثلاثاء';
      case 3: // Wednesday
        return 'الاربعاء';
      case 4: // Thursday
        return 'الخميس';
      case 5: // Friday
        return 'الجمعة';
      case 6: // Saturday
        return 'السبت';
      case 7: // Sunday
        return 'الاحد';
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
  Function(ScheduleItem item)? onEditItem,
  Function(int oldIndex, int newIndex)? onReorder,
}) {
  return ScheduleCalendarBuilder.buildCalendar(
    selectedDayIndex: selectedDayIndex,
    context: context,
    days: days,
    dayScheduleItems: dayScheduleItems,
    onDaySelected: onDaySelected,
    handleDelete: handleDelete,
    onNotificationToggle: onNotificationToggle,
    onEditItem: onEditItem,
    onReorder: onReorder,
  );
}
