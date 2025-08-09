import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/models/schedule_item.dart';

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
    print('🔄 ScheduleService: Fetching schedule from Firestore...');
    final snapshot = await _getScheduleCollection().get();
    print('🔄 ScheduleService: Received ${snapshot.docs.length} documents');

    final scheduleMap = <String, List<ScheduleItem>>{};
    for (var doc in snapshot.docs) {
      final item = doc.data();
      print(
        '📄 Document: ${item.title} (day: ${item.day}, order: ${item.order ?? 'null'})',
      );
      scheduleMap.putIfAbsent(item.day, () => []).add(item);
    }

    // Sort each day's items by order
    for (var entry in scheduleMap.entries) {
      final day = entry.key;
      final dayItems = entry.value;
      print('📅 Day $day: Before sorting - ${dayItems.length} items');
      for (int i = 0; i < dayItems.length; i++) {
        print(
          '  [$i] ${dayItems[i].title} (order: ${dayItems[i].order ?? 'null'})',
        );
      }

      dayItems.sort((a, b) {
        final aOrder = a.order ?? 0;
        final bOrder = b.order ?? 0;
        return aOrder.compareTo(bOrder);
      });

      print('📅 Day $day: After sorting by order');
      for (int i = 0; i < dayItems.length; i++) {
        print(
          '  [$i] ${dayItems[i].title} (order: ${dayItems[i].order ?? 'null'})',
        );
      }
    }

    return scheduleMap;
  }

  // Add a new schedule item
  Future<void> addScheduleItem(ScheduleItem item) async {
    await _getScheduleCollection().doc(item.id).set(item);
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
    print('📝 ScheduleService: Reordering ${items.length} items for day: $day');

    final batch = _firestore.batch();

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      // Create a new item with the updated order
      final updatedItem = item.copyWith(order: i);
      print(
        '  📝 Setting ${item.title} to order $i (was ${item.order ?? 'null'})',
      );
      batch.set(_getScheduleCollection().doc(item.id), updatedItem);
    }

    print('📝 ScheduleService: Committing batch to Firestore...');
    await batch.commit();
    print('✅ ScheduleService: Batch committed successfully');
  }
}
