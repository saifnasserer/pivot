import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/models/schedule_item.dart';
import '../services/schedule_service.dart';
import '../services/notification_trigger_service.dart';
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/services/local_notification_service.dart';

class ScheduleProvider with ChangeNotifier {
  ScheduleProvider() {
    // Automatically load schedule on startup to ensure reminders are scheduled
    fetchSchedule();
  }
  final ScheduleService _scheduleService = ScheduleService();
  final NotificationTriggerService _notificationService =
      NotificationTriggerService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, List<ScheduleItem>> _schedule = {};
  bool _isLoading = false;
  String? _error;

  final Uuid _uuid = Uuid();

  final List<String> _days = [
    'السبت',
    'الاحد',
    'الاثنين',
    'الثلاثاء',
    'الاربعاء',
    'الخميس',
  ];

  List<String> get days => _days;
  Map<String, List<ScheduleItem>> get schedule => _schedule;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ScheduleItem> getScheduleForDay(String day) {
    return _schedule[day] ?? [];
  }

  /// Helper method to get order value safely, defaulting to index if null
  int _getItemOrder(ScheduleItem item, int fallbackIndex) {
    return item.order ?? fallbackIndex;
  }

  /// Migrates legacy schedule items that don't have order values
  Future<void> _migrateLegacyOrders() async {
    bool needsMigration = false;

    // Check if any items need order migration
    for (var entry in _schedule.entries) {
      final day = entry.key;
      final dayItems = entry.value;

      for (int i = 0; i < dayItems.length; i++) {
        if (dayItems[i].order == null) {
          print('🔄 Migrating legacy item: ${dayItems[i].title} on $day');
          dayItems[i] = dayItems[i].copyWith(order: i);
          needsMigration = true;
        }
      }

      // Sort items by order after migration
      dayItems.sort((a, b) {
        final aOrder = _getItemOrder(a, 0);
        final bOrder = _getItemOrder(b, 0);
        return aOrder.compareTo(bOrder);
      });
    }

    // If we migrated any items, save them to the backend
    if (needsMigration) {
      print('📝 Saving migrated orders to backend...');
      try {
        for (var entry in _schedule.entries) {
          final day = entry.key;
          final dayItems = entry.value;
          await _scheduleService.reorderScheduleItems(day, dayItems);
        }
        print('✅ Migration completed successfully');
      } catch (e) {
        print('❌ Migration failed: $e');
      }
    }
  }

  Future<void> reorderScheduleItems(
    String day,
    int oldIndex,
    int newIndex,
  ) async {
    print('=== REORDER DEBUG ===');
    print('Day: $day');
    print('Old Index: $oldIndex');
    print('New Index: $newIndex');

    final items = _schedule[day];
    print('Items for day: ${items?.length ?? 0}');

    if (items == null ||
        oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= items.length ||
        newIndex > items.length) {
      // Changed >= to > for newIndex
      print('❌ Invalid reorder parameters - aborting');
      print('  - items.length: ${items?.length}');
      print(
        '  - oldIndex: $oldIndex (valid: 0 to ${(items?.length ?? 0) - 1})',
      );
      print('  - newIndex: $newIndex (valid: 0 to ${items?.length ?? 0})');
      return;
    }

    print('Items before reorder:');
    for (int i = 0; i < items.length; i++) {
      print('  [$i] ${items[i].title} (order: ${_getItemOrder(items[i], i)})');
    }

    // Adjust newIndex for items moving down
    if (oldIndex < newIndex) {
      newIndex -= 1;
      print('Adjusted newIndex to: $newIndex');
    }

    try {
      // Reorder locally first for immediate UI feedback
      final item = items.removeAt(oldIndex);
      print('Removed item: ${item.title}');

      items.insert(newIndex, item);
      print('Inserted item at index: $newIndex');

      // Update the order values for all items in this day
      for (int i = 0; i < items.length; i++) {
        final oldOrder = _getItemOrder(items[i], i);
        items[i] = items[i].copyWith(order: i);
        print('Updated ${items[i].title}: order $oldOrder -> $i');
      }

      print('Items after reorder:');
      for (int i = 0; i < items.length; i++) {
        print(
          '  [$i] ${items[i].title} (order: ${_getItemOrder(items[i], i)})',
        );
      }

      notifyListeners();
      print('✅ Local reorder complete - notified listeners');

      // Update in the backend
      print('🔄 Updating backend...');
      await _scheduleService.reorderScheduleItems(day, items);
      print('✅ Backend update complete');

      // Update cache
      final allItems = _schedule.values.expand((list) => list).toList();
      await CacheService.instance.cacheSchedule(allItems);
      print('✅ Cache update complete');
    } catch (e) {
      print('❌ Reorder failed: $e');
      // Revert on error
      await fetchSchedule();
      _error = 'Failed to reorder items: ${e.toString()}';
      notifyListeners();
    }
    print('=== REORDER DEBUG END ===');
  }

  Future<void> fetchSchedule() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Load from cache first
      final cachedSchedule = CacheService.instance.getCachedSchedule();
      if (cachedSchedule.isNotEmpty) {
        _schedule = {};
        for (var item in cachedSchedule) {
          _schedule.putIfAbsent(item.day, () => []).add(item);
        }
        // Sort cached items by order and migrate any null orders
        await _migrateLegacyOrders();
        notifyListeners();
      }

      // Step 2: Fetch from server in the background
      print('📥 Fetching schedule from server...');
      _schedule = await _scheduleService.getSchedule();
      print('📥 Received schedule from server');

      // Migrate legacy items and ensure proper sorting
      await _migrateLegacyOrders();

      // Flatten schedule to a list for caching
      final allItems = _schedule.values.expand((list) => list).toList();
      await CacheService.instance.cacheSchedule(allItems);
      print('✅ Schedule cached');

      // After fetch, (re)schedule weekly class reminders locally on mobile
      if (!kIsWeb) {
        for (final dayItems in _schedule.values) {
          for (final item in dayItems) {
            if (item.notificationEnabled) {
              await _scheduleClassNotification(item);
            } else {
              await _removeClassNotifications(item.id);
            }
          }
        }
      }
    } catch (e) {
      _error = 'Failed to fetch schedule: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addScheduleItem({
    required String title,
    required String time,
    required String location,
    required String day,
    required ScheduleItemType type,
    bool notificationEnabled = true,
  }) async {
    print('🗓️ === ADD SCHEDULE ITEM DEBUG ===');
    print('  - Title: $title');
    print('  - Time: $time');
    print('  - Location: $location');
    print('  - Day: $day');
    print('  - Type: $type');
    print('  - Notification Enabled: $notificationEnabled');
    // Calculate the next order index for this day
    final existingItems = _schedule[day] ?? [];
    final nextOrder =
        existingItems.isNotEmpty
            ? existingItems
                    .map((item) => _getItemOrder(item, 0))
                    .reduce((a, b) => a > b ? a : b) +
                1
            : 0;

    final newItem = ScheduleItem(
      id: _uuid.v4(),
      title: title,
      time: time,
      location: location,
      day: day,
      type: type,
      notificationEnabled: notificationEnabled,
      order: nextOrder,
    );

    try {
      print('  - Saving to Firestore...');
      await _scheduleService.addScheduleItem(newItem);
      print('  - ✅ Saved to Firestore successfully');

      _schedule.putIfAbsent(day, () => []).add(newItem);

      // Sort the items by order
      _schedule[day]!.sort((a, b) {
        final aOrder = _getItemOrder(a, 0);
        final bOrder = _getItemOrder(b, 0);
        return aOrder.compareTo(bOrder);
      });

      // Schedule automatic notification for this class only if enabled
      if (notificationEnabled) {
        print('  - Scheduling local notification...');
        await _scheduleClassNotification(newItem);
        print('  - ✅ Local notification scheduled');
      } else {
        print('  - ⚠️ Notification disabled, skipping notification scheduling');
      }

      notifyListeners();
      print('🗓️ === ADD SCHEDULE ITEM COMPLETE ===');
    } catch (e) {
      print('  - ❌ Error adding schedule item: $e');
      _error = 'Failed to add item: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> removeScheduleItem(String day, String itemId) async {
    try {
      await _scheduleService.removeScheduleItem(itemId);
      _schedule[day]?.removeWhere((item) => item.id == itemId);

      // Remove scheduled notifications for this class
      await _removeClassNotifications(itemId);

      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove item: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> toggleNotificationForItem(String day, String itemId) async {
    try {
      final dayItems = _schedule[day];
      if (dayItems == null) return;

      final itemIndex = dayItems.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) return;

      final item = dayItems[itemIndex];
      final updatedItem = item.copyWith(
        notificationEnabled: !item.notificationEnabled,
      );

      // Update in Firestore
      await _scheduleService.addScheduleItem(updatedItem);

      // Update local state
      dayItems[itemIndex] = updatedItem;

      // Handle notifications
      if (updatedItem.notificationEnabled) {
        // Schedule notification if enabled
        await _scheduleClassNotification(updatedItem);
      } else {
        // Remove notification if disabled
        await _removeClassNotifications(itemId);
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to toggle notification: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> updateScheduleItem(ScheduleItem updatedItem) async {
    try {
      await _scheduleService.addScheduleItem(updatedItem);

      final dayItems = _schedule[updatedItem.day];
      if (dayItems != null) {
        final itemIndex = dayItems.indexWhere(
          (item) => item.id == updatedItem.id,
        );
        if (itemIndex != -1) {
          dayItems[itemIndex] = updatedItem;

          // Handle notifications based on preference
          if (updatedItem.notificationEnabled) {
            await _scheduleClassNotification(updatedItem);
          } else {
            await _removeClassNotifications(updatedItem.id);
          }
        }
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to update item: ${e.toString()}';
      notifyListeners();
    }
  }

  // Schedule automatic notification for a class (local on mobile)
  Future<void> _scheduleClassNotification(ScheduleItem item) async {
    print('📅 === SCHEDULE CLASS NOTIFICATION DEBUG ===');
    print('  - Item ID: ${item.id}');
    print('  - Subject: ${item.title}');
    print('  - Day: ${item.day}');
    print('  - Time: ${item.time}');
    print('  - Type: ${item.type}');
    print('  - Is Web: ${kIsWeb}');

    try {
      // Convert day name to day of week
      final dayOfWeek = _getDayOfWeek(item.day);
      print('  - Day of week number: $dayOfWeek');
      if (dayOfWeek == null) {
        print('  - ❌ Failed to convert day name to day of week');
        return;
      }

      // Parse time (handle AM/PM format)
      final timeParts = item.time.split(':');
      print('  - Time parts: $timeParts');
      if (timeParts.length != 2) {
        print('  - ❌ Invalid time format');
        return;
      }

      final hourPart = timeParts[0];
      final minuteAndPeriod = timeParts[1]; // e.g., "55 PM" or "30 AM"

      // Extract minute and AM/PM
      final minuteMatch = RegExp(
        r'(\d+)\s*(AM|PM)?',
      ).firstMatch(minuteAndPeriod);
      print('  - Minute match: $minuteMatch');

      if (minuteMatch == null) {
        print('  - ❌ Failed to parse minute/period');
        return;
      }

      final minute = int.tryParse(minuteMatch.group(1) ?? '');
      final period = minuteMatch.group(2); // 'AM' or 'PM' or null
      print('  - Extracted minute: $minute, period: $period');

      if (minute == null) {
        print('  - ❌ Failed to parse minute');
        return;
      }

      // Parse hour and convert from 12-hour to 24-hour format if needed
      int? hour = int.tryParse(hourPart);
      if (hour == null) {
        print('  - ❌ Failed to parse hour');
        return;
      }

      if (period != null) {
        // Convert 12-hour to 24-hour format
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      print('  - Final parsed hour: $hour, minute: $minute');

      if (!kIsWeb) {
        // Lectures are typically one-time, sections are recurring weekly
        final isRecurring = item.type == ScheduleItemType.section;
        print('  - Is recurring: $isRecurring (${item.type})');
        print('  - Calling LocalNotificationService.scheduleClassReminder...');

        await LocalNotificationService.instance.scheduleClassReminder(
          scheduleItemId: item.id,
          subjectName: item.title,
          weekday: dayOfWeek,
          classHour: hour,
          classMinute: minute,
          isRecurring: isRecurring,
          classType:
              item.type == ScheduleItemType.section ? 'section' : 'lecture',
        );
        print('  - ✅ LocalNotificationService.scheduleClassReminder completed');
      } else {
        print('  - On web, using remote scheduling...');
        // Web: still rely on server-side triggers (no local scheduling)
        // Fallback to existing remote scheduling if needed
        await _notificationService.scheduleClassReminder(
          userId: _getCurrentUserId(),
          subjectName: item.title,
          classDateTime: DateTime.now(),
          reminderTime: DateTime.now(),
        );
        print('  - ✅ Remote scheduling completed');
      }
      print('📅 === SCHEDULE CLASS NOTIFICATION COMPLETE ===');
    } catch (e) {
      print('  - ❌ Error scheduling class notification: $e');
    }
  }

  // Remove scheduled notifications for a class
  Future<void> _removeClassNotifications(String itemId) async {
    try {
      if (!kIsWeb) {
        await LocalNotificationService.instance.cancelClassReminder(itemId);
      }
    } catch (e) {
      //debugprint('Error removing class notifications: $e');
    }
  }

  // Helper method to get current user ID
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    return user?.uid ?? '';
  }

  // Convert Arabic day name to day of week
  int? _getDayOfWeek(String dayName) {
    switch (dayName) {
      case 'السبت':
        return DateTime.saturday;
      case 'الاحد':
        return DateTime.sunday;
      case 'الاثنين':
        return DateTime.monday;
      case 'الثلاثاء':
        return DateTime.tuesday;
      case 'الاربعاء':
        return DateTime.wednesday;
      case 'الخميس':
        return DateTime.thursday;
      default:
        return null;
    }
  }

  // Get next occurrence of a day of week
  DateTime? _getNextOccurrence(int dayOfWeek) {
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday;

    int daysUntilNext = dayOfWeek - currentDayOfWeek;
    if (daysUntilNext <= 0) {
      daysUntilNext += 7; // Next week
    }

    return DateTime(now.year, now.month, now.day + daysUntilNext);
  }
}
