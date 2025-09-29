import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/screens/models/schedule_item.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's schedule
  Future<Map<String, List<ScheduleItem>>> getUserSchedule() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('schedule')
              .get();

      Map<String, List<ScheduleItem>> schedule = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final day = data['day'] as String;
        final item = ScheduleItem.fromJson(data);

        if (schedule[day] == null) {
          schedule[day] = [];
        }
        schedule[day]!.add(item);
      }

      // Sort items by time within each day
      for (var day in schedule.keys) {
        schedule[day]!.sort((a, b) => a.time.compareTo(b.time));
      }

      return schedule;
    } catch (e) {
      throw Exception('Failed to fetch user schedule: $e');
    }
  }

  // Get schedule for specific day
  Future<List<ScheduleItem>> getScheduleForDay(String day) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('schedule')
              .where('day', isEqualTo: day)
              .orderBy('time')
              .get();

      return snapshot.docs
          .map((doc) => ScheduleItem.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch schedule for day: $e');
    }
  }

  // Add schedule item
  Future<bool> addScheduleItem(ScheduleItem item) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('schedule')
          .doc(item.id)
          .set(item.toJson());

      return true;
    } catch (e) {
      throw Exception('Failed to add schedule item: $e');
    }
  }

  // Update schedule item
  Future<bool> updateScheduleItem(ScheduleItem item) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('schedule')
          .doc(item.id)
          .update(item.toJson());

      return true;
    } catch (e) {
      throw Exception('Failed to update schedule item: $e');
    }
  }

  // Remove schedule item
  Future<bool> removeScheduleItem(String itemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('schedule')
          .doc(itemId)
          .delete();

      return true;
    } catch (e) {
      throw Exception('Failed to remove schedule item: $e');
    }
  }

  // Toggle notification for schedule item
  Future<bool> toggleNotificationForItem(String itemId, bool enabled) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('schedule')
          .doc(itemId)
          .update({'notificationEnabled': enabled});

      return true;
    } catch (e) {
      throw Exception('Failed to toggle notification: $e');
    }
  }

  // Get schedule items by type
  Future<List<ScheduleItem>> getScheduleItemsByType(
    ScheduleItemType type,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('schedule')
              .where('type', isEqualTo: type.toString().split('.').last)
              .get();

      return snapshot.docs
          .map((doc) => ScheduleItem.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch schedule items by type: $e');
    }
  }

  // Search schedule items
  Future<List<ScheduleItem>> searchScheduleItems(String query) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('schedule')
              .get();

      final lowercaseQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => ScheduleItem.fromJson(doc.data()))
          .where((item) {
            return item.title.toLowerCase().contains(lowercaseQuery) ||
                item.location.toLowerCase().contains(lowercaseQuery);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to search schedule items: $e');
    }
  }

  // Get schedule statistics
  Future<Map<String, dynamic>> getScheduleStatistics() async {
    try {
      final schedule = await getUserSchedule();

      int totalItems = 0;
      int lecturesCount = 0;
      int sectionsCount = 0;
      int notificationsEnabled = 0;
      Map<String, int> dayCounts = {};

      for (var day in schedule.keys) {
        final items = schedule[day]!;
        totalItems += items.length;
        dayCounts[day] = items.length;

        for (var item in items) {
          if (item.type == ScheduleItemType.lecture) {
            lecturesCount++;
          } else {
            sectionsCount++;
          }

          if (item.notificationEnabled) {
            notificationsEnabled++;
          }
        }
      }

      return {
        'totalItems': totalItems,
        'lecturesCount': lecturesCount,
        'sectionsCount': sectionsCount,
        'notificationsEnabled': notificationsEnabled,
        'dayCounts': dayCounts,
        'averageItemsPerDay':
            dayCounts.isNotEmpty ? (totalItems / dayCounts.length).round() : 0,
        'hasSchedule': totalItems > 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch schedule statistics: $e');
    }
  }

  // Get upcoming schedule items
  Future<List<ScheduleItem>> getUpcomingItems({int limit = 5}) async {
    try {
      final schedule = await getUserSchedule();
      final now = DateTime.now();
      final currentDay = _getDayName(now.weekday);
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      List<ScheduleItem> upcomingItems = [];

      // Get remaining items for today
      if (schedule[currentDay] != null) {
        for (var item in schedule[currentDay]!) {
          if (item.time.compareTo(currentTime) > 0) {
            upcomingItems.add(item);
          }
        }
      }

      // Get items for next days
      final days = [
        'السبت',
        'الأحد',
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
      ];
      final currentDayIndex = days.indexOf(currentDay);

      for (int i = 1; i < 7 && upcomingItems.length < limit; i++) {
        final nextDayIndex = (currentDayIndex + i) % 7;
        final nextDay = days[nextDayIndex];

        if (schedule[nextDay] != null) {
          upcomingItems.addAll(schedule[nextDay]!);
        }
      }

      return upcomingItems.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming items: $e');
    }
  }

  // Get schedule items for date range
  Future<List<ScheduleItem>> getScheduleForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final schedule = await getUserSchedule();
      List<ScheduleItem> items = [];

      for (var day in schedule.keys) {
        for (var item in schedule[day]!) {
          // This is a simplified check - in a real app you'd parse the day and time
          // to determine if it falls within the date range
          items.add(item);
        }
      }

      return items;
    } catch (e) {
      throw Exception('Failed to fetch schedule for date range: $e');
    }
  }

  // Export schedule
  Future<Map<String, dynamic>> exportSchedule() async {
    try {
      final schedule = await getUserSchedule();
      final statistics = await getScheduleStatistics();

      return {
        'schedule': schedule.map(
          (day, items) =>
              MapEntry(day, items.map((item) => item.toJson()).toList()),
        ),
        'statistics': statistics,
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
    } catch (e) {
      throw Exception('Failed to export schedule: $e');
    }
  }

  // Import schedule
  Future<bool> importSchedule(Map<String, dynamic> scheduleData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      if (scheduleData.containsKey('schedule')) {
        final schedule = scheduleData['schedule'] as Map<String, dynamic>;

        for (var day in schedule.keys) {
          final items = schedule[day] as List<dynamic>;
          for (var itemData in items) {
            final item = ScheduleItem.fromJson(
              Map<String, dynamic>.from(itemData),
            );
            await addScheduleItem(item);
          }
        }
      }

      return true;
    } catch (e) {
      throw Exception('Failed to import schedule: $e');
    }
  }

  // Clear all schedule
  Future<bool> clearAllSchedule() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('schedule')
              .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return true;
    } catch (e) {
      throw Exception('Failed to clear all schedule: $e');
    }
  }

  // Helper method to get day name
  String _getDayName(int weekday) {
    const days = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];
    return days[weekday % 7];
  }
}
