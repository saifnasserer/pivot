import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:pivot/services/fcm_token_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/services/local_notification_service.dart';
import 'package:pivot/services/notification_controller.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background FCM message received: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');

  // Show local notification when FCM arrives in background
  // This ensures user sees the notification even when app is closed
  try {
    await LocalNotificationService.instance.sendImmediateNotification(
      title:
          message.notification?.title ?? message.data['title'] ?? 'إشعار جديد',
      body: message.notification?.body ?? message.data['body'] ?? '',
      payload: message.data.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  } catch (e) {
    print('❌ Error showing background notification: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // TODO: move to Remote Config or env if needed
  static const String _functionUrl =
      'https://us-central1-pivot-28563.cloudfunctions.net/send_notification';

  Future<void> initialize([BuildContext? context]) async {
    // Request permissions (no-op on Android < 13, prompts on iOS and Android 13 for post notifications)
    await requestPermissionsExplicitly();

    // Set up token refresh listener BEFORE getting initial token
    _setupTokenRefreshListener();

    // Save initial token
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      await saveTokenToFirestore(token);
    } else {}

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Show local notification for foreground messages
      if (message.notification != null) {
        _showForegroundNotification(message);
      }
    });

    // Handle notification taps when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        print(
          '🔔 App opened from terminated state via notification: ${message.messageId}',
        );
        // Handle the notification tap
        NotificationController.handleFCMNotificationTap(message.data);
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
        '🔔 App opened from background via notification: ${message.messageId}',
      );
      // Handle the notification tap
      NotificationController.handleFCMNotificationTap(message.data);
    });
  }

  void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) async {
      try {
        await saveTokenToFirestore(newToken);
      } catch (e) {
        print('Error refreshing FCM token: $e');
      }
    });
  }

  void _showForegroundNotification(RemoteMessage message) {
    // Since FCM notifications don't show automatically when app is in foreground,
    // show a local notification instead
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      LocalNotificationService.instance.sendImmediateNotification(
        title: notification.title ?? 'إشعار جديد',
        body: notification.body ?? '',
        payload: data.map((key, value) => MapEntry(key, value.toString())),
      );
    } else if (data.isNotEmpty) {
      // If no notification payload but has data, create notification from data
      LocalNotificationService.instance.sendImmediateNotification(
        title: data['title'] ?? 'إشعار جديد',
        body: data['body'] ?? data['message'] ?? '',
        payload: data.map((key, value) => MapEntry(key, value.toString())),
      );
    }
  }

  Future<bool> requestPermissionsExplicitly() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
    } else {}

    return granted;
  }

  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'tokenStatus': 'active', // Track token status
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving FCM token to Firestore: $e');
    }
  }

  Future<String?> getUserFCMToken(String userId) async {
    return await FCMTokenManager().getUserToken(userId);
  }

  Future<List<String>> getAllUserFCMTokens() async {
    return await FCMTokenManager().getAllActiveTokens();
  }

  Future<List<String>> getMultipleUserFCMTokens(List<String> userIds) async {
    return await FCMTokenManager().getMultipleUserTokens(userIds);
  }

  // Handle invalid token by marking it as inactive
  Future<void> _handleInvalidToken(String token, String? userId) async {
    await FCMTokenManager().markTokenAsInvalid(token, userId);
  }

  // Enhanced token validation with better error handling
  Future<bool> _validateToken(String token) async {
    return await FCMTokenManager().validateTokenWithFirebase(token);
  }

  // Enhanced send notification with better error handling
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
    try {
      // Validate token format before sending
      if (!_isValidTokenFormat(targetToken)) {
        await _handleInvalidToken(targetToken, userId);
        return false;
      }

      final payload = {
        'token': targetToken,
        'title': title,
        'body': body,
        'data': data ?? {},
        'icon': icon ?? 'ic_notification',
        'color': color ?? '#000000',
        'sound': sound ?? 'default',
      };

      final resp = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        return true;
      } else if (resp.statusCode == 400) {
        // Handle invalid token error
        final responseBody = jsonDecode(resp.body);
        final error = responseBody['error']?.toString() ?? '';

        if (error.contains('Invalid or unregistered token') ||
            error.contains('Invalid argument')) {
          await _handleInvalidToken(targetToken, userId);
        } else {}
        return false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Validate token format
  bool _isValidTokenFormat(String token) {
    return FCMTokenManager().isValidTokenFormat(token);
  }

  // Clean up invalid/expired FCM tokens - OPTIMIZED with batch operations
  Future<Map<String, dynamic>> cleanupInvalidTokens() async {
    final results = {
      'totalUsers': 0,
      'cleanedTokens': 0,
      'errors': <String>[],
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Get users with FCM tokens in batches to reduce reads
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('fcmToken', isNotEqualTo: null)
              .limit(50) // Process in smaller batches
              .get();

      results['totalUsers'] = usersSnapshot.docs.length;
      final batch = _firestore.batch();
      int batchCount = 0;
      const int maxBatchSize = 20;

      for (final userDoc in usersSnapshot.docs) {
        try {
          final userData = userDoc.data();
          final token = userData['fcmToken'] as String?;
          final lastUpdate = userData['lastTokenUpdate'] as Timestamp?;

          if (token == null || token.isEmpty) {
            continue;
          }

          // Check if token is older than 60 days (FCM tokens refresh periodically)
          final isOldToken =
              lastUpdate == null ||
              DateTime.now().difference(lastUpdate.toDate()).inDays > 60;

          // Only validate token if it's not obviously old
          bool isValidToken = true;
          if (!isOldToken) {
            isValidToken = await _validateToken(token);
          }

          if (!isValidToken || isOldToken) {
            // Mark token as invalid using batch operation
            batch.update(userDoc.reference, {
              'fcmToken': FieldValue.delete(),
              'tokenStatus': 'invalid',
              'lastTokenError': FieldValue.serverTimestamp(),
            });
            results['cleanedTokens'] = (results['cleanedTokens'] as int) + 1;
            batchCount++;

            // Commit batch when it reaches the limit
            if (batchCount >= maxBatchSize) {
              await batch.commit();
              batchCount = 0;
            }
          }
        } catch (e) {
          (results['errors'] as List<String>).add('User ${userDoc.id}: $e');
        }
      }

      // Commit remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      (results['errors'] as List<String>).add('General error: $e');
    }

    return results;
  }

  // Get FCM token statistics
  Future<Map<String, dynamic>> getTokenStatistics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final usersWithActiveTokens =
          await _firestore
              .collection('users')
              .where('fcmToken', isNotEqualTo: null)
              .where('tokenStatus', isEqualTo: 'active')
              .get();

      final usersWithInvalidTokens =
          await _firestore
              .collection('users')
              .where('tokenStatus', isEqualTo: 'invalid')
              .get();

      final now = DateTime.now();
      int recentTokens = 0;
      int oldTokens = 0;

      for (final doc in usersWithActiveTokens.docs) {
        final lastUpdate = doc.data()['lastTokenUpdate'] as Timestamp?;
        if (lastUpdate != null) {
          final daysSinceUpdate = now.difference(lastUpdate.toDate()).inDays;
          if (daysSinceUpdate <= 30) {
            recentTokens++;
          } else {
            oldTokens++;
          }
        } else {
          oldTokens++;
        }
      }

      return {
        'totalUsers': usersSnapshot.docs.length,
        'usersWithActiveTokens': usersWithActiveTokens.docs.length,
        'usersWithInvalidTokens': usersWithInvalidTokens.docs.length,
        'usersWithoutTokens':
            usersSnapshot.docs.length - usersWithActiveTokens.docs.length,
        'recentTokens': recentTokens, // Updated within 30 days
        'oldTokens': oldTokens, // Older than 30 days or no update date
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Force refresh current user's token
  Future<bool> refreshCurrentUserToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Delete current token to force refresh
      await _messaging.deleteToken();

      // Get new token
      final newToken = await _messaging.getToken();
      if (newToken == null) {
        return false;
      }

      // Save new token
      await saveTokenToFirestore(newToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Request new token from user (for manual refresh)
  Future<bool> requestNewTokenFromUser(String userId) async {
    try {
      // Mark current token as invalid to force refresh
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'tokenStatus': 'pending_refresh',
        'lastTokenError': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Batch send notifications with automatic invalid token handling
  Future<Map<String, dynamic>> sendBatchNotifications({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async {
    final results = {
      'totalTokens': tokens.length,
      'successCount': 0,
      'failureCount': 0,
      'invalidTokens': <String>[],
      'errors': <String>[],
    };

    for (final token in tokens) {
      try {
        final success = await sendNotification(
          targetToken: token,
          title: title,
          body: body,
          data: data,
          icon: icon,
          color: color,
          sound: sound,
          imageUrl: imageUrl,
        );

        if (success) {
          results['successCount'] = (results['successCount'] as int) + 1;
        } else {
          results['failureCount'] = (results['failureCount'] as int) + 1;
          (results['invalidTokens'] as List<String>).add(token);
        }
      } catch (e) {
        results['failureCount'] = (results['failureCount'] as int) + 1;
        (results['errors'] as List<String>).add('Token $token: $e');
      }
    }

    return results;
  }
}
