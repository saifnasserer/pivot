import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
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
          (ctx) => UnifiedDialog(
            title: 'الصلاحية مطلوبة',
            subtitle: 'يجب منح الصلاحية للاستمرار',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Warning icon
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: Responsive.space(context, size: Space.large),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.medium),
                      ),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                // Instructions
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: Responsive.space(context, size: Space.medium),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.medium),
                      ),
                      Expanded(
                        child: Text(
                          'اضغط على "فتح الإعدادات" للانتقال إلى إعدادات التطبيق ومنح الصلاحية المطلوبة',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            confirmText: 'فتح الإعدادات',
            confirmIcon: Icons.settings,
            onConfirm: () {
              permission_handler.openAppSettings();
              Navigator.of(ctx).pop();
            },
            onCancel: () => Navigator.of(ctx).pop(),
          ),
    );
  }

  // Add more as needed (location, notifications, etc.)
}
