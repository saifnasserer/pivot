import 'package:pivot/features/notifications/services/notifications_service.dart';
import 'package:pivot/models/scheduled_notification.dart';
import 'package:pivot/models/user_notification.dart';

class NotificationsRepository {
  final NotificationsService _notificationsService;

  NotificationsRepository(this._notificationsService);

  // Initialize notification services
  Future<void> initialize() async {
    return await _notificationsService.initialize();
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
    return await _notificationsService.sendNotification(
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
    return await _notificationsService.sendMultipleNotifications(
      userIds: userIds,
      title: title,
      body: body,
      data: data,
      icon: icon,
      color: color,
      sound: sound,
      imageUrl: imageUrl,
    );
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
    return await _notificationsService.sendNotificationToAllUsers(
      title: title,
      body: body,
      data: data,
      icon: icon,
      color: color,
      sound: sound,
      imageUrl: imageUrl,
    );
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
    return await _notificationsService.sendFilteredNotification(
      title: title,
      body: body,
      department: department,
      level: level,
      data: data,
      icon: icon,
      color: color,
      sound: sound,
      imageUrl: imageUrl,
    );
  }

  // Create scheduled notification
  Future<bool> createScheduledNotification(
    ScheduledNotification notification,
  ) async {
    return await _notificationsService.createScheduledNotification(
      notification,
    );
  }

  // Get scheduled notifications
  Future<List<ScheduledNotification>> getScheduledNotifications() async {
    return await _notificationsService.getScheduledNotifications();
  }

  // Get pending scheduled notifications
  Future<List<ScheduledNotification>> getPendingScheduledNotifications() async {
    return await _notificationsService.getPendingScheduledNotifications();
  }

  // Execute scheduled notification
  Future<bool> executeScheduledNotification(
    ScheduledNotification notification,
  ) async {
    return await _notificationsService.executeScheduledNotification(
      notification,
    );
  }

  // Delete scheduled notification
  Future<bool> deleteScheduledNotification(String notificationId) async {
    return await _notificationsService.deleteScheduledNotification(
      notificationId,
    );
  }

  // Get user notifications
  Future<List<UserNotification>> getUserNotifications(String userId) async {
    return await _notificationsService.getUserNotifications(userId);
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    return await _notificationsService.markNotificationAsRead(
      userId,
      notificationId,
    );
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    return await _notificationsService.getUnreadNotificationCount(userId);
  }

  // Test notification system
  Future<Map<String, dynamic>> testNotificationSystem() async {
    return await _notificationsService.testNotificationSystem();
  }

  // Get FCM token statistics
  Future<Map<String, dynamic>> getTokenStatistics() async {
    return await _notificationsService.getTokenStatistics();
  }

  // Cleanup invalid tokens
  Future<Map<String, dynamic>> cleanupInvalidTokens() async {
    return await _notificationsService.cleanupInvalidTokens();
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    return await _notificationsService.requestPermissions();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationsService.areNotificationsEnabled();
  }

  // Get current user's FCM token
  Future<String?> getCurrentUserToken() async {
    return await _notificationsService.getCurrentUserToken();
  }

  // Save token to Firestore
  Future<void> saveTokenToFirestore(String token) async {
    await _notificationsService.saveTokenToFirestore(token);
  }
}
