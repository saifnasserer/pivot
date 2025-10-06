import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/services/local_notification_service.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, List<ScheduleItem>>> fetchSchedule() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final snapshot =
          await _firestore.collection('schedules').doc(user.uid).get();

      if (!snapshot.exists) {
        return {};
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final schedule = <String, List<ScheduleItem>>{};

      for (final entry in data.entries) {
        if (entry.value is List) {
          final items =
              (entry.value as List)
                  .map(
                    (item) =>
                        ScheduleItem.fromMap(item as Map<String, dynamic>),
                  )
                  .toList();
          schedule[entry.key] = items;
        }
      }

      return schedule;
    } catch (e) {
      throw Exception('Failed to fetch schedule: $e');
    }
  }

  Future<void> addScheduleItem(ScheduleItem item) async {
    try {
      final user = _auth.currentUser;
      print('🔐 === ADD SCHEDULE ITEM DEBUG ===');
      print('  - User authenticated: ${user != null}');
      print('  - User ID: ${user?.uid}');
      print('  - User email: ${user?.email}');

      if (user == null) throw Exception('User not authenticated');

      final scheduleRef = _firestore.collection('schedules').doc(user.uid);
      print('  - Firestore path: schedules/${user.uid}');
      print('  - Item day: ${item.day}');
      print('  - Item data: ${item.toMap()}');

      print('  - Starting transaction...');
      await _firestore.runTransaction((transaction) async {
        print('    - Transaction: Getting document...');
        final snapshot = await transaction.get(scheduleRef);
        print('    - Transaction: Document exists: ${snapshot.exists}');

        final data = snapshot.data() ?? {};
        print('    - Transaction: Current data keys: ${data.keys.toList()}');

        final dayItems = List<Map<String, dynamic>>.from(data[item.day] ?? []);
        print(
          '    - Transaction: Current items for ${item.day}: ${dayItems.length}',
        );

        dayItems.add(item.toMap());
        data[item.day] = dayItems;
        print(
          '    - Transaction: New items for ${item.day}: ${dayItems.length}',
        );

        print('    - Transaction: Setting document...');
        transaction.set(scheduleRef, data);
        print('    - Transaction: Set complete');
      });
      print('  - ✅ Transaction committed successfully');

      // Schedule notification for the class
      if (item.notificationEnabled) {
        final timeComponents = _parseTimeString(item.time);
        if (timeComponents != null) {
          print('📅 Scheduling WEEKLY notification:');
          print(
            '   Class day: ${item.day} (weekday: ${_getDayOfWeek(item.day)})',
          );
          print(
            '   Class time: ${timeComponents['hour']}:${timeComponents['minute']}',
          );
          print(
            '   Notification will fire: Every ${item.day} at ${timeComponents['hour']}:${timeComponents['minute']! - 15}',
          );

          await LocalNotificationService.instance.scheduleClassReminder(
            scheduleItemId: item.id,
            subjectName: item.title,
            weekday: _getDayOfWeek(item.day),
            classHour: timeComponents['hour']!,
            classMinute: timeComponents['minute']!,
            isRecurring: true, // ✅ ALWAYS recurring weekly
            classType:
                item.type == ScheduleItemType.lecture ? 'lecture' : 'section',
          );
        }
      }
    } catch (e) {
      print('  - ❌ Error in addScheduleItem:');
      print('  - Error: $e');
      print('  - Error type: ${e.runtimeType}');
      throw Exception('Failed to add schedule item: $e');
    }
  }

  Future<void> updateScheduleItem(String id, ScheduleItem item) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final scheduleRef = _firestore.collection('schedules').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(scheduleRef);
        final data = snapshot.data() ?? {};
        final dayItems = List<Map<String, dynamic>>.from(data[item.day] ?? []);

        final index = dayItems.indexWhere((item) => item['id'] == id);
        if (index != -1) {
          dayItems[index] = item.toMap();
          data[item.day] = dayItems;
          transaction.set(scheduleRef, data);
        }
      });

      // Cancel existing notification and reschedule if enabled
      await LocalNotificationService.instance.cancelClassReminder(item.id);

      if (item.notificationEnabled) {
        final timeComponents = _parseTimeString(item.time);
        if (timeComponents != null) {
          await LocalNotificationService.instance.scheduleClassReminder(
            scheduleItemId: item.id,
            subjectName: item.title,
            weekday: _getDayOfWeek(item.day),
            classHour: timeComponents['hour']!,
            classMinute: timeComponents['minute']!,
            isRecurring: true, // ✅ ALWAYS recurring weekly
            classType:
                item.type == ScheduleItemType.lecture ? 'lecture' : 'section',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to update schedule item: $e');
    }
  }

  Future<void> deleteScheduleItem(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final scheduleRef = _firestore.collection('schedules').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(scheduleRef);
        final data = snapshot.data() ?? {};

        for (final day in data.keys) {
          final dayItems = List<Map<String, dynamic>>.from(data[day] ?? []);
          final updatedItems =
              dayItems.where((item) => item['id'] != id).toList();
          data[day] = updatedItems;
        }

        transaction.set(scheduleRef, data);
      });

      // Cancel scheduled notification by hashing the id
      // Note: We use a stable hash to ensure consistent notification IDs
    } catch (e) {
      throw Exception('Failed to delete schedule item: $e');
    }
  }

  Future<void> reorderScheduleItems(
    String day,
    List<ScheduleItem> items,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final scheduleRef = _firestore.collection('schedules').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(scheduleRef);
        final data = snapshot.data() ?? {};

        // Update order values
        for (int i = 0; i < items.length; i++) {
          items[i] = items[i].copyWith(order: i);
        }

        data[day] = items.map((item) => item.toMap()).toList();
        transaction.set(scheduleRef, data);
      });
    } catch (e) {
      throw Exception('Failed to reorder schedule items: $e');
    }
  }

  Future<void> scheduleNotifications() async {
    try {
      final schedule = await fetchSchedule();

      for (final dayItems in schedule.values) {
        for (final item in dayItems) {
          if (item.notificationEnabled) {
            final timeComponents = _parseTimeString(item.time);
            if (timeComponents != null) {
              await LocalNotificationService.instance.scheduleClassReminder(
                scheduleItemId: item.id,
                subjectName: item.title,
                weekday: _getDayOfWeek(item.day),
                classHour: timeComponents['hour']!,
                classMinute: timeComponents['minute']!,
                isRecurring: true, // ✅ ALWAYS recurring weekly
                classType:
                    item.type == ScheduleItemType.lecture
                        ? 'lecture'
                        : 'section',
              );
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to schedule notifications: $e');
    }
  }

  Future<void> cancelNotifications() async {
    try {
      // Cancel all class reminders
      final schedule = await fetchSchedule();

      for (final dayItems in schedule.values) {
        for (final item in dayItems) {
          await LocalNotificationService.instance.cancelClassReminder(item.id);
        }
      }
    } catch (e) {
      throw Exception('Failed to cancel notifications: $e');
    }
  }

  // Helper method to parse time strings into hour and minute components
  Map<String, int>? _parseTimeString(String timeString) {
    try {
      // Handle various time formats
      final trimmed = timeString.trim();

      // Try to parse as HH:MM format first
      if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        if (parts.length >= 2) {
          // Extract hour and minute, handling AM/PM if present
          String hourStr = parts[0].trim();
          String minuteStr = parts[1].trim();

          // Remove AM/PM from minute string if present
          bool isPM = false;
          if (minuteStr.contains('PM')) {
            isPM = true;
            minuteStr = minuteStr.replaceAll('PM', '').trim();
          } else if (minuteStr.contains('AM')) {
            minuteStr = minuteStr.replaceAll('AM', '').trim();
          }

          // Parse hour and minute
          int hour = int.parse(hourStr);
          int minute = int.parse(minuteStr);

          // Convert to 24-hour format if needed
          if (isPM && hour != 12) {
            hour += 12;
          } else if (!isPM && hour == 12) {
            hour = 0;
          }

          return {'hour': hour, 'minute': minute};
        }
      }

      // Try to parse as a simple number (assuming it's in HHMM format)
      final numericOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');
      if (numericOnly.length >= 3) {
        int hour = int.parse(numericOnly.substring(0, numericOnly.length - 2));
        int minute = int.parse(numericOnly.substring(numericOnly.length - 2));
        return {'hour': hour, 'minute': minute};
      }

      return null;
    } catch (e) {
      print('Error parsing time string "$timeString": $e');
      return null;
    }
  }

  // Helper method to convert day name to weekday number
  int _getDayOfWeek(String day) {
    final normalizedDay = day.toLowerCase().trim();

    switch (normalizedDay) {
      case 'saturday':
      case 'السبت':
        return DateTime.saturday;
      case 'sunday':
      case 'الأحد':
      case 'الاحد': // Without hamza
        return DateTime.sunday;
      case 'monday':
      case 'الإثنين': // With hamza
      case 'الاثنين': // Without hamza ✅
        return DateTime.monday;
      case 'tuesday':
      case 'الثلاثاء':
        return DateTime.tuesday;
      case 'wednesday':
      case 'الأربعاء':
      case 'الاربعاء': // Without hamza
        return DateTime.wednesday;
      case 'thursday':
      case 'الخميس':
        return DateTime.thursday;
      case 'friday':
      case 'الجمعة':
        return DateTime.friday;
      default:
        print('⚠️ Unknown day name: "$day" - defaulting to Saturday');
        return DateTime.saturday;
    }
  }
}
