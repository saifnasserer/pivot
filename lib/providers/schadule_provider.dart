import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/models/schedule_item.dart';
import '../services/schedule_service.dart';
import '../services/notification_trigger_service.dart';
import 'package:pivot/services/cache_service.dart';

class ScheduleProvider with ChangeNotifier {
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
        notifyListeners();
      }

      // Step 2: Fetch from server in the background
      _schedule = await _scheduleService.getSchedule();
      // Flatten schedule to a list for caching
      final allItems = _schedule.values.expand((list) => list).toList();
      await CacheService.instance.cacheSchedule(allItems);
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
    final newItem = ScheduleItem(
      id: _uuid.v4(),
      title: title,
      time: time,
      location: location,
      day: day,
      type: type,
      notificationEnabled: notificationEnabled,
    );

    try {
      await _scheduleService.addScheduleItem(newItem);
      _schedule.putIfAbsent(day, () => []).add(newItem);

      // Schedule automatic notification for this class only if enabled
      if (notificationEnabled) {
        await _scheduleClassNotification(newItem);
      }

      notifyListeners();
    } catch (e) {
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

  // Schedule automatic notification for a class
  Future<void> _scheduleClassNotification(ScheduleItem item) async {
    try {
      // Convert day name to day of week
      final dayOfWeek = _getDayOfWeek(item.day);
      if (dayOfWeek == null) return;

      // Get next occurrence of this day
      final nextClassDate = _getNextOccurrence(dayOfWeek);
      if (nextClassDate == null) return;

      // Parse time
      final timeParts = item.time.split(':');
      if (timeParts.length != 2) return;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) return;

      // Calculate class start time
      final classStartTime = DateTime(
        nextClassDate.year,
        nextClassDate.month,
        nextClassDate.day,
        hour,
        minute,
      );

      // Calculate reminder time (15 minutes before class)
      final reminderTime = classStartTime.subtract(const Duration(minutes: 15));

      // Only schedule if reminder time is in the future
      if (reminderTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleClassReminder(
          userId: _getCurrentUserId(),
          subjectName: item.title,
          classDateTime: classStartTime,
          reminderTime: reminderTime,
        );
      }
    } catch (e) {
      //debugprint('Error scheduling class notification: $e');
    }
  }

  // Remove scheduled notifications for a class
  Future<void> _removeClassNotifications(String itemId) async {
    try {
      // Find the item to get its details
      ScheduleItem? itemToRemove;
      for (var dayItems in _schedule.values) {
        final item = dayItems.firstWhere(
          (item) => item.id == itemId,
          orElse:
              () => ScheduleItem(
                id: '',
                title: '',
                time: '',
                location: '',
                day: '',
                type: ScheduleItemType.lecture,
              ),
        );
        if (item.id.isNotEmpty) {
          itemToRemove = item;
          break;
        }
      }

      if (itemToRemove != null) {
        // Remove scheduled notifications for this class
        // This would require additional logic to identify and remove specific notifications
        //debugprint('Removed notifications for class: ${itemToRemove.title}');
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
