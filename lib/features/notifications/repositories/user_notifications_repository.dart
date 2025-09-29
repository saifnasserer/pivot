import 'package:pivot/features/notifications/services/user_notifications_service.dart';
import 'package:pivot/models/scheduled_notification.dart';

class UserNotificationsRepository {
  final UserNotificationsService _userNotificationsService;

  UserNotificationsRepository(this._userNotificationsService);

  // Get user notifications
  Future<List<ScheduledNotification>> getUserNotifications({
    int limit = 50,
  }) async {
    return await _userNotificationsService.getUserNotifications(limit: limit);
  }

  // Get unread notifications
  Future<List<ScheduledNotification>> getUnreadNotifications() async {
    return await _userNotificationsService.getUnreadNotifications();
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    return await _userNotificationsService.markNotificationAsRead(
      notificationId,
    );
  }

  // Mark multiple notifications as read
  Future<bool> markMultipleNotificationsAsRead(
    List<String> notificationIds,
  ) async {
    return await _userNotificationsService.markMultipleNotificationsAsRead(
      notificationIds,
    );
  }

  // Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    return await _userNotificationsService.markAllNotificationsAsRead();
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    return await _userNotificationsService.deleteNotification(notificationId);
  }

  // Delete multiple notifications
  Future<bool> deleteMultipleNotifications(List<String> notificationIds) async {
    return await _userNotificationsService.deleteMultipleNotifications(
      notificationIds,
    );
  }

  // Get notification by ID
  Future<ScheduledNotification?> getNotificationById(
    String notificationId,
  ) async {
    return await _userNotificationsService.getNotificationById(notificationId);
  }

  // Search notifications
  Future<List<ScheduledNotification>> searchNotifications(String query) async {
    return await _userNotificationsService.searchNotifications(query);
  }

  // Get notifications by type
  Future<List<ScheduledNotification>> getNotificationsByType(
    String type,
  ) async {
    return await _userNotificationsService.getNotificationsByType(type);
  }

  // Get notifications by date range
  Future<List<ScheduledNotification>> getNotificationsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _userNotificationsService.getNotificationsByDateRange(
      startDate,
      endDate,
    );
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStatistics() async {
    return await _userNotificationsService.getNotificationStatistics();
  }

  // Get recent notifications
  Future<List<ScheduledNotification>> getRecentNotifications({
    int limit = 10,
  }) async {
    return await _userNotificationsService.getRecentNotifications(limit: limit);
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
    return await _userNotificationsService.createNotification(
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      targetUserIds: targetUserIds,
      sendToAllUsers: sendToAllUsers,
      department: department,
      level: level,
      additionalData: additionalData,
    );
  }

  // Update notification preferences
  Future<bool> updateNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    return await _userNotificationsService.updateNotificationPreferences(
      preferences,
    );
  }

  // Get notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    return await _userNotificationsService.getNotificationPreferences();
  }
}
