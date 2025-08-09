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

    // Save initial token
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      await saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      await saveTokenToFirestore(newToken);
    });
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
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
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
      }, SetOptions(merge: true));
    } catch (_) {
      // ignore
    }
  }

  Future<String?> getUserFCMToken(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return data['fcmToken'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> getAllUserFCMTokens() async {
    try {
      final query =
          await _firestore
              .collection('users')
              .where('fcmToken', isGreaterThan: '')
              .get();
      return query.docs
          .map((d) => (d.data()['fcmToken'] as String?) ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (_) {
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
        if (token != null && token.isNotEmpty) tokens.add(token);
      }
    } catch (_) {
      // ignore errors, return what we have
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
      final resp = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
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

          // Try to validate token by sending a test message (dry run)
          final isValidToken = await _validateToken(token);

          if (!isValidToken || isOldToken) {
            // Remove invalid/old token
            await _firestore.collection('users').doc(userDoc.id).update({
              'fcmToken': FieldValue.delete(),
              'lastTokenUpdate': FieldValue.delete(),
            });
            results['cleanedTokens'] = (results['cleanedTokens'] as int) + 1;
          }
        } catch (e) {
          (results['errors'] as List<String>).add('User ${userDoc.id}: $e');
        }
      }
    } catch (e) {
      (results['errors'] as List<String>).add('General error: $e');
    }

    return results;
  }

  // Validate if a token is still valid by testing it (without actually sending)
  Future<bool> _validateToken(String token) async {
    try {
      // Send a dry-run test to validate token
      final payload = {
        'token': token,
        'title': 'Token Validation',
        'body': 'This is a validation test',
        'dry_run': true, // This tells the server to validate but not send
      };

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get FCM token statistics
  Future<Map<String, dynamic>> getTokenStatistics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final usersWithTokens =
          await _firestore
              .collection('users')
              .where('fcmToken', isNotEqualTo: null)
              .get();

      final now = DateTime.now();
      int recentTokens = 0;
      int oldTokens = 0;

      for (final doc in usersWithTokens.docs) {
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
        'usersWithTokens': usersWithTokens.docs.length,
        'usersWithoutTokens':
            usersSnapshot.docs.length - usersWithTokens.docs.length,
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
      if (newToken == null) return false;

      // Save new token
      await saveTokenToFirestore(newToken);
      return true;
    } catch (e) {
      return false;
    }
  }
}
