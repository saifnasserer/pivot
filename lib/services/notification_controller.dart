import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

/// Controller for handling notification actions and navigation
/// This handles both local notifications (AwesomeNotifications) and FCM notifications
class NotificationController {
  // Global navigation key to navigate without context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Handle notification tap/action
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    print('🔔 Notification tapped: ${receivedAction.payload}');

    final payload = receivedAction.payload ?? {};
    final type = payload['type'] ?? '';

    // Wait a bit to ensure app is fully initialized
    await Future.delayed(const Duration(milliseconds: 500));

    // Navigate based on notification type
    switch (type) {
      case 'task_reminder':
      case 'new_task':
        _navigateToTasks();
        break;

      case 'class_reminder':
      case 'class_reminder_immediate':
        _navigateToSchedule();
        break;

      case 'announcement':
        _navigateToAnnouncements();
        break;

      case 'test_notification':
      case 'immediate_notification':
        // Just open the app, no specific navigation
        print('Test notification tapped - no navigation');
        break;

      default:
        print('Unknown notification type: $type');
        // Navigate to home/landing as fallback
        _navigateToHome();
    }
  }

  /// Called when notification is created (optional)
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    print('📬 Notification created: ${receivedNotification.title}');
  }

  /// Called when notification is displayed (optional)
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    print('📱 Notification displayed: ${receivedNotification.title}');
  }

  /// Called when notification is dismissed (optional)
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    print('🗑️ Notification dismissed: ${receivedAction.id}');
  }

  // Navigation helper methods
  static void _navigateToTasks() {
    try {
      navigatorKey.currentState?.pushNamed('/tasks-control');
    } catch (e) {
      print('Error navigating to tasks: $e');
    }
  }

  static void _navigateToSchedule() {
    try {
      // Navigate to landing page with schedule tab selected
      // The landing page should handle showing the schedule
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/landing',
        (route) => false,
      );
    } catch (e) {
      print('Error navigating to schedule: $e');
    }
  }

  static void _navigateToAnnouncements() {
    try {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/landing',
        (route) => false,
      );
    } catch (e) {
      print('Error navigating to announcements: $e');
    }
  }

  static void _navigateToHome() {
    try {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/landing',
        (route) => false,
      );
    } catch (e) {
      print('Error navigating to home: $e');
    }
  }

  /// Initialize notification listeners
  static Future<void> initialize() async {
    print('🔔 Initializing notification listeners...');

    try {
      // Set up listeners for AwesomeNotifications
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod,
      );

      print('✅ Notification listeners initialized');
    } catch (e) {
      print('❌ Error initializing notification listeners: $e');
      rethrow;
    }
  }

  /// Handle FCM notification tap (for RemoteMessage)
  static void handleFCMNotificationTap(Map<String, dynamic> data) {
    print('🔔 FCM Notification tapped: $data');

    final type = data['type'] ?? '';

    // Navigate based on notification type
    switch (type) {
      case 'task_reminder':
      case 'new_task':
        _navigateToTasks();
        break;

      case 'class_reminder':
        _navigateToSchedule();
        break;

      case 'announcement':
        _navigateToAnnouncements();
        break;

      default:
        print('Unknown FCM notification type: $type');
        _navigateToHome();
    }
  }
}
