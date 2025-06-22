import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pivot/responsive.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static Future<bool> requestPhotosPermission() async {
    if (kIsWeb) return true;
    var status = await Permission.photos.status;
    if (status.isDenied || status.isRestricted) {
      status = await Permission.photos.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true;
    var status = await Permission.storage.status;
    if (status.isDenied || status.isRestricted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;
    var status = await Permission.camera.status;
    if (status.isDenied || status.isRestricted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestPhotosPermissionWithRationale(
    BuildContext context,
  ) async {
    if (kIsWeb) return true;
    var status = await Permission.photos.status;
    if (status.isDenied) {
      status = await Permission.photos.request();
    }
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        'يرجى منح صلاحية الوصول للصور من إعدادات التطبيق.',
      );
      return false;
    }
    return status.isGranted;
  }

  static Future<bool> requestStoragePermissionWithRationale(
    BuildContext context,
  ) async {
    if (kIsWeb) return true;
    var status = await Permission.storage.status;
    if (status.isDenied) {
      status = await Permission.storage.request();
    }
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        'يرجى منح صلاحية الوصول للتخزين من إعدادات التطبيق.',
      );
      return false;
    }
    return status.isGranted;
  }

  static Future<bool> requestCameraPermissionWithRationale(
    BuildContext context,
  ) async {
    if (kIsWeb) return true;
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        'يرجى منح صلاحية الوصول للكاميرا من إعدادات التطبيق.',
      );
      return false;
    }
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    var status = await Permission.notification.status;
    if (status.isDenied || status.isRestricted) {
      status = await Permission.notification.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermissionWithRationale(
    BuildContext context,
  ) async {
    if (kIsWeb) return true;
    var status = await Permission.notification.status;
    if (status.isDenied) {
      status = await Permission.notification.request();
    }
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        'يرجى منح صلاحية الإشعارات من إعدادات التطبيق لتلقي تذكيرات المحاضرات والمهام.',
      );
      return false;
    }
    return status.isGranted;
  }

  static Future<bool> checkNotificationPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<void> showNotificationPermissionDialog(
    BuildContext context,
  ) async {
    final hasPermission = await checkNotificationPermission();
    if (!hasPermission) {
      await requestNotificationPermissionWithRationale(context);
    }
  }

  static Future<void> _showSettingsDialog(
    BuildContext context,
    String message,
  ) async {
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).cardColor,
            title: Center(
              child: Text(
                'الصلاحية مطلوبة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:
                      Theme.of(context).textTheme.titleLarge?.fontSize ?? 20,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  color: Colors.black87,
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                child: const Text('إلغاء', textAlign: TextAlign.center),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              ElevatedButton(
                onPressed: () {
                  permission_handler.openAppSettings();
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                child: const Text('فتح الإعدادات', textAlign: TextAlign.center),
              ),
            ],
          ),
    );
  }

  // Add more as needed (location, notifications, etc.)
}
