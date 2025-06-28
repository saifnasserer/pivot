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
  final userProfileProvider = Provider.of<UserProfileProvider>(
    context,
    listen: false,
  );
  final loggedInUser =
      userProfileProvider.loggedInUserProfile; // The logged-in user
  final displayedProfile =
      userProfileProvider.userProfile; // The profile being viewed

  // Check if Super Admin is viewing another user's profile
  final isSuperAdminViewingOtherUser =
      loggedInUser?.role == 'Super Admin' &&
      displayedProfile != null &&
      loggedInUser?.id != displayedProfile.id;

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

  // If Super Admin is viewing their own profile, show admin options
  if (loggedInUser?.role == 'Super Admin' && !isSuperAdminViewingOtherUser) {
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

  // If Super Admin is viewing another user's profile, show edit options for that user
  if (isSuperAdminViewingOtherUser) {
    // Add edit teaching subjects option for Professor or miniProfessor
    if (displayedProfile?.role == 'Professor' ||
        displayedProfile?.role == 'miniProfessor') {
      menuItems.insert(
        1, // Insert after 'edit_profile'
        PopupMenuItem<String>(
          value: 'edit_teaching_subjects',
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Icon(Icons.edit_note, color: Colors.white),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Text(
                  'تعديل المواد المدرسية',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Add edit enrolled subjects option for Student or Admin
    if (displayedProfile?.role == 'Student' ||
        displayedProfile?.role == 'Admin') {
      menuItems.insert(
        1, // Insert after 'edit_profile'
        PopupMenuItem<String>(
          value: 'edit_enrolled_subjects',
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Icon(Icons.school, color: Colors.white),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Text(
                  'تعديل المواد المسجلة',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }
  } else {
    // Normal user viewing their own profile - show their own options
    if (displayedProfile?.role == 'Student' ||
        displayedProfile?.role == 'Admin') {
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

    if (displayedProfile?.role == 'Professor' ||
        displayedProfile?.role == 'miniProfessor') {
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
    case 'edit_teaching_subjects':
      final displayedProfile =
          Provider.of<UserProfileProvider>(context, listen: false).userProfile;
      if (displayedProfile != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SubjectSelectionScreen(
                  previouslySelectedIds: displayedProfile.teachingSubjects,
                  targetUserId: displayedProfile.id,
                ),
          ),
        );
        // If the user saved changes, refresh the profile data
        if (result == true && context.mounted) {
          final userProfileProvider = Provider.of<UserProfileProvider>(
            context,
            listen: false,
          );
          // Refresh the profile data
          await userProfileProvider.loadLoggedInUserProfile();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث المواد المدرسية بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      break;
    case 'edit_enrolled_subjects':
      final displayedProfile =
          Provider.of<UserProfileProvider>(context, listen: false).userProfile;
      if (displayedProfile != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SubjectSelectionScreen(
                  previouslySelectedIds: displayedProfile.enrolledSubjects,
                  targetUserId: displayedProfile.id,
                ),
          ),
        );
        // If the user saved changes, refresh the profile data
        if (result == true && context.mounted) {
          final userProfileProvider = Provider.of<UserProfileProvider>(
            context,
            listen: false,
          );
          // Refresh the profile data
          await userProfileProvider.loadLoggedInUserProfile();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث المواد المسجلة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      break;
    case 'edit_profile':
      if (displayedProfile != null) {
        Navigator.pushNamed(
          context,
          EditProfile.id,
          arguments: displayedProfile,
        );
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
                previouslySelectedIds: displayedProfile?.teachingSubjects ?? [],
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
                previouslySelectedIds: displayedProfile?.enrolledSubjects ?? [],
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
  NotificationPreferencesModel prefs = NotificationPreferencesModel();

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
              title: Text(
                'إعدادات الإشعارات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  color: Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FutureBuilder<bool>(
                      future: PermissionService.checkNotificationPermission(),
                      builder: (context, snapshot) {
                        final hasPermission = snapshot.data ?? false;
                        return Container(
                          padding: EdgeInsets.all(
                            Responsive.space(context, size: Space.small),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasPermission
                                    ? Icons.check_circle
                                    : Icons.error_outline,
                                color: Colors.black,
                                size: Responsive.text(
                                  context,
                                  size: TextSize.medium,
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
                                      size: TextSize.small,
                                    ),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (!hasPermission)
                                TextButton(
                                  onPressed: () async {
                                    await PermissionService.showNotificationPermissionDialog(
                                      context,
                                    );
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // محاضرات
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.school,
                                color: Colors.black,
                                size: Responsive.text(
                                  context,
                                  size: TextSize.heading,
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
                                  color: Colors.black,
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
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                        ),
                        // تاسكات
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.assignment,
                                color: Colors.black,
                                size: Responsive.text(
                                  context,
                                  size: TextSize.heading,
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
                                  color: Colors.black,
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
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                        ),
                        // اخبار
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.announcement,
                                color: Colors.black,
                                size: Responsive.text(
                                  context,
                                  size: TextSize.heading,
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
                                  color: Colors.black,
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
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: () {
                    _saveNotificationPreferences(
                      classNotifications: prefs.classNotifications,
                      taskNotifications: prefs.taskNotifications,
                      announcementNotifications:
                          prefs.announcementNotifications,
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم حفظ إعدادات الإشعارات'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
                    padding: EdgeInsets.symmetric(
                      vertical: Responsive.space(context, size: Space.small),
                    ),
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.text(context, size: TextSize.medium),
                    ),
                  ),
                  child: Text('حفظ'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'إلغاء',
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
}
