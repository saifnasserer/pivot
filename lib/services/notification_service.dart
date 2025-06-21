import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Firebase Function URL - replace with your actual deployed function URL
  static const String _functionUrl =
      'https://us-central1-pivot-28563.cloudfunctions.net/send_notification';

  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else {
      print('User declined or has not accepted notification permission');
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _saveToken(token);
      await saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      _saveToken(newToken);
      saveTokenToFirestore(newToken);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(initializationSettings);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'pivot_notifications',
          'Pivot Notifications',
          channelDescription: 'Notifications from Pivot app',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }

  Future<void> _saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  // Save FCM token to Firestore user profile
  Future<void> saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmToken': token,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            });
        print('FCM token saved to Firestore for user: ${user.uid}');
      }
    } catch (e) {
      print('Error saving FCM token to Firestore: $e');
    }
  }

  // Get FCM token for a specific user
  Future<String?> getUserFCMToken(String userId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (doc.exists) {
        return doc.data()?['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting FCM token for user $userId: $e');
      return null;
    }
  }

  // Get FCM tokens for multiple users
  Future<List<String>> getMultipleUserFCMTokens(List<String> userIds) async {
    List<String> tokens = [];

    try {
      for (String userId in userIds) {
        final token = await getUserFCMToken(userId);
        if (token != null) {
          tokens.add(token);
        }
      }
    } catch (e) {
      print('Error getting multiple FCM tokens: $e');
    }

    return tokens;
  }

  // Get all users with FCM tokens (for admin notifications)
  Future<List<String>> getAllUserFCMTokens() async {
    List<String> tokens = [];

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('fcmToken', isNotEqualTo: null)
              .get();

      for (var doc in querySnapshot.docs) {
        final token = doc.data()['fcmToken'] as String?;
        if (token != null) {
          tokens.add(token);
        }
      }
    } catch (e) {
      print('Error getting all FCM tokens: $e');
    }

    return tokens;
  }

  // Send notification to another device
  Future<bool> sendNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': targetToken, 'title': title, 'body': body}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Notification sent successfully: ${responseData['message_id']}');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Failed to send notification: ${errorData['error']}');
        return false;
      }
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Send notification to multiple devices
  Future<bool> sendNotificationToMultiple({
    required List<String> targetTokens,
    required String title,
    required String body,
  }) async {
    try {
      // For multiple tokens, you might want to modify your Firebase function
      // to accept a list of tokens, or send them one by one
      bool allSuccess = true;

      for (String token in targetTokens) {
        bool success = await sendNotification(
          targetToken: token,
          title: title,
          body: body,
        );
        if (!success) {
          allSuccess = false;
        }
      }

      return allSuccess;
    } catch (e) {
      print('Error sending notifications to multiple devices: $e');
      return false;
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  // You can perform background tasks here
}
