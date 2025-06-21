import 'package:flutter/material.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section2/adminstration/user_management_page.dart';
import 'package:pivot/screens/section2/adminstration/global_subject_management_screen.dart';
import 'package:pivot/screens/section3/edit_profile.dart' show EditProfile;
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:pivot/screens/section3/feedback_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      value: 'feedback',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(Icons.feedback_outlined, color: Colors.white),
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
    case 'feedback':
      Navigator.pushNamed(context, FeedbackScreen.id);
      break;
    case 'notification_permissions':
      await _handleNotificationPermissions(context);
      break;
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
          content: const SingleChildScrollView(
            // child: ListBody(
            //   children: <Widget>[
            //     Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
            //   ],
            // ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.large)),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.green),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _performLogout(context);
                  },
                  child: const Text(
                    'تأكيد',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

// Perform logout
Future<void> _performLogout(BuildContext context) async {
  final storage = const FlutterSecureStorage();
  await storage.deleteAll();
  await FirebaseAuth.instance.signOut();

  if (context.mounted) {
    Provider.of<UserProfileProvider>(context, listen: false).clearProfile();

    Navigator.pushNamedAndRemoveUntil(
      context,
      FirstLandingScreen.id,
      (Route<dynamic> route) => false,
    );
  }
}

// Handle notification permissions
Future<void> _handleNotificationPermissions(BuildContext context) async {
  if (kIsWeb) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('الإشعارات غير متوفرة على المتصفح'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Use existing static method from PermissionService
  bool granted = await PermissionService.requestStoragePermission();

  if (!granted) {
    // Show dialog to open settings if permission denied
    await PermissionService.requestStoragePermissionWithRationale(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تفعيل الإشعارات بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
