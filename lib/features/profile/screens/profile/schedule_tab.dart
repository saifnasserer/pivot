import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:pivot/features/schedule/screens/add_edit_schedule_dialog.dart';
import 'package:pivot/features/schedule/screens/schadule.dart';
import 'package:pivot/features/schedule/providers/schedule_provider.dart';
import 'package:pivot/features/schedule/widgets/import_schedule_dialog.dart';
import 'package:pivot/services/schedule_sharing_service.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/widgets/offline_banner.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/screens/models/schadule_card.dart';

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

  // Track selected day index
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    // Provider loads from cache automatically on startup (zero server reads)
    // Initialize day selection when data is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final scheduleState = ref.read(scheduleProvider);
        if (scheduleState.schedule.isNotEmpty &&
            scheduleState.days.isNotEmpty) {
          // Select today's day or first day
          final todayIndex = ScheduleCalendarBuilder.getTodayIndex(
            scheduleState.days,
          );
          final targetIndex = todayIndex != -1 ? todayIndex : 0;

          setState(() {
            _selectedDayIndex = targetIndex;
          });
          widget.onDaySelected(targetIndex);

          print(
            '📅 ScheduleTab initialized: Selected day $_selectedDayIndex (${scheduleState.days[targetIndex]})',
          );
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we need to fetch data (only if cache is empty)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final scheduleState = ref.read(scheduleProvider);
        if (scheduleState.schedule.isEmpty && !scheduleState.isLoading) {
          // Only fetch from server if no cached data exists (first time only)
          print(
            '📦 didChangeDependencies: No cached data, fetching from server...',
          );
          ref.read(scheduleProvider.notifier).fetchSchedule();
        }
      }
    });
  }

  void _autoSelectTodayIfAvailable() {
    final scheduleState = ref.read(scheduleProvider);
    final days = scheduleState.days;

    if (days.isNotEmpty) {
      final todayIndex = ScheduleCalendarBuilder.getTodayIndex(days);

      // Set the selected day index to today or first day
      final targetIndex = todayIndex != -1 ? todayIndex : 0;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedDayIndex = targetIndex;
          });
          widget.onDaySelected(targetIndex);
        }
      });
    }
  }

  Future<void> _refreshSchedule() async {
    print('🔄 ScheduleTab: Manual refresh...');
    try {
      // Manual refresh: Force fetch from remote (bypasses cache)
      await ref.read(scheduleProvider.notifier).forceRefresh();

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

    setState(() {
      _selectedDayIndex = index;
    });

    widget.onDaySelected(index);
  }

  void _handleDelete(String itemId) async {
    try {
      await ref.read(scheduleProvider.notifier).deleteScheduleItem(itemId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف العنصر بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Handle errors gracefully
      if (mounted) {
        final errorMessage = e.toString();
        final isNetworkError =
            errorMessage.contains('firebase') ||
            errorMessage.contains('network') ||
            errorMessage.contains('connection') ||
            errorMessage.contains('offline');

        if (isNetworkError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لا يوجد اتصال بالإنترنت. سيتم حذف العنصر عند الاتصال.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'حسناً',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء الحذف: $errorMessage'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _handleNotificationToggle(String itemId) async {
    // Toggle notification for the schedule item
    try {
      await ref.read(scheduleProvider.notifier).toggleNotification(itemId);
      print('📱 ScheduleTab: Toggled notification for item $itemId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث حالة التنبيه'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ ScheduleTab: Failed to toggle notification - $e');

      if (mounted) {
        final errorMessage = e.toString();
        final isNetworkError =
            errorMessage.contains('firebase') ||
            errorMessage.contains('network') ||
            errorMessage.contains('connection') ||
            errorMessage.contains('offline');

        if (isNetworkError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لا يوجد اتصال بالإنترنت. سيتم تحديث التنبيه عند الاتصال.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $errorMessage'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _handleEditItem(ScheduleItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddEditScheduleDialog(day: item.day, itemToEdit: item);
      },
    );
  }

  Future<void> _handleShareSchedule() async {
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

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('جاري إنشاء المفتاح...'),
          ],
        ),
        backgroundColor: Colors.black,
        duration: Duration(seconds: 3),
      ),
    );

    try {
      // Auto-create shareable link with 7-day expiration
      final sharingService = ScheduleSharingService();
      final shareId = await sharingService.createShareableLink(
        title: 'جدولي الدراسي',
        description: 'جدول دراسي مشترك',
        schedule: scheduleState.schedule,
        expiresAt: DateTime.now().add(
          Duration(days: 7),
        ), // Always expires in 7 days
      );

      if (shareId != null) {
        // Close loading snackbar
        ScaffoldMessenger.of(context).clearSnackBars();

        // Share the link directly
        await sharingService.shareScheduleLink(shareId);
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إنشاء مفتاح المشاركة'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _showAddScheduleDialog(BuildContext context, String selectedDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddEditScheduleDialog(day: selectedDay);
      },
    );
  }

  void _showImportScheduleDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const ImportScheduleDialog();
      },
    );

    // Force refresh after dialog closes
    if (mounted) {
      print('🔄 ScheduleTab: Refreshing after import dialog closed');
      await _refreshSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final scheduleState = ref.watch(scheduleProvider);
    final days = scheduleState.days;
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
          ],
        ),
      );
    }

    final validIndex = _selectedDayIndex.clamp(0, days.length - 1);
    final currentDay = days[validIndex];

    // Get items for the selected day from the schedule state
    final itemsForSelectedDay = scheduleState.schedule[currentDay] ?? [];

    return Stack(
      children: [
        Column(
          children: [
            // Offline banner
            Consumer(
              builder: (context, ref, _) {
                final connectivityStatus = ref.watch(
                  connectivityStatusProvider,
                );
                return connectivityStatus.when(
                  data:
                      (isOnline) =>
                          isOnline
                              ? const SizedBox.shrink()
                              : const OfflineBanner(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
            // Fixed header with day tabs
            _buildDayTabs(context, days, validIndex),

            // Scrollable schedule items
            Expanded(
              child: _buildScrollableScheduleItems(
                context,
                itemsForSelectedDay,
                currentDay,
              ),
            ),
          ],
        ),
        // Speed dial with add and share actions positioned at bottom right
        Positioned(
          bottom: Responsive.space(context, size: Space.medium),
          right: Responsive.space(context, size: Space.medium),
          child: SpeedDial(
            icon: Icons.add,
            activeIcon: Icons.close,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            activeBackgroundColor: Colors.black,
            activeForegroundColor: Colors.white,
            visible: true,
            closeManually: false,
            elevation: 4,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            direction: SpeedDialDirection.up,
            children: [
              SpeedDialChild(
                child: Icon(Icons.download_outlined),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                onTap: _showImportScheduleDialog,
                elevation: 4,
                shape: CircleBorder(),
              ),
              SpeedDialChild(
                child: Icon(Icons.share_outlined),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                onTap: _handleShareSchedule,
                elevation: 4,
                shape: CircleBorder(),
              ),
              SpeedDialChild(
                child: Icon(Icons.add),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                onTap: () => _showAddScheduleDialog(context, currentDay),
                elevation: 4,
                shape: CircleBorder(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the fixed day tabs header
  Widget _buildDayTabs(
    BuildContext context,
    List<String> days,
    int selectedIndex,
  ) {
    return Container(
      height: Responsive.space(context, size: Space.xlarge) * 1.8,
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
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
        _handleDaySelected,
        true, // enableAnimations
      ),
    );
  }

  /// Builds scrollable schedule items
  Widget _buildScrollableScheduleItems(
    BuildContext context,
    List<ScheduleItem> items,
    String currentDay,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(context, 'لا توجد محاضرات أو سكاشن لهذا اليوم');
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
        vertical: Responsive.space(context, size: Space.small),
      ),
      child: Column(
        children:
            items
                .map(
                  (item) => _buildScheduleCard(
                    context,
                    item,
                    _handleDelete,
                    _handleNotificationToggle,
                    _handleEditItem,
                  ),
                )
                .toList(),
      ),
    );
  }

  /// Builds individual schedule card
  Widget _buildScheduleCard(
    BuildContext context,
    ScheduleItem item,
    Function(String itemId) handleDelete,
    Function(String itemId)? onNotificationToggle,
    Function(ScheduleItem item)? onEditItem,
  ) {
    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
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

  /// Builds enhanced tab bar with today detection
  Widget _buildEnhancedTabBar(
    BuildContext context,
    List<String> days,
    int selectedIndex,
    Function(int) onDaySelected,
    bool enableAnimations,
  ) {
    final validSelectedIndex = selectedIndex.clamp(0, days.length - 1);
    final todayIndex = _getTodayIndex(days);
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
            if (index >= 0 && index < days.length) {
              _handleDaySelected(index);
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

  /// Builds empty state for schedule items
  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
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
        ],
      ),
    );
  }

  /// Checks if the given day is today
  bool _isToday(String day) {
    final now = DateTime.now();
    final today = _getDayName(now.weekday);

    final normalizedDay = day.trim().toLowerCase();
    final normalizedToday = today.trim().toLowerCase();

    return normalizedDay == normalizedToday;
  }

  /// Gets today's index in the days list
  int _getTodayIndex(List<String> days) {
    for (int i = 0; i < days.length; i++) {
      if (_isToday(days[i])) {
        return i;
      }
    }
    return -1;
  }

  /// Gets day name from weekday number
  String _getDayName(int weekday) {
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
