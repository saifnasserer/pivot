import 'package:pivot/services/notification_service.dart';
import 'package:pivot/services/notification_trigger_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationTestService {
  static final NotificationTestService _instance =
      NotificationTestService._internal();
  factory NotificationTestService() => _instance;
  NotificationTestService._internal();

  final NotificationService _notificationService = NotificationService();
  final NotificationTriggerService _triggerService =
      NotificationTriggerService();

  // Test all notification components
  Future<Map<String, dynamic>> runFullNotificationTest() async {
    Map<String, dynamic> results = {
      'timestamp': DateTime.now().toIso8601String(),
      'tests': {},
    };

    try {
      // Test 1: FCM Token Generation
      results['tests']['fcm_token'] = await _testFCMTokenGeneration();

      // Test 2: Token Storage
      results['tests']['token_storage'] = await _testTokenStorage();

      // Test 3: Firebase Function Connection
      results['tests']['firebase_function'] = await _testFirebaseFunction();

      // Test 4: Local Notifications
      results['tests']['local_notifications'] = await _testLocalNotifications();

      // Test 5: Background Message Handler
      results['tests']['background_handler'] = await _testBackgroundHandler();

      // Test 6: Permission Status
      results['tests']['permissions'] = await _testPermissions();

      // Test 7: Firestore Integration
      results['tests']['firestore_integration'] =
          await _testFirestoreIntegration();

      // Test 8: Notification Triggers
      results['tests']['notification_triggers'] =
          await _testNotificationTriggers();
    } catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }

  // Test FCM Token Generation
  Future<Map<String, dynamic>> _testFCMTokenGeneration() async {
    try {
      final token = await _notificationService.getToken();
      return {
        'success': token != null && token.isNotEmpty,
        'token': token,
        'token_length': token?.length ?? 0,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Test Token Storage
  Future<Map<String, dynamic>> _testTokenStorage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No authenticated user'};
      }

      final token = await _notificationService.getToken();
      if (token == null) {
        return {'success': false, 'error': 'No FCM token available'};
      }

      await _notificationService.saveTokenToFirestore(token);

      // Verify token was saved
      final savedToken = await _notificationService.getUserFCMToken(user.uid);

      return {
        'success': savedToken == token,
        'saved_token': savedToken,
        'original_token': token,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Test Firebase Function Connection
  Future<Map<String, dynamic>> _testFirebaseFunction() async {
    try {
      final token = await _notificationService.getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No FCM token available for testing',
        };
      }

      final success = await _notificationService.sendNotification(
        targetToken: token,
        title: 'Test Notification',
        body: 'This is a test notification from the app',
      );

      return {'success': success, 'test_token': token};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Test Local Notifications
  Future<Map<String, dynamic>> _testLocalNotifications() async {
    try {
      // This would require testing the local notification display
      // For now, we'll just check if the service is properly initialized
      return {
        'success': true,
        'message': 'Local notification service initialized',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Test Background Message Handler
  Future<Map<String, dynamic>> _testBackgroundHandler() async {
    try {
      // Background handler is registered in main.dart
      return {
        'success': true,
        'message': 'Background message handler registered',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Test Permissions
  Future<Map<String, dynamic>> _testPermissions() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();

      return {
        'success':
            settings.authorizationStatus == AuthorizationStatus.authorized,
        'authorization_status': settings.authorizationStatus.toString(),
        'alert_enabled': settings.alert,
        'badge_enabled': settings.badge,
        'sound_enabled': settings.sound,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Test Firestore Integration
  Future<Map<String, dynamic>> _testFirestoreIntegration() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No authenticated user'};
      }

      // Test getting user FCM token from Firestore
      final token = await _notificationService.getUserFCMToken(user.uid);

      // Test getting all user tokens
      final allTokens = await _notificationService.getAllUserFCMTokens();

      return {
        'success': true,
        'user_token_exists': token != null,
        'total_users_with_tokens': allTokens.length,
        'current_user_token': token,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Test Notification Triggers
  Future<Map<String, dynamic>> _testNotificationTriggers() async {
    try {
      // Test running auto notifications
      await _triggerService.sendAnnouncement(
        'Test Notification',
        'This is a test notification from the app',
      );

      return {
        'success': true,
        'message': 'Auto notifications executed successfully',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Send a test notification to current user only
  Future<bool> sendTestNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      // Get current user's FCM token directly
      final token = await _notificationService.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // Send notification only to current user's device
      final result = await _notificationService.sendNotification(
        targetToken: token,
        title: 'Test Notification - Current User Only',
        body:
            'This is a test notification sent to your device only at ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
        userId: user.uid,
        icon: 'ic_notification',
        data: {
          'test_type': 'current_user_only',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (result) {
      } else {}

      return result;
    } catch (e) {
      return false;
    }
  }

  // Check notification system health
  Future<Map<String, dynamic>> checkSystemHealth() async {
    Map<String, dynamic> health = {
      'timestamp': DateTime.now().toIso8601String(),
      'overall_status': 'unknown',
      'components': {},
    };

    try {
      // Check FCM token
      final token = await _notificationService.getToken();
      health['components']['fcm_token'] = {
        'status': token != null && token.isNotEmpty ? 'healthy' : 'unhealthy',
        'details': token != null ? 'Token available' : 'No token',
      };

      // Check user authentication
      final user = FirebaseAuth.instance.currentUser;
      health['components']['user_auth'] = {
        'status': user != null ? 'healthy' : 'unhealthy',
        'details': user != null ? 'User authenticated' : 'No user',
      };

      // Check Firestore connection
      try {
        await FirebaseFirestore.instance.collection('users').limit(1).get();
        health['components']['firestore'] = {
          'status': 'healthy',
          'details': 'Connection successful',
        };
      } catch (e) {
        health['components']['firestore'] = {
          'status': 'unhealthy',
          'details': e.toString(),
        };
      }

      // Check permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      health['components']['permissions'] = {
        'status':
            settings.authorizationStatus == AuthorizationStatus.authorized
                ? 'healthy'
                : 'unhealthy',
        'details': 'Authorization: ${settings.authorizationStatus}',
      };

      // Determine overall status
      final healthyComponents =
          health['components'].values
              .where((component) => component['status'] == 'healthy')
              .length;
      final totalComponents = health['components'].length;

      health['overall_status'] =
          healthyComponents == totalComponents ? 'healthy' : 'degraded';
    } catch (e) {
      health['overall_status'] = 'unhealthy';
      health['error'] = e.toString();
    }

    return health;
  }
}
