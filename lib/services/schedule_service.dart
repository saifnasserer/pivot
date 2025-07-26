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
          fromFirestore: (snapshot, _) => ScheduleItem.fromJson(snapshot.data()!),
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
}
