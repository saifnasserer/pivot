import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

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
          debugPrint('🔔 Web notification permission granted.');
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
}
