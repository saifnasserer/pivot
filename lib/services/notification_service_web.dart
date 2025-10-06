import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Web background message handler (not used on web, but exported for consistency)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Web platform - background messages handled by service worker
  print('Web background message (handled by SW): ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize(BuildContext context) async {
    await requestWebNotificationPermission(context);
  }

  Future<void> requestWebNotificationPermission(BuildContext context) async {
    if (!kIsWeb) return;
    try {
      if (html.Notification.supported) {
        final permission = await html.Notification.requestPermission();
        if (permission == 'granted') {
        } else if (permission == 'denied') {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('يرجى السماح بالإشعارات من إعدادات المتصفح.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {}
      } else if (_isIOS()) {
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
      print('Error requesting web notification permission: $e');
    }
  }

  bool _isIOS() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
  }

  Future<String?> getUserFCMToken(String userId) async => null;
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
  }) async => false;
  Future<bool> requestPermissionsExplicitly() async => false;
  Future<bool> areNotificationsEnabled() async => false;
  Future<String?> getToken() async => null;
  Future<void> saveTokenToFirestore(String token) async {}
  Future<List<String>> getAllUserFCMTokens() async => <String>[];
  Future<List<String>> getMultipleUserFCMTokens(List<String> userIds) async =>
      <String>[];

  // FCM Token cleanup methods (web implementations)
  Future<Map<String, dynamic>> cleanupInvalidTokens() async => {
    'totalUsers': 0,
    'cleanedTokens': 0,
    'errors': <String>[],
    'timestamp': DateTime.now().toIso8601String(),
  };

  Future<Map<String, dynamic>> getTokenStatistics() async => {
    'totalUsers': 0,
    'usersWithActiveTokens': 0,
    'usersWithInvalidTokens': 0,
    'usersWithoutTokens': 0,
    'recentTokens': 0,
    'oldTokens': 0,
    'timestamp': DateTime.now().toIso8601String(),
  };

  Future<bool> refreshCurrentUserToken() async => false;

  Future<bool> requestNewTokenFromUser(String userId) async => false;

  Future<Map<String, dynamic>> sendBatchNotifications({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async => {
    'totalTokens': tokens.length,
    'successCount': 0,
    'failureCount': tokens.length,
    'invalidTokens': <String>[],
    'errors': <String>[],
  };
}
