import 'package:flutter/material.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section1/auth_wrapper.dart';
import 'package:pivot/screens/section2/adminstration/user_management_page.dart';
import 'package:pivot/screens/section2/adminstration/global_subject_management_screen.dart';
import 'package:pivot/screens/section3/edit_profile.dart' show EditProfile;
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:pivot/screens/section3/feedback_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:pivot/responsive.dart';

Future<void> profile_options(BuildContext context) async {
  final userProfile =
      Provider.of<UserProfileProvider>(context, listen: false).userProfile;

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

  if (userProfile?.role == 'Super Admin') {
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

  if (userProfile?.role == 'Student' || userProfile?.role == 'Admin') {
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
              Text('المواد الدراسية', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  if (userProfile?.role == 'Professor' ||
      userProfile?.role == 'miniProfessor') {
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
      Navigator.pushNamed(context, UserManagementPage.id);
      break;
    case 'manage_subjects':
      Navigator.pushNamed(context, GlobalSubjectManagementScreen.id);
      break;
    case 'edit_profile':
      if (userProfile != null) {
        Navigator.pushNamed(context, EditProfile.id, arguments: userProfile);
      }
      break;
    case 'notification_settings':
      await _showNotificationSettingsDialog(context);
      break;
    case 'feedback':
      Navigator.pushNamed(context, FeedbackScreen.id);
      break;
    // case 'notification_permissions':
    //   await _handleNotificationPermissions(context);
    //   break;
    case 'select_subjects':
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SubjectSelectionScreen(
                previouslySelectedIds: userProfile?.teachingSubjects ?? [],
              ),
        ),
      );
      break;
    case 'enroll_in_courses':
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SubjectSelectionScreen(
                previouslySelectedIds: userProfile?.enrolledSubjects ?? [],
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
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج؟', textAlign: TextAlign.center),

          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AuthWrapper.id,
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Text(
                      'تأكيد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                TextButton(
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showNotificationSettingsDialog(BuildContext context) async {
  bool classNotifications = true;
  bool taskNotifications = true;
  bool announcementNotifications = true;

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'إعدادات الإشعارات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.text(context, size: TextSize.heading),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Permission check
                  FutureBuilder<bool>(
                    future: PermissionService.checkNotificationPermission(),
                    builder: (context, snapshot) {
                      final hasPermission = snapshot.data ?? false;
                      return Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        decoration: BoxDecoration(
                          color:
                              hasPermission
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                hasPermission
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasPermission ? Icons.check_circle : Icons.error,
                              color: hasPermission ? Colors.green : Colors.red,
                              size: 20,
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
                                    size: TextSize.small,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (!hasPermission)
                              TextButton(
                                onPressed: () async {
                                  await PermissionService.showNotificationPermissionDialog(
                                    context,
                                  );
                                  setState(() {}); // Refresh the dialog
                                },
                                child: Text('تفعيل'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),

                  // Notification types
                  Text(
                    'أنواع الإشعارات',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),

                  // Class notifications
                  SwitchListTile(
                    title: Text('تذكيرات المحاضرات'),
                    subtitle: Text('إشعارات قبل 15 دقيقة من المحاضرة'),
                    value: classNotifications,
                    onChanged: (value) {
                      setState(() {
                        classNotifications = value;
                      });
                    },
                    secondary: Icon(Icons.school),
                  ),

                  // Task notifications
                  SwitchListTile(
                    title: Text('تذكيرات المهام'),
                    subtitle: Text('إشعارات للمهام المستحقة والمتأخرة'),
                    value: taskNotifications,
                    onChanged: (value) {
                      setState(() {
                        taskNotifications = value;
                      });
                    },
                    secondary: Icon(Icons.assignment),
                  ),

                  // Announcement notifications
                  SwitchListTile(
                    title: Text('إشعارات الإعلانات'),
                    subtitle: Text('إشعارات الإعلانات الجديدة'),
                    value: announcementNotifications,
                    onChanged: (value) {
                      setState(() {
                        announcementNotifications = value;
                      });
                    },
                    secondary: Icon(Icons.announcement),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Save notification preferences
                  _saveNotificationPreferences(
                    classNotifications: classNotifications,
                    taskNotifications: taskNotifications,
                    announcementNotifications: announcementNotifications,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حفظ إعدادات الإشعارات'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text('حفظ'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _saveNotificationPreferences({
  required bool classNotifications,
  required bool taskNotifications,
  required bool announcementNotifications,
}) {
  // Save to SharedPreferences or other storage
  // This is a placeholder - implement actual storage logic
  print('Saving notification preferences:');
  print('Class notifications: $classNotifications');
  print('Task notifications: $taskNotifications');
  print('Announcement notifications: $announcementNotifications');
}
