import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/screens/models/schedule_item.dart';

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

      // TODO: Implement notification services
      // if (item.notificationEnabled) {
      //   await NotificationTriggerService().scheduleNotification(item);
      // }
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

      // TODO: Implement notification services
      // await NotificationTriggerService().cancelNotification(id);
      // if (item.notificationEnabled) {
      //   await NotificationTriggerService().scheduleNotification(item);
      // }
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

      // TODO: Implement notification services
      // await NotificationTriggerService().cancelNotification(id);
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
      // final schedule = await fetchSchedule();
      // TODO: Implement notification services
      // for (final dayItems in schedule.values) {
      //   for (final item in dayItems) {
      //     if (item.notificationEnabled) {
      //       await NotificationTriggerService().scheduleNotification(item);
      //     }
      //   }
      // }
    } catch (e) {
      throw Exception('Failed to schedule notifications: $e');
    }
  }

  Future<void> cancelNotifications() async {
    try {
      // TODO: Implement notification services
      // await LocalNotificationService().cancelAllNotifications();
    } catch (e) {
      throw Exception('Failed to cancel notifications: $e');
    }
  }
}
