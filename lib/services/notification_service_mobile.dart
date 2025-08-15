import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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
      print('FCM Init: ✅ Token saved: ${token.substring(0, 20)}...');
    } else {
      print('FCM Init: ❌ No token available');
    }

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('FCM Foreground: 📱 Received message while app is in foreground');
      print('FCM Foreground: Title: ${message.notification?.title}');
      print('FCM Foreground: Body: ${message.notification?.body}');
      print('FCM Foreground: Data: ${message.data}');

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
        print('FCM Terminated: 📱 App launched from notification');
        print('FCM Terminated: Data: ${message.data}');
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('FCM Background: 📱 App opened from notification');
      print('FCM Background: Data: ${message.data}');
    });
  }

  void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) async {
      print('FCM Token Refresh: 🔄 Token refreshed, updating in Firestore...');
      try {
        await saveTokenToFirestore(newToken);
        print('FCM Token Refresh: ✅ New token saved successfully');
      } catch (e) {
        print('FCM Token Refresh: ❌ Failed to save new token: $e');
      }
    });
  }

  void _showForegroundNotification(RemoteMessage message) {
    // Since FCM notifications don't show automatically when app is in foreground,
    // we can show a local notification instead
    print('FCM Foreground: 🔔 Would show local notification here');
    // TODO: Integrate with LocalNotificationService to show the notification
  }

  Future<bool> requestPermissionsExplicitly() async {
    print('FCM Permissions: Requesting notification permissions...');

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print(
      'FCM Permissions: Authorization status: ${settings.authorizationStatus}',
    );
    print('FCM Permissions: Alert: ${settings.alert}');
    print('FCM Permissions: Badge: ${settings.badge}');
    print('FCM Permissions: Sound: ${settings.sound}');

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
      print('FCM Permissions: ✅ Permissions granted');
    } else {
      print('FCM Permissions: ❌ Permissions denied');
    }

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
      print('FCM Token Save: ✅ Token saved for user ${user.uid}');
    } catch (e) {
      print('FCM Token Save: ❌ Failed to save token: $e');
    }
  }

  Future<String?> getUserFCMToken(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;

      final token = data['fcmToken'] as String?;
      final status = data['tokenStatus'] as String?;

      // Only return token if it's marked as active
      if (token != null && token.isNotEmpty && status == 'active') {
        return token;
      }
      return null;
    } catch (e) {
      print('FCM Get Token: ❌ Error getting token for user $userId: $e');
      return null;
    }
  }

  Future<List<String>> getAllUserFCMTokens() async {
    try {
      final query =
          await _firestore
              .collection('users')
              .where('fcmToken', isGreaterThan: '')
              .where('tokenStatus', isEqualTo: 'active')
              .get();

      final tokens =
          query.docs
              .map((d) => (d.data()['fcmToken'] as String?) ?? '')
              .where((t) => t.isNotEmpty)
              .toList();

      print('FCM Get All Tokens: ✅ Found ${tokens.length} active tokens');
      return tokens;
    } catch (e) {
      print('FCM Get All Tokens: ❌ Error getting tokens: $e');
      return <String>[];
    }
  }

  Future<List<String>> getMultipleUserFCMTokens(List<String> userIds) async {
    final List<String> tokens = [];
    try {
      final futures = userIds.map(
        (id) => _firestore.collection('users').doc(id).get(),
      );
      final docs = await Future.wait(futures);
      for (final doc in docs) {
        if (!doc.exists) continue;
        final data = doc.data();
        final token = data?['fcmToken'] as String?;
        final status = data?['tokenStatus'] as String?;

        // Only include active tokens
        if (token != null && token.isNotEmpty && status == 'active') {
          tokens.add(token);
        }
      }
      print(
        'FCM Get Multiple Tokens: ✅ Found ${tokens.length} active tokens for ${userIds.length} users',
      );
    } catch (e) {
      print('FCM Get Multiple Tokens: ❌ Error getting tokens: $e');
    }
    return tokens;
  }

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
      final payload = <String, dynamic>{
        'token': targetToken,
        'title': title,
        'body': body,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        if (sound != null) 'sound': sound,
        if (imageUrl != null) 'image': imageUrl,
        if (data != null) 'data': data,
      };

      print('FCM: Sending notification to function: $_functionUrl');
      print('FCM: Payload: ${jsonEncode(payload)}');

      final resp = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      print('FCM: Response status: ${resp.statusCode}');
      print('FCM: Response body: ${resp.body}');

      if (resp.statusCode == 200) {
        print('FCM: ✅ Notification sent successfully');
        return true;
      } else if (resp.statusCode == 400) {
        // Handle invalid token error
        final responseBody = jsonDecode(resp.body);
        if (responseBody['error']?.toString().contains(
              'Invalid or unregistered token',
            ) ==
            true) {
          print('FCM: ❌ Invalid token detected: $targetToken');
          await _handleInvalidToken(targetToken, userId);
        }
        return false;
      } else {
        print('FCM: ❌ Notification failed with status: ${resp.statusCode}');
        return false;
      }
    } catch (e) {
      print('FCM: ❌ Exception occurred: $e');
      return false;
    }
  }

  // Handle invalid token by marking it as inactive
  Future<void> _handleInvalidToken(String token, String? userId) async {
    try {
      if (userId != null) {
        // If we know the user ID, mark their token as invalid
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': FieldValue.delete(),
          'tokenStatus': 'invalid',
          'lastTokenError': FieldValue.serverTimestamp(),
        });
        print('FCM Invalid Token: ✅ Marked token as invalid for user $userId');
      } else {
        // Find user by token and mark as invalid
        final query =
            await _firestore
                .collection('users')
                .where('fcmToken', isEqualTo: token)
                .get();

        for (final doc in query.docs) {
          await _firestore.collection('users').doc(doc.id).update({
            'fcmToken': FieldValue.delete(),
            'tokenStatus': 'invalid',
            'lastTokenError': FieldValue.serverTimestamp(),
          });
          print(
            'FCM Invalid Token: ✅ Marked token as invalid for user ${doc.id}',
          );
        }
      }
    } catch (e) {
      print('FCM Invalid Token: ❌ Error handling invalid token: $e');
    }
  }

  // Clean up invalid/expired FCM tokens
  Future<Map<String, dynamic>> cleanupInvalidTokens() async {
    final results = {
      'totalUsers': 0,
      'cleanedTokens': 0,
      'errors': <String>[],
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Get all users with FCM tokens
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('fcmToken', isNotEqualTo: null)
              .get();

      results['totalUsers'] = usersSnapshot.docs.length;

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

          // Try to validate token by sending a test message
          final isValidToken = await _validateToken(token);

          if (!isValidToken || isOldToken) {
            // Mark token as invalid
            await _firestore.collection('users').doc(userDoc.id).update({
              'fcmToken': FieldValue.delete(),
              'tokenStatus': 'invalid',
              'lastTokenError': FieldValue.serverTimestamp(),
            });
            results['cleanedTokens'] = (results['cleanedTokens'] as int) + 1;
            print(
              'FCM Cleanup: ✅ Cleaned invalid token for user ${userDoc.id}',
            );
          }
        } catch (e) {
          (results['errors'] as List<String>).add('User ${userDoc.id}: $e');
        }
      }
    } catch (e) {
      (results['errors'] as List<String>).add('General error: $e');
    }

    print(
      'FCM Cleanup: ✅ Cleanup completed. Cleaned ${results['cleanedTokens']} tokens',
    );
    return results;
  }

  // Validate if a token is still valid by testing it
  Future<bool> _validateToken(String token) async {
    try {
      // Send a test notification to validate token
      final payload = {
        'token': token,
        'title': 'Token Validation',
        'body': 'This is a validation test',
        'data': {'validation': 'true'},
      };

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      final isValid = response.statusCode == 200;
      if (!isValid) {
        print(
          'FCM Token Validation: ❌ Token validation failed for token: ${token.substring(0, 20)}...',
        );
      }
      return isValid;
    } catch (e) {
      print('FCM Token Validation: ❌ Error validating token: $e');
      return false;
    }
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

      print('FCM Token Refresh: 🔄 Forcing token refresh for user ${user.uid}');

      // Delete current token to force refresh
      await _messaging.deleteToken();

      // Get new token
      final newToken = await _messaging.getToken();
      if (newToken == null) {
        print('FCM Token Refresh: ❌ Failed to get new token');
        return false;
      }

      // Save new token
      await saveTokenToFirestore(newToken);
      print('FCM Token Refresh: ✅ Token refreshed successfully');
      return true;
    } catch (e) {
      print('FCM Token Refresh: ❌ Error refreshing token: $e');
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

      print('FCM Manual Refresh: ✅ Requested new token for user $userId');
      return true;
    } catch (e) {
      print('FCM Manual Refresh: ❌ Error requesting new token: $e');
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

    print(
      'FCM Batch Send: ✅ Completed. Success: ${results['successCount']}, Failed: ${results['failureCount']}',
    );
    return results;
  }
}
