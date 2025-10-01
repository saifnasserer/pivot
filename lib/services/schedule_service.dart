import 'package:firebase_auth/firebase_auth.dart';
import '../screens/models/schedule_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper to get the user's schedule collection reference
  CollectionReference<ScheduleItem> _getScheduleCollection() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('schedule')
        .withConverter<ScheduleItem>(
          fromFirestore:
              (snapshot, _) => ScheduleItem.fromJson(snapshot.data()!),
          toFirestore: (item, _) => item.toJson(),
        );
  }

  // Fetch all schedule items for the logged-in user
  Future<Map<String, List<ScheduleItem>>> getSchedule() async {
    final snapshot = await _getScheduleCollection().get();

    final scheduleMap = <String, List<ScheduleItem>>{};
    for (var doc in snapshot.docs) {
      final item = doc.data();
      scheduleMap.putIfAbsent(item.day, () => []).add(item);
    }

    // Sort each day's items by order
    for (var entry in scheduleMap.entries) {
      final day = entry.key;
      final dayItems = entry.value;
      for (int i = 0; i < dayItems.length; i++) {}

      dayItems.sort((a, b) {
        final aOrder = a.order ?? 0;
        final bOrder = b.order ?? 0;
        return aOrder.compareTo(bOrder);
      });

      for (int i = 0; i < dayItems.length; i++) {}
    }

    return scheduleMap;
  }

  // Add a new schedule item
  Future<void> addScheduleItem(ScheduleItem item) async {
    try {
      final user = _auth.currentUser;
      print('🔐 Schedule Service: Adding item');
      print('  - User ID: ${user?.uid}');
      print('  - Path: users/${user?.uid}/schedule/${item.id}');
      print('  - Item data: ${item.toJson()}');

      await _getScheduleCollection().doc(item.id).set(item);
      print('  - ✅ Item added successfully');
    } catch (e) {
      print('  - ❌ Error adding schedule item: $e');
      print('  - Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Remove a schedule item by its ID
  Future<void> removeScheduleItem(String itemId) async {
    await _getScheduleCollection().doc(itemId).delete();
  }

  // Reorder schedule items for a specific day
  Future<void> reorderScheduleItems(
    String day,
    List<ScheduleItem> items,
  ) async {
    final batch = _firestore.batch();

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      // Create a new item with the updated order
      final updatedItem = item.copyWith(order: i);
      batch.set(_getScheduleCollection().doc(item.id), updatedItem);
    }

    await batch.commit();
  }
}
