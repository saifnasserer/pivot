import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/models/scheduled_notification.dart';

class UserNotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user notifications
  Future<List<ScheduledNotification>> getUserNotifications({
    int limit = 50,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot =
          await _firestore
              .collection('notifications')
              .where('targetUserIds', arrayContains: user.uid)
              .orderBy('scheduledTime', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map((doc) => ScheduledNotification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user notifications: $e');
    }
  }

  // Get unread notifications
  Future<List<ScheduledNotification>> getUnreadNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot =
          await _firestore
              .collection('notifications')
              .where('targetUserIds', arrayContains: user.uid)
              .where('status', isEqualTo: 'sent')
              .orderBy('scheduledTime', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => ScheduledNotification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch unread notifications: $e');
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('notifications').doc(notificationId).update({
        'readBy': FieldValue.arrayUnion([user.uid]),
        'lastReadAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark multiple notifications as read
  Future<bool> markMultipleNotificationsAsRead(
    List<String> notificationIds,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final batch = _firestore.batch();
      for (var notificationId in notificationIds) {
        final docRef = _firestore
            .collection('notifications')
            .doc(notificationId);
        batch.update(docRef, {
          'readBy': FieldValue.arrayUnion([user.uid]),
          'lastReadAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      return true;
    } catch (e) {
      throw Exception('Failed to mark multiple notifications as read: $e');
    }
  }

  // Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final notifications = await getUnreadNotifications();
      final notificationIds = notifications.map((n) => n.id!).toList();

      return await markMultipleNotificationsAsRead(notificationIds);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('notifications').doc(notificationId).update({
        'deletedBy': FieldValue.arrayUnion([user.uid]),
        'deletedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete multiple notifications
  Future<bool> deleteMultipleNotifications(List<String> notificationIds) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final batch = _firestore.batch();
      for (var notificationId in notificationIds) {
        final docRef = _firestore
            .collection('notifications')
            .doc(notificationId);
        batch.update(docRef, {
          'deletedBy': FieldValue.arrayUnion([user.uid]),
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      return true;
    } catch (e) {
      throw Exception('Failed to delete multiple notifications: $e');
    }
  }

  // Get notification by ID
  Future<ScheduledNotification?> getNotificationById(
    String notificationId,
  ) async {
    try {
      final doc =
          await _firestore
              .collection('notifications')
              .doc(notificationId)
              .get();

      if (doc.exists) {
        return ScheduledNotification.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch notification by ID: $e');
    }
  }

  // Search notifications
  Future<List<ScheduledNotification>> searchNotifications(String query) async {
    try {
      final notifications = await getUserNotifications();
      final lowercaseQuery = query.toLowerCase();

      return notifications.where((notification) {
        return notification.title.toLowerCase().contains(lowercaseQuery) ||
            notification.body.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search notifications: $e');
    }
  }

  // Get notifications by type
  Future<List<ScheduledNotification>> getNotificationsByType(
    String type,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot =
          await _firestore
              .collection('notifications')
              .where('targetUserIds', arrayContains: user.uid)
              .where('additionalData.type', isEqualTo: type)
              .orderBy('scheduledTime', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => ScheduledNotification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications by type: $e');
    }
  }

  // Get notifications by date range
  Future<List<ScheduledNotification>> getNotificationsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot =
          await _firestore
              .collection('notifications')
              .where('targetUserIds', arrayContains: user.uid)
              .where(
                'scheduledTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'scheduledTime',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .orderBy('scheduledTime', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => ScheduledNotification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications by date range: $e');
    }
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final allNotifications = await getUserNotifications();
      final unreadNotifications = await getUnreadNotifications();

      int totalNotifications = allNotifications.length;
      int unreadCount = unreadNotifications.length;
      int readCount = totalNotifications - unreadCount;

      Map<String, int> typeCounts = {};
      Map<String, int> statusCounts = {};

      for (var notification in allNotifications) {
        // Count by type
        final type =
            notification.additionalData?['type'] as String? ?? 'general';
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;

        // Count by status
        statusCounts[notification.status] =
            (statusCounts[notification.status] ?? 0) + 1;
      }

      return {
        'totalNotifications': totalNotifications,
        'unreadCount': unreadCount,
        'readCount': readCount,
        'typeCounts': typeCounts,
        'statusCounts': statusCounts,
        'hasNotifications': totalNotifications > 0,
        'hasUnreadNotifications': unreadCount > 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch notification statistics: $e');
    }
  }

  // Get recent notifications
  Future<List<ScheduledNotification>> getRecentNotifications({
    int limit = 10,
  }) async {
    try {
      final notifications = await getUserNotifications(limit: limit);
      return notifications.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent notifications: $e');
    }
  }

  // Create notification (for testing/admin purposes)
  Future<bool> createNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required List<String> targetUserIds,
    bool sendToAllUsers = false,
    String? department,
    String? level,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final notification = ScheduledNotification(
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        createdAt: DateTime.now(),
        createdBy: user.uid,
        createdByName: user.displayName ?? 'Unknown',
        targetUserIds: targetUserIds,
        sendToAllUsers: sendToAllUsers,
        department: department,
        level: level,
        status: 'pending',
        additionalData: additionalData,
      );

      await _firestore.collection('notifications').add(notification.toJson());

      return true;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Update notification preferences
  Future<bool> updateNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'notificationPreferences': preferences,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  // Get notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return {};

      final data = doc.data()!;
      final preferences =
          data['notificationPreferences'] as Map<String, dynamic>? ?? {};

      return preferences.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      throw Exception('Failed to fetch notification preferences: $e');
    }
  }
}
