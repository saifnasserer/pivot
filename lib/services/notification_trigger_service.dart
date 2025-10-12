import 'package:pivot/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for triggering FCM push notifications from server/admin
/// NOTE: This service is for SERVER-INITIATED notifications only
/// For scheduled task/class reminders, we are using LocalNotificationService instead
class NotificationTriggerService {
  static final NotificationTriggerService _instance =
      NotificationTriggerService._internal();
  factory NotificationTriggerService() => _instance;
  NotificationTriggerService._internal();

  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Analytics data structure
  final Map<String, Map<String, int>> _notificationAnalytics = {
    'sent': {
      'task_reminder': 0,
      'class_reminder': 0,
      'announcement': 0,
      'department': 0,
      'level': 0,
      'welcome': 0,
      'unknown': 0,
    },
    'opened': {
      'task_reminder': 0,
      'class_reminder': 0,
      'announcement': 0,
      'department': 0,
      'level': 0,
      'welcome': 0,
      'unknown': 0,
    },
    'failed': {
      'task_reminder': 0,
      'class_reminder': 0,
      'announcement': 0,
      'department': 0,
      'level': 0,
      'welcome': 0,
      'unknown': 0,
    },
  };

  // Update analytics
  void _updateAnalytics(String metric, String type) {
    _notificationAnalytics[metric]![type] =
        (_notificationAnalytics[metric]![type] ?? 0) + 1;
  }

  // Get analytics data
  Map<String, Map<String, int>> getAnalytics() {
    return Map.from(_notificationAnalytics);
  }

  // Record notification opened
  Future<void> recordNotificationOpened(String type) async {
    _updateAnalytics('opened', type);
  }

  // ===== FCM PUSH NOTIFICATION METHODS =====
  // These are for SERVER-INITIATED, DYNAMIC notifications only
  // For scheduled reminders, use LocalNotificationService

  /// Send immediate notification when a new task is created (by professor/admin)
  /// This is for IMMEDIATE notification, not scheduled reminders
  Future<void> sendNewTaskNotification(
    String userId,
    String taskName,
    DateTime dueDate,
  ) async {
    try {
      final token = await _notificationService.getUserFCMToken(userId);
      if (token != null) {
        print('📱 Sending immediate new task notification via FCM...');

        // Format due date for display
        final now = DateTime.now();
        final daysUntilDue = dueDate.difference(now).inDays;

        String dueText;
        if (daysUntilDue == 0) {
          dueText = 'اليوم';
        } else if (daysUntilDue == 1) {
          dueText = 'غداً';
        } else if (daysUntilDue > 1) {
          dueText = 'خلال $daysUntilDue أيام';
        } else {
          dueText = 'متأخر';
        }

        final success = await _notificationService.sendNotification(
          targetToken: token,
          userId: userId,
          title: 'تاسك جديد تم إضافته',
          body: 'تم إضافة التاسك "$taskName" - مطلوب $dueText',
          data: {
            'type': 'new_task',
            'taskName': taskName,
            'dueDate': dueDate.toIso8601String(),
          },
        );

        if (success) {
          print('✅ New task notification sent successfully');
        } else {
          print('❌ Failed to send new task notification');
        }
      } else {
        print('⚠️ No FCM token found for user');
      }
    } catch (e) {
      print('❌ Error sending new task notification: $e');
    }
  }

  /// Send announcement notifications to specific users or all users
  /// Can be filtered by department and/or level
  Future<void> sendAnnouncement(
    String title,
    String body, {
    List<String>? targetUserIds,
    String? department,
    String? level,
  }) async {
    try {
      if (targetUserIds != null && targetUserIds.isNotEmpty) {
        // Send to specific users
        for (String userId in targetUserIds) {
          final token = await _notificationService.getUserFCMToken(userId);
          if (token != null) {
            await _notificationService.sendNotification(
              targetToken: token,
              userId: userId,
              title: title,
              body: body,
              data: {'type': 'announcement'},
            );
          }
        }
      } else if (department != null || level != null) {
        // Filter by department and/or level
        await sendFilteredAnnouncement(
          title,
          body,
          department: department,
          level: level,
        );
      } else {
        // Broadcast to all users
        final tokens = await _notificationService.getAllUserFCMTokens();
        for (String token in tokens) {
          await _notificationService.sendNotification(
            targetToken: token,
            title: title,
            body: body,
            data: {'type': 'announcement'},
          );
        }
      }
    } catch (e) {
      print('❌ Error sending announcement: $e');
    }
  }

  /// Send announcement filtered by department and/or level
  Future<bool> sendFilteredAnnouncement(
    String title,
    String body, {
    String? department,
    String? level,
  }) async {
    try {
      print(
        '📱 Sending filtered announcement (department: $department, level: $level)',
      );

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
        print(
          '⚠️ No users found matching criteria (department: $department, level: $level)',
        );
        return false;
      }

      final tokens =
          usersSnapshot.docs
              .map((doc) => doc.data()['fcmToken'] as String?)
              .where((token) => token != null && token.isNotEmpty)
              .cast<String>()
              .toList();

      if (tokens.isEmpty) {
        print('⚠️ No valid tokens found');
        return false;
      }

      print('📤 Sending to ${tokens.length} users...');

      // Use batch notification sending for better error handling
      final results = await _notificationService.sendBatchNotifications(
        tokens: tokens,
        title: title,
        body: body,
        data: {
          'type': 'announcement',
          if (department != null) 'department': department,
          if (level != null) 'level': level,
        },
      );

      final successCount = results['successCount'] as int;
      final failureCount = results['failureCount'] as int;

      print('✅ Sent: $successCount, ❌ Failed: $failureCount');

      return successCount > 0;
    } catch (e) {
      print('❌ Error sending filtered announcement: $e');
      return false;
    }
  }

  /// Send notification to users in specific department
  Future<bool> sendDepartmentNotification(
    String department,
    String title,
    String body, {
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async {
    try {
      print('📱 Sending department notification to: $department');

      // Get all users in the department with active FCM tokens
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('department', isEqualTo: department)
              .where('fcmToken', isNotEqualTo: null)
              .where('tokenStatus', isEqualTo: 'active')
              .get();

      if (usersSnapshot.docs.isEmpty) {
        print('⚠️ No users found in department: $department');
        return false;
      }

      final tokens =
          usersSnapshot.docs
              .map((doc) => doc.data()['fcmToken'] as String)
              .where((token) => token.isNotEmpty)
              .toList();

      if (tokens.isEmpty) {
        print('⚠️ No valid tokens found');
        return false;
      }

      print('📤 Sending to ${tokens.length} users...');

      // Use batch notification sending for better error handling
      final results = await _notificationService.sendBatchNotifications(
        tokens: tokens,
        title: title,
        body: body,
        data: {'type': 'department', 'department': department, ...?data},
        icon: icon,
        color: color,
        sound: sound,
        imageUrl: imageUrl,
      );

      final successCount = results['successCount'] as int;
      final failureCount = results['failureCount'] as int;
      final invalidTokens = results['invalidTokens'] as List<String>;

      print('✅ Sent: $successCount, ❌ Failed: $failureCount');

      if (invalidTokens.isNotEmpty) {
        print('⚠️ Invalid tokens: ${invalidTokens.length}');
      }

      return successCount > 0;
    } catch (e) {
      print('❌ Error sending department notification: $e');
      return false;
    }
  }

  /// Send notification to users in specific level
  Future<void> sendLevelNotification(
    String level,
    String title,
    String body,
  ) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('level', isEqualTo: level)
              .get();

      final userIds = querySnapshot.docs.map((doc) => doc.id).toList();
      final tokens = await _notificationService.getMultipleUserFCMTokens(
        userIds,
      );

      for (String token in tokens) {
        await _notificationService.sendNotification(
          targetToken: token,
          userId: userIds[tokens.indexOf(token)],
          title: title,
          body: body,
          data: {'type': 'level', 'level': level},
        );
      }
    } catch (e) {
      print('❌ Error sending level notification: $e');
    }
  }

  /// Send notification to multiple specific users by IDs
  Future<bool> sendMultiUserNotification(
    List<String> userIds,
    String title,
    String body, {
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async {
    try {
      print('📱 Sending notification to ${userIds.length} users...');

      // Get FCM tokens for the specified users
      final tokens = await _notificationService.getMultipleUserFCMTokens(
        userIds,
      );

      if (tokens.isEmpty) {
        print('⚠️ No valid tokens found');
        return false;
      }

      print('📤 Sending to ${tokens.length} tokens...');

      // Use batch notification sending
      final results = await _notificationService.sendBatchNotifications(
        tokens: tokens,
        title: title,
        body: body,
        data: data,
        icon: icon,
        color: color,
        sound: sound,
        imageUrl: imageUrl,
      );

      final successCount = results['successCount'] as int;
      final failureCount = results['failureCount'] as int;

      print('✅ Sent: $successCount, ❌ Failed: $failureCount');

      return successCount > 0;
    } catch (e) {
      print('❌ Error sending multi-user notification: $e');
      return false;
    }
  }

  /// Send notification to all users (global broadcast)
  Future<bool> sendGlobalNotification(
    String title,
    String body, {
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async {
    try {
      print('📱 Sending global notification to all users...');

      // Get all active FCM tokens
      final tokens = await _notificationService.getAllUserFCMTokens();

      if (tokens.isEmpty) {
        print('⚠️ No active tokens found');
        return false;
      }

      print('📤 Broadcasting to ${tokens.length} users...');

      // Use batch notification sending
      final results = await _notificationService.sendBatchNotifications(
        tokens: tokens,
        title: title,
        body: body,
        data: data,
        icon: icon,
        color: color,
        sound: sound,
        imageUrl: imageUrl,
      );

      final successCount = results['successCount'] as int;
      final failureCount = results['failureCount'] as int;
      final invalidTokens = results['invalidTokens'] as List<String>;

      print('✅ Sent: $successCount, ❌ Failed: $failureCount');

      if (invalidTokens.isNotEmpty) {
        print('⚠️ Invalid tokens: ${invalidTokens.length}');
      }

      return successCount > 0;
    } catch (e) {
      print('❌ Error sending global notification: $e');
      return false;
    }
  }

  // ===== TOKEN MANAGEMENT =====

  /// Clean up invalid tokens (can be called periodically)
  Future<Map<String, dynamic>> cleanupInvalidTokens() async {
    final results = await _notificationService.cleanupInvalidTokens();
    return results;
  }

  /// Get token statistics
  Future<Map<String, dynamic>> getTokenStatistics() async {
    final stats = await _notificationService.getTokenStatistics();
    return stats;
  }

  /// Refresh current user's token
  Future<bool> refreshCurrentUserToken() async {
    final success = await _notificationService.refreshCurrentUserToken();
    if (success) {
      print('✅ Token refreshed successfully');
    } else {
      print('❌ Token refresh failed');
    }
    return success;
  }

  /// Request new token from specific user
  Future<bool> requestNewTokenFromUser(String userId) async {
    final success = await _notificationService.requestNewTokenFromUser(userId);
    if (success) {
      print('✅ Token refresh requested for user: $userId');
    } else {
      print('❌ Token refresh request failed for user: $userId');
    }
    return success;
  }
}
