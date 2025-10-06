import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMTokenManager {
  static final FCMTokenManager _instance = FCMTokenManager._internal();
  factory FCMTokenManager() => _instance;
  FCMTokenManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // TODO: move to Remote Config or env if needed
  static const String _functionUrl =
      'https://us-central1-pivot-28563.cloudfunctions.net/send_notification';

  // Initialize token management
  Future<void> initialize() async {
    // Set up token refresh listener
    _messaging.onTokenRefresh.listen((newToken) async {
      await _updateUserToken(newToken);
    });

    // Get and save initial token
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _updateUserToken(token);
    }

    // Schedule periodic token cleanup
    _scheduleTokenCleanup();
  }

  // Update user's FCM token in Firestore
  Future<void> _updateUserToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'tokenStatus': 'active',
        'tokenErrorReason': FieldValue.delete(), // Clear any previous errors
      }, SetOptions(merge: true));
    } catch (e) {}
  }

  // Get user's FCM token
  Future<String?> getUserToken(String userId) async {
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
      return null;
    }
  }

  // Get all active FCM tokens
  Future<List<String>> getAllActiveTokens() async {
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

      return tokens;
    } catch (e) {
      return <String>[];
    }
  }

  // Get multiple user tokens
  Future<List<String>> getMultipleUserTokens(List<String> userIds) async {
    final List<String> tokens = [];

    try {
      final futures = userIds.map((id) => getUserToken(id));
      final results = await Future.wait(futures);

      for (final token in results) {
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      return tokens;
    } catch (e) {
      return tokens;
    }
  }

  // Mark token as invalid
  Future<void> markTokenAsInvalid(String token, String? userId) async {
    try {
      // Handle special case for "all_users" - find the actual user by token
      if (userId == 'all_users' || userId == null) {
        // Find user by token
        final query =
            await _firestore
                .collection('users')
                .where('fcmToken', isEqualTo: token)
                .get();

        if (query.docs.isEmpty) {
          return;
        }

        for (final doc in query.docs) {
          await _firestore.collection('users').doc(doc.id).update({
            'fcmToken': FieldValue.delete(),
            'tokenStatus': 'invalid',
            'lastTokenError': FieldValue.serverTimestamp(),
            'tokenErrorReason': 'Invalid or unregistered token',
          });
        }
      } else {
        // Regular user ID - try to update the specific user
        try {
          await _firestore.collection('users').doc(userId).update({
            'fcmToken': FieldValue.delete(),
            'tokenStatus': 'invalid',
            'lastTokenError': FieldValue.serverTimestamp(),
            'tokenErrorReason': 'Invalid or unregistered token',
          });
        } catch (e) {
          // If the specific user document doesn't exist, try to find by token
          final query =
              await _firestore
                  .collection('users')
                  .where('fcmToken', isEqualTo: token)
                  .get();

          if (query.docs.isNotEmpty) {
            for (final doc in query.docs) {
              await _firestore.collection('users').doc(doc.id).update({
                'fcmToken': FieldValue.delete(),
                'tokenStatus': 'invalid',
                'lastTokenError': FieldValue.serverTimestamp(),
                'tokenErrorReason': 'Invalid or unregistered token',
              });
            }
          } else {}
        }
      }
    } catch (e) {}
  }

  // Validate token format
  bool isValidTokenFormat(String token) {
    if (token.isEmpty) return false;

    // FCM tokens should be around 140-160 characters
    if (token.length < 100 || token.length > 200) return false;

    // Check if token contains valid characters
    final validPattern = RegExp(r'^[a-zA-Z0-9:_-]+$');
    if (!validPattern.hasMatch(token)) return false;

    return true;
  }

  // Validate token with Firebase
  Future<bool> validateTokenWithFirebase(String token) async {
    try {
      final payload = {
        'token': token,
        'title': 'Token Validation',
        'body': 'This is a validation test',
        'data': {'validation': 'true'},
      };

      final response = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 10));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 400) {
        final error = responseBody['error']?.toString() ?? '';
        if (error.contains('Invalid or unregistered token') ||
            error.contains('Invalid argument')) {
          return false;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Clean up invalid tokens
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
          final tokenStatus = userData['tokenStatus'] as String?;

          if (token == null || token.isEmpty) {
            continue;
          }

          // Skip tokens that are already marked as invalid
          if (tokenStatus == 'invalid') {
            continue;
          }

          // Check if token is older than 60 days
          final isOldToken =
              lastUpdate == null ||
              DateTime.now().difference(lastUpdate.toDate()).inDays > 60;

          // Validate token format
          final isValidFormat = isValidTokenFormat(token);

          if (!isValidFormat || isOldToken) {
            await markTokenAsInvalid(token, userDoc.id);
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

  // Schedule periodic token cleanup
  void _scheduleTokenCleanup() {
    // Run cleanup every 24 hours
    Future.delayed(const Duration(hours: 24), () async {
      await cleanupInvalidTokens();
      _scheduleTokenCleanup(); // Schedule next cleanup
    });
  }

  // Get token statistics
  Future<Map<String, dynamic>> getTokenStatistics() async {
    try {
      final totalUsers = await _firestore.collection('users').count().get();
      final activeTokens =
          await _firestore
              .collection('users')
              .where('tokenStatus', isEqualTo: 'active')
              .count()
              .get();
      final invalidTokens =
          await _firestore
              .collection('users')
              .where('tokenStatus', isEqualTo: 'invalid')
              .count()
              .get();

      return {
        'totalUsers': totalUsers.count,
        'activeTokens': activeTokens.count,
        'invalidTokens': invalidTokens.count,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Delete the local FCM token (called during logout)
  /// This prevents the device from receiving notifications after logout
  Future<void> deleteLocalToken() async {
    try {
      await _messaging.deleteToken();
      print('✅ Local FCM token deleted successfully');
    } catch (e) {
      print('❌ Error deleting local FCM token: $e');
      rethrow;
    }
  }
}
