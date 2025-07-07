import 'dart:convert';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/models/user_notification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static const String _functionUrl =
      'https://us-central1-pivot-28563.cloudfunctions.net/send_notification';

  Future<void> initialize(BuildContext context) async {
    debugPrint('🔔 Initializing NotificationService...');

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

    debugPrint('🔔 Setting up permissions gracefully...');
    // Use graceful permission request that doesn't block
    requestPermissionsGracefully();

    // Web-specific: request browser notification permission
    if (kIsWeb) {
      await requestWebNotificationPermission(context);
    }

    debugPrint('🔔 Configuring FCM listeners...');
    await _configureFCMListeners();

    debugPrint('🔔 Getting and saving FCM token...');
    await _getAndSaveFCMToken();

    debugPrint('✅ NotificationService initialized');
  }

  Future<void> _requestPermissions() async {
    // Don't block the app startup - handle permissions in background
    try {
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        // Request permission without awaiting - let it run in background
        AwesomeNotifications()
            .requestPermissionToSendNotifications()
            .catchError((e) {
              debugPrint('Notification permission request failed: $e');
            });
      }
    } catch (e) {
      debugPrint('Error checking notification permissions: $e');
    }
  }

  Future<void> _getAndSaveFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveToken(token);
      await saveTokenToFirestore(token);
    }
  }

  Future<void> _configureFCMListeners() async {
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showAwesomeNotification(message);
      await _saveNotificationToHistory(message);
    });

    // Listen for when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _showAwesomeNotification(message);
      await _saveNotificationToHistory(message);
    });

    // Set the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _showAwesomeNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
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
    } catch (e) {}
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
    } catch (e) {}
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
      }
    } catch (e) {}
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
    } catch (e) {}
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

      // Send HTTPS POST request using dart:io HttpClient
      final client = HttpClient();
      try {
        final request = await client.postUrl(Uri.parse(_functionUrl));
        request.headers.set('Content-Type', 'application/json');
        request.add(utf8.encode(jsonEncode(payload)));
        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          return true;
        } else {
          return false;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      return false;
    }
  }

  // New method to handle permissions gracefully without blocking
  Future<void> requestPermissionsGracefully() async {
    debugPrint('🔔 Checking notification permissions gracefully...');
    // Check current permission status
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      debugPrint(
        '🔔 FCM authorization status: ${settings.authorizationStatus}',
      );

      // Only request if not determined (first time) or denied
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        debugPrint('🔔 Requesting FCM permissions (non-blocking)...');
        // Request permission without blocking
        _firebaseMessaging.requestPermission().catchError((e) {
          debugPrint('❌ FCM permission request failed: $e');
        });
      }

      // Also check Awesome Notifications permissions
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      debugPrint('🔔 Awesome Notifications allowed: $isAllowed');
      if (!isAllowed) {
        debugPrint(
          '🔔 Requesting Awesome Notifications permissions (non-blocking)...',
        );
        AwesomeNotifications()
            .requestPermissionToSendNotifications()
            .catchError((e) {
              debugPrint(
                '❌ Awesome Notifications permission request failed: $e',
              );
            });
      }
    } catch (e) {
      debugPrint('❌ Error in graceful permission request: $e');
    }
  }

  // Method to request permissions when user explicitly wants notifications
  Future<bool> requestPermissionsExplicitly() async {
    try {
      // Request FCM permissions
      final fcmSettings = await _firebaseMessaging.requestPermission();

      // Request Awesome Notifications permissions
      final awesomeAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();

      return fcmSettings.authorizationStatus ==
              AuthorizationStatus.authorized &&
          awesomeAllowed;
    } catch (e) {
      debugPrint('Error requesting permissions explicitly: $e');
      return false;
    }
  }

  // Method to check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final fcmSettings = await _firebaseMessaging.getNotificationSettings();
      final awesomeAllowed =
          await AwesomeNotifications().isNotificationAllowed();

      return fcmSettings.authorizationStatus ==
              AuthorizationStatus.authorized &&
          awesomeAllowed;
    } catch (e) {
      debugPrint('Error checking notification status: $e');
      return false;
    }
  }

  /// Web-only: Request browser notification permission and handle user feedback
  Future<void> requestWebNotificationPermission(BuildContext context) async {
    if (!kIsWeb) return;
    try {
      if (html.Notification.supported) {
        final permission = await html.Notification.requestPermission();
        if (permission == 'granted') {
          debugPrint('🔔 Web notification permission granted.');
          // Safe to call getToken() if needed
        } else if (permission == 'denied') {
          debugPrint('❌ Web notification permission denied.');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('يرجى السماح بالإشعارات من إعدادات المتصفح.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          debugPrint('ℹ️ Web notification permission: $permission');
        }
      } else if (_isIOS()) {
        debugPrint('❌ Notifications are not supported on iOS browsers.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'الإشعارات غير مدعومة في متصفحات iOS. إذا كنت تستخدم iOS 16.4 أو أحدث، يمكنك تثبيت التطبيق كـ PWA (إضافة إلى الشاشة الرئيسية) لتفعيل الإشعارات.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        debugPrint('❌ Notifications are not supported on this browser.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الإشعارات غير مدعومة في هذا المتصفح.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error requesting web notification permission: $e');
    }
  }

  /// Helper to detect iOS user agent
  bool _isIOS() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Required for background isolate

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
    } catch (e) {}
  } else {}
}
