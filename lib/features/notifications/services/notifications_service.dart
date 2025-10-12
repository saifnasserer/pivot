import 'package:flutter/material.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:pivot/services/local_notification_service.dart';
import 'package:pivot/services/notification_test_service.dart';
import 'package:pivot/models/scheduled_notification.dart';
import 'package:pivot/models/user_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsService {
  final NotificationService _notificationService = NotificationService();
  final LocalNotificationService _localNotificationService =
      LocalNotificationService.instance;
  final NotificationTestService _testService = NotificationTestService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notification services
  Future<void> initialize([BuildContext? context]) async {
    if (context != null) {
      await _notificationService.initialize(context);
    }
    await _localNotificationService.initialize();
  }

  // Send immediate notification
  Future<bool> sendNotification({
    required String targetToken,
    required String title,
    required String body,
    String? userId,
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async {
    return await _notificationService.sendNotification(
      targetToken: targetToken,
      title: title,
      body: body,
      userId: userId,
      data: data,
      icon: icon,
      color: color,
      sound: sound,
      imageUrl: imageUrl,
    );
  }

  // Send notification to multiple users
  Future<Map<String, dynamic>> sendMultipleNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async {
    final tokens = await _notificationService.getMultipleUserFCMTokens(userIds);

    if (tokens.isEmpty) {
      return {
        'success': false,
        'sentCount': 0,
        'totalCount': userIds.length,
        'error': 'No valid FCM tokens found',
      };
    }

    int successCount = 0;
    List<String> errors = [];

    for (String token in tokens) {
      try {
        final success = await _notificationService.sendNotification(
          targetToken: token,
          title: title,
          body: body,
          data: data,
          icon: icon,
          color: color,
          sound: sound,
          imageUrl: imageUrl,
        );
        if (success) successCount++;
      } catch (e) {
        errors.add('Failed to send to token: $e');
      }
    }

    return {
      'success': successCount > 0,
      'sentCount': successCount,
      'totalCount': tokens.length,
      'errors': errors,
    };
  }

  // Send notification to all users
  Future<Map<String, dynamic>> sendNotificationToAllUsers({
    required String title,
    required String body,
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async {
    final tokens = await _notificationService.getAllUserFCMTokens();

    if (tokens.isEmpty) {
      return {
        'success': false,
        'sentCount': 0,
        'totalCount': 0,
        'error': 'No valid FCM tokens found',
      };
    }

    int successCount = 0;
    List<String> errors = [];

    for (String token in tokens) {
      try {
        final success = await _notificationService.sendNotification(
          targetToken: token,
          title: title,
          body: body,
          data: data,
          icon: icon,
          color: color,
          sound: sound,
          imageUrl: imageUrl,
        );
        if (success) successCount++;
      } catch (e) {
        errors.add('Failed to send to token: $e');
      }
    }

    return {
      'success': successCount > 0,
      'sentCount': successCount,
      'totalCount': tokens.length,
      'errors': errors,
    };
  }

  // Send filtered notification by department and/or level
  Future<Map<String, dynamic>> sendFilteredNotification({
    required String title,
    required String body,
    String? department,
    String? level,
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async {
    try {
      // Build query to filter users
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .where('tokenStatus', isEqualTo: 'active');

      // Add department filter if provided
      if (department != null && department.isNotEmpty) {
        query = query.where('department', isEqualTo: department);
      }

      // Add level filter if provided
      if (level != null && level.isNotEmpty) {
        query = query.where('level', isEqualTo: level);
      }

      final usersSnapshot = await query.get();

      if (usersSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'sentCount': 0,
          'totalCount': 0,
          'error':
              'No users found matching criteria (department: $department, level: $level)',
        };
      }

      final tokens =
          usersSnapshot.docs
              .map((doc) => doc.data()['fcmToken'] as String?)
              .where((token) => token != null && token.isNotEmpty)
              .cast<String>()
              .toList();

      if (tokens.isEmpty) {
        return {
          'success': false,
          'sentCount': 0,
          'totalCount': 0,
          'error': 'No valid FCM tokens found',
        };
      }

      int successCount = 0;
      List<String> errors = [];

      for (String token in tokens) {
        try {
          final success = await _notificationService.sendNotification(
            targetToken: token,
            title: title,
            body: body,
            data: {
              ...?data,
              'type': 'announcement',
              if (department != null) 'department': department,
              if (level != null) 'level': level,
            },
            icon: icon,
            color: color,
            sound: sound,
            imageUrl: imageUrl,
          );
          if (success) successCount++;
        } catch (e) {
          errors.add('Failed to send to token: $e');
        }
      }

      return {
        'success': successCount > 0,
        'sentCount': successCount,
        'totalCount': tokens.length,
        'errors': errors,
      };
    } catch (e) {
      return {
        'success': false,
        'sentCount': 0,
        'totalCount': 0,
        'error': e.toString(),
      };
    }
  }

  // Create scheduled notification
  Future<bool> createScheduledNotification(
    ScheduledNotification notification,
  ) async {
    try {
      final docRef = await _firestore
          .collection('scheduledNotifications')
          .add(notification.toJson());

      notification = notification.copyWith(id: docRef.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get scheduled notifications
  Future<List<ScheduledNotification>> getScheduledNotifications() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('scheduledNotifications')
              .orderBy('scheduledTime', descending: false)
              .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                ScheduledNotification.fromJson({'id': doc.id, ...doc.data()}),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get pending scheduled notifications
  Future<List<ScheduledNotification>> getPendingScheduledNotifications() async {
    final allNotifications = await getScheduledNotifications();
    return allNotifications.where((n) => n.isPending).toList();
  }

  // Execute scheduled notification
  Future<bool> executeScheduledNotification(
    ScheduledNotification notification,
  ) async {
    try {
      List<String> tokens = [];

      if (notification.sendToAllUsers) {
        tokens = await _notificationService.getAllUserFCMTokens();
      } else {
        tokens = await _notificationService.getMultipleUserFCMTokens(
          notification.targetUserIds,
        );
      }

      if (tokens.isEmpty) {
        await _updateNotificationStatus(
          notification.id!,
          'failed',
          errorMessage: 'No valid FCM tokens found',
        );
        return false;
      }

      int successCount = 0;
      for (String token in tokens) {
        final success = await _notificationService.sendNotification(
          targetToken: token,
          title: notification.title,
          body: notification.body,
        );
        if (success) successCount++;
      }

      final newStatus = successCount > 0 ? 'sent' : 'failed';
      final errorMessage =
          successCount == 0 ? 'Failed to send all notifications' : null;

      await _updateNotificationStatus(
        notification.id!,
        newStatus,
        sentCount: successCount,
        totalCount: tokens.length,
        errorMessage: errorMessage,
      );

      return successCount > 0;
    } catch (e) {
      await _updateNotificationStatus(
        notification.id!,
        'failed',
        errorMessage: 'Error sending notification: $e',
      );
      return false;
    }
  }

  // Update notification status
  Future<void> _updateNotificationStatus(
    String notificationId,
    String status, {
    int? sentCount,
    int? totalCount,
    String? errorMessage,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (sentCount != null) updateData['sentCount'] = sentCount;
      if (totalCount != null) updateData['totalCount'] = totalCount;
      if (errorMessage != null) updateData['errorMessage'] = errorMessage;

      await _firestore
          .collection('scheduledNotifications')
          .doc(notificationId)
          .update(updateData);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  // Delete scheduled notification
  Future<bool> deleteScheduledNotification(String notificationId) async {
    try {
      await _firestore
          .collection('scheduledNotifications')
          .doc(notificationId)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user notifications
  Future<List<UserNotification>> getUserNotifications(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();

      return snapshot.docs
          .map((doc) => UserNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Test notification system
  Future<Map<String, dynamic>> testNotificationSystem() async {
    return await _testService.runFullNotificationTest();
  }

  // Get FCM token statistics
  Future<Map<String, dynamic>> getTokenStatistics() async {
    return await _notificationService.getTokenStatistics();
  }

  // Cleanup invalid tokens
  Future<Map<String, dynamic>> cleanupInvalidTokens() async {
    return await _notificationService.cleanupInvalidTokens();
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    return await _notificationService.requestPermissionsExplicitly();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  // Get current user's FCM token
  Future<String?> getCurrentUserToken() async {
    return await _notificationService.getToken();
  }

  // Save token to Firestore
  Future<void> saveTokenToFirestore(String token) async {
    await _notificationService.saveTokenToFirestore(token);
  }
}
