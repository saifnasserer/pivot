import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:permission_handler/permission_handler.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static Future<bool> requestPhotosPermission() async {
    if (kIsWeb) return true;
    var status = await permission_handler.Permission.photos.status;
    if (status.isDenied || status.isRestricted) {
      status = await permission_handler.Permission.photos.request();
    }
    return status.isGranted;
  }

  // DEPRECATED: Storage permission not needed for modern Android scoped storage
  // static Future<bool> requestStoragePermission() async {
  //   if (kIsWeb) return true;
  //   var status = await Permission.storage.status;
  //   if (status.isDenied || status.isRestricted) {
  //     status = await Permission.storage.request();
  //   }
  //   return status.isGranted;
  // }

  static Future<bool> requestPhotosPermissionWithRationale(
    BuildContext context,
  ) async {
    if (kIsWeb) return true;
    var status = await permission_handler.Permission.photos.status;
    if (status.isDenied) {
      status = await permission_handler.Permission.photos.request();
    }
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        'يرجى منح صلاحية الوصول للصور من إعدادات التطبيق لاختيار صورة الملف الشخصي.',
      );
      return false;
    }
    return status.isGranted;
  }

  // DEPRECATED: Storage permission not needed for modern Android scoped storage
  // static Future<bool> requestStoragePermissionWithRationale(
  //   BuildContext context,
  // ) async {
  //   if (kIsWeb) return true;
  //   var status = await Permission.storage.status;
  //   if (status.isDenied) {
  //     status = await Permission.storage.request();
  //   }
  //   if (status.isPermanentlyDenied) {
  //     await _showSettingsDialog(
  //       context,
  //       'يرجى منح صلاحية الوصول للتخزين من إعدادات التطبيق.',
  //     );
  //     return false;
  //   }
  //   return status.isGranted;
  // }

  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    var status = await permission_handler.Permission.notification.status;
    if (status.isDenied || status.isRestricted) {
      status = await permission_handler.Permission.notification.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermissionWithRationale(
    BuildContext context,
  ) async {
    if (kIsWeb) return true;
    var status = await permission_handler.Permission.notification.status;
    if (status.isDenied) {
      status = await permission_handler.Permission.notification.request();
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
    final status = await permission_handler.Permission.notification.status;
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

  // Biometric permission handling
  static Future<bool> requestBiometricPermissionWithRationale(
    BuildContext context,
  ) async {
    if (kIsWeb) return true;

    // Check if biometric is available
    final LocalAuthentication localAuth = LocalAuthentication();
    final bool isAvailable = await localAuth.canCheckBiometrics;

    if (!isAvailable) {
      await _showSettingsDialog(
        context,
        'الجهاز لا يدعم البصمة أو التعرف على الوجه. يرجى التأكد من تفعيل هذه الميزة في إعدادات الجهاز.',
      );
      return false;
    }

    try {
      // Try to authenticate - this will request permission if needed
      final bool isAuthenticated = await localAuth.authenticate(
        localizedReason:
            'استخدم البصمة أو التعرف على الوجه لتسجيل الدخول بشكل آمن',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      await _showSettingsDialog(
        context,
        'يرجى منح صلاحية استخدام البصمة أو التعرف على الوجه من إعدادات التطبيق لتسجيل الدخول بشكل آمن.',
      );
      return false;
    }
  }

  static Future<bool> checkBiometricPermission() async {
    if (kIsWeb) return false;
    final LocalAuthentication localAuth = LocalAuthentication();
    return await localAuth.canCheckBiometrics;
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
