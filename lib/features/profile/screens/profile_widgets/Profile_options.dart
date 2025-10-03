import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/subjects/screens/subject_selection_screen.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:pivot/widgets/biometric_settings_widget.dart';
import 'package:pivot/features/onboarding/screens/privacy_policy_screen.dart';
import 'package:pivot/features/onboarding/screens/community_guidelines_screen.dart';

Future<void> profile_options(BuildContext context, WidgetRef ref) async {
  final userProfileState = ref.read(userProfileProvider);
  final loggedInUser =
      userProfileState.loggedInUserProfile; // The logged-in user

  List<PopupMenuEntry<String>> menuItems = [
    PopupMenuItem<String>(
      value: 'edit_profile',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(Icons.settings_outlined, color: Colors.white),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Text('تعديل البيانات', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),

    PopupMenuItem<String>(
      value: 'notification_settings',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(Icons.notifications_outlined, color: Colors.white),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Text('إعدادات الإشعارات', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),

    PopupMenuItem<String>(
      value: 'biometric_settings',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(Icons.fingerprint, color: Colors.white),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Text('المصادقة الحيوية', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),

    PopupMenuItem<String>(
      value: 'feedback',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(Icons.mic, color: Colors.white),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Text('إرسال ملاحظات', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),

    PopupMenuItem<String>(
      value: 'community_guidelines',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(Icons.people_outline, color: Colors.white),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Text('قواعد المجتمع', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),

    PopupMenuItem<String>(
      value: 'privacy_policy',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: Colors.white),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Text('سياسة الخصوصية', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),

    PopupMenuItem<String>(
      value: 'logout',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.white),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Text(
              'تسجيل الخروج',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    ),
  ];

  // If Super Admin is viewing their own profile, show admin options
  if (loggedInUser?.role == 'Super Admin') {
    menuItems.insertAll(0, [
      PopupMenuItem<String>(
        value: 'user_management',
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.white),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text('ادارة المستخدمين', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
      PopupMenuItem<String>(
        value: 'manage_subjects',
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(Icons.class_, color: Colors.white),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'ادارة المواد الدراسية',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  // Add subject selection options for own profile
  if (loggedInUser?.role == 'Student' ||
      loggedInUser?.role == 'Admin' ||
      loggedInUser?.role == 'Super Admin') {
    menuItems.insert(
      1, // Insert after 'edit_profile'
      PopupMenuItem<String>(
        value: 'enroll_in_courses',
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(Icons.school, color: Colors.white),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text('تسجيل المواد', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  if (loggedInUser?.role == 'Professor' ||
      loggedInUser?.role == 'miniProfessor') {
    menuItems.insert(
      1, // Insert after 'edit_profile'
      PopupMenuItem<String>(
        value: 'select_subjects',
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(Icons.book, color: Colors.white),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text('المواد الخاصة بي', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  final result = await showMenu<String>(
    context: context,
    position: const RelativeRect.fromLTRB(100, 80, 0, 0),
    color: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    items: menuItems,
  );

  if (result == null) {
    // Menu was dismissed without a selection
    return;
  }

  // It's important to check if the context is still mounted after an await
  if (!context.mounted) return;

  switch (result) {
    case 'user_management':
      Navigator.pushNamed(context, '/user-management');
      break;
    case 'manage_subjects':
      Navigator.pushNamed(context, '/global-subject-management');
      break;
    case 'edit_profile':
      Navigator.pushNamed(context, '/edit-profile');
      break;
    case 'notification_settings':
      await _showNotificationSettingsDialog(context);
      break;
    case 'biometric_settings':
      await _showBiometricSettingsDialog(context);
      break;
    case 'feedback':
      Navigator.pushNamed(context, '/feedback');
      break;
    case 'community_guidelines':
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CommunityGuidelinesScreen(),
        ),
      );
      break;
    case 'privacy_policy':
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
      );
      break;
    case 'select_subjects':
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SubjectSelectionScreenWithProviders(
                previouslySelectedIds: loggedInUser?.teachingSubjects ?? [],
              ),
        ),
      );
      break;
    case 'enroll_in_courses':
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SubjectSelectionScreenWithProviders(
                previouslySelectedIds: loggedInUser?.enrolledSubjects ?? [],
              ),
        ),
      );
      break;
    case 'logout':
      await _showLogoutConfirmationDialog(context);
      break;
  }
}

Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap button!
    builder: (BuildContext dialogContext) {
      return UnifiedDialog(
        title: 'تسجيل الخروج؟',
        subtitle: 'هل أنت متأكد من تسجيل الخروج؟',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout,
              size: Responsive.space(context, size: Space.large) * 2,
              color: Colors.red,
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Text(
              'سيتم تسجيل خروجك من التطبيق',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        confirmText: 'تأكيد',
        confirmIcon: Icons.logout,
        onConfirm: () async {
          await FirebaseAuth.instance.signOut();
          if (!context.mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/auth-wrapper',
            (Route<dynamic> route) => false,
          );
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      );
    },
  );
}

class NotificationPreferencesModel {
  bool classNotifications;
  bool taskNotifications;
  bool announcementNotifications;

  NotificationPreferencesModel({
    this.classNotifications = true,
    this.taskNotifications = true,
    this.announcementNotifications = true,
  });
}

class NotificationSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const NotificationSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.medium),
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.small),
          color: Colors.grey.shade600,
        ),
      ),
      value: value,
      onChanged: onChanged,
      secondary: Icon(
        icon,
        color: Colors.black,
        size: Responsive.text(context, size: TextSize.medium),
      ),
    );
  }
}

Future<void> _showNotificationSettingsDialog(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  NotificationPreferencesModel prefs = NotificationPreferencesModel();

  // Load preferences from Firestore if user is logged in
  if (user != null) {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();
    if (data != null && data['notificationPreferences'] != null) {
      final np = data['notificationPreferences'];
      prefs = NotificationPreferencesModel(
        classNotifications: np['classNotifications'] ?? true,
        taskNotifications: np['taskNotifications'] ?? true,
        announcementNotifications: np['announcementNotifications'] ?? true,
      );
    }
  }

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return UnifiedDialog(
            title: 'إعدادات الإشعارات',
            subtitle: 'قم بتخصيص إعدادات الإشعارات حسب احتياجاتك',
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Permission Status
                  FutureBuilder<bool>(
                    future: NotificationService().areNotificationsEnabled(),
                    builder: (context, snapshot) {
                      final hasPermission = snapshot.data ?? false;
                      return Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.medium),
                        ),
                        decoration: BoxDecoration(
                          color:
                              hasPermission
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                          border: Border.all(
                            color:
                                hasPermission
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasPermission
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: hasPermission ? Colors.green : Colors.red,
                              size: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                hasPermission
                                    ? 'صلاحية الإشعارات مفعلة'
                                    : 'صلاحية الإشعارات مطلوبة',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (!hasPermission)
                              TextButton(
                                onPressed: () async {
                                  final notificationService =
                                      NotificationService();
                                  final granted =
                                      await notificationService
                                          .requestPermissionsExplicitly();

                                  if (!granted) {
                                    await PermissionService.showNotificationPermissionDialog(
                                      context,
                                    );
                                  }
                                  setState(() {});
                                },
                                child: Text(
                                  'تفعيل',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),

                  // Notification Types
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // محاضرات
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(
                            Responsive.space(context, size: Space.small),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.school,
                                color: Colors.black,
                                size: Responsive.space(
                                  context,
                                  size: Space.large,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              Text(
                                'محاضرات',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              Switch(
                                value: prefs.classNotifications,
                                onChanged:
                                    (value) => setState(
                                      () => prefs.classNotifications = value,
                                    ),
                                activeThumbColor: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),

                      // تاسكات
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(
                            Responsive.space(context, size: Space.small),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.assignment,
                                color: Colors.black,
                                size: Responsive.space(
                                  context,
                                  size: Space.large,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              Text(
                                'تاسكات',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              Switch(
                                value: prefs.taskNotifications,
                                onChanged:
                                    (value) => setState(
                                      () => prefs.taskNotifications = value,
                                    ),
                                activeThumbColor: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),

                      // اخبار
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(
                            Responsive.space(context, size: Space.small),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.announcement,
                                color: Colors.black,
                                size: Responsive.space(
                                  context,
                                  size: Space.large,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              Text(
                                'اخبار',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              Switch(
                                value: prefs.announcementNotifications,
                                onChanged:
                                    (value) => setState(
                                      () =>
                                          prefs.announcementNotifications =
                                              value,
                                    ),
                                activeThumbColor: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            confirmText: 'حفظ',
            confirmIcon: Icons.save,
            onConfirm: () async {
              await _saveNotificationPreferences(
                classNotifications: prefs.classNotifications,
                taskNotifications: prefs.taskNotifications,
                announcementNotifications: prefs.announcementNotifications,
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حفظ إعدادات الإشعارات'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                ),
              );
            },
            onCancel: () => Navigator.of(context).pop(),
          );
        },
      );
    },
  );
}

Future<void> _showBiometricSettingsDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return UnifiedDialog(
        title: 'إعدادات المصادقة الحيوية',
        subtitle: 'إدارة المصادقة الحيوية لتسجيل الدخول السريع',
        content: const BiometricSettingsWidget(),
        onConfirm: () => Navigator.of(context).pop(),
        confirmText: 'حسناً',
        confirmIcon: Icons.check,
      );
    },
  );
}

Future<void> _saveNotificationPreferences({
  required bool classNotifications,
  required bool taskNotifications,
  required bool announcementNotifications,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'notificationPreferences': {
        'classNotifications': classNotifications,
        'taskNotifications': taskNotifications,
        'announcementNotifications': announcementNotifications,
      },
    });
  }
}
