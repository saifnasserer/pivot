import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserBlockingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Block a user
  static Future<bool> blockUser(String userIdToBlock) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore.collection('blocked_users').add({
        'userId': currentUser.uid,
        'blockedUserId': userIdToBlock,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error blocking user: $e');
      return false;
    }
  }

  /// Unblock a user
  static Future<bool> unblockUser(String userIdToUnblock) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final querySnapshot = await _firestore
          .collection('blocked_users')
          .where('userId', isEqualTo: currentUser.uid)
          .where('blockedUserId', isEqualTo: userIdToUnblock)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error unblocking user: $e');
      return false;
    }
  }

  /// Check if a user is blocked
  static Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final querySnapshot = await _firestore
          .collection('blocked_users')
          .where('userId', isEqualTo: currentUser.uid)
          .where('blockedUserId', isEqualTo: userId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }

  /// Get list of blocked users
  static Future<List<String>> getBlockedUserIds() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final querySnapshot = await _firestore
          .collection('blocked_users')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['blockedUserId'] as String)
          .toList();
    } catch (e) {
      print('Error getting blocked users: $e');
      return [];
    }
  }
}

