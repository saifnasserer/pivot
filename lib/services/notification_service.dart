import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/models/user_notification.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static const String _functionUrl =
      'https://us-central1-pivot-28563.cloudfunctions.net/send_notification';

  Future<void> initialize() async {
    await AwesomeNotifications()
        .initialize('resource://drawable/ic_notification', [
          NotificationChannel(
            channelKey: 'pivot_notifications',
            channelName: 'Pivot Notifications',
            channelDescription: 'Notifications from Pivot app',
            defaultColor: Colors.black,
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            enableVibration: true,
            playSound: true,
          ),
        ], debug: true);

    await _requestPermissions();
    await _configureFCMListeners();
    await _getAndSaveFCMToken();
  }

  Future<void> _requestPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> _getAndSaveFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _saveToken(token);
      await saveTokenToFirestore(token);
    }
  }

  Future<void> _configureFCMListeners() async {
    print("NotificationService: Configuring FCM listeners...");
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("NotificationService: FOREGROUND message received!");
      print(
        "NotificationService: Title: ${message.notification?.title}, Body: ${message.notification?.body}",
      );
      _showAwesomeNotification(message);
      _saveNotificationToHistory(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print("NotificationService: FCM listeners configured.");
  }

  Future<void> _showAwesomeNotification(RemoteMessage message) async {
    print("NotificationService: Attempting to show notification...");
    final notification = message.notification;
    if (notification == null) {
      print(
        "NotificationService: Message has no notification payload, aborting.",
      );
      return;
    }

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: message.hashCode,
          channelKey: 'pivot_notifications',
          title: notification.title,
          body: notification.body,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Message,
          payload: Map<String, String>.from(message.data),
          largeIcon: message.data['image_url'],
          bigPicture: message.data['image_url'],
        ),
      );
      print("NotificationService: createNotification call succeeded.");
    } catch (e) {
      print("NotificationService: ERROR creating notification: $e");
    }
  }

  Future<void> _saveNotificationToHistory(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || message.notification == null) return;

    final notification = UserNotification(
      id: message.messageId ?? DateTime.now().toIso8601String(),
      title: message.notification!.title ?? 'No Title',
      body: message.notification!.body ?? 'No Body',
      createdAt: message.sentTime ?? DateTime.now(),
      data: message.data,
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add(notification.toJson());
      print("Notification saved to history for user ${user.uid}");
    } catch (e) {
      print("Error saving notification to history: $e");
    }
  }

  // Show a local test notification
  Future<void> showLocalTestNotification({
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'pivot_notifications',
        title: title,
        body: body,
        payload: payload,
        notificationLayout: NotificationLayout.Default,
      ),
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

  Future<String?> getUserFCMToken(String userId) async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting FCM token for user $userId: $e');
      return null;
    }
  }

  Future<List<String>> getMultipleUserFCMTokens(List<String> userIds) async {
    List<String> tokens = [];
    for (String userId in userIds) {
      final token = await getUserFCMToken(userId);
      if (token != null) tokens.add(token);
    }
    return tokens;
  }

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
        if (token != null) tokens.add(token);
      }
    } catch (e) {
      print('Error getting all FCM tokens: $e');
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
      final Map<String, dynamic> payload = {
        'token': targetToken,
        'title': title,
        'body': body,
        'data': data ?? {},
      };

      if (userId != null) {
        payload['data']['userId'] = userId;
      }
      if (icon != null) payload['icon'] = icon;
      if (color != null) payload['color'] = color;
      if (sound != null) payload['sound'] = sound;
      if (imageUrl != null) payload['image_url'] = imageUrl;

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully: ${response.body}');
        return true;
      } else {
        print('Failed to send notification: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Required for background isolate
  print("Handling a background message: ${message.messageId}");

  // Show the notification
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: message.hashCode,
      channelKey: 'pivot_notifications',
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? 'New message arrived.',
      notificationLayout: NotificationLayout.Default,
      payload: Map<String, String>.from(message.data),
    ),
  );

  // Save to history
  final userId = message.data['userId'];
  final notification = message.notification;

  if (userId != null && notification != null) {
    final userNotification = UserNotification(
      id: message.messageId ?? DateTime.now().toIso8601String(),
      title: notification.title ?? 'No Title',
      body: notification.body ?? 'No Body',
      createdAt: message.sentTime ?? DateTime.now(),
      data: message.data,
    );
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(userNotification.toJson());
      print("Background notification saved to history for user $userId");
    } catch (e) {
      print("Error saving background notification to history: $e");
    }
  } else {
    print(
      "Could not save background notification to history: userId or notification part is null.",
    );
  }
}
