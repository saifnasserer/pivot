import 'package:flutter/material.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section2/adminstration/user_management_page.dart';
import 'package:pivot/screens/section2/adminstration/global_subject_management_screen.dart';
import 'package:pivot/screens/section3/edit_profile.dart' show EditProfile;
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> profile_options(BuildContext context) async {
  final userProfile =
      Provider.of<UserProfileProvider>(context, listen: false).userProfile;

  List<PopupMenuEntry<String>> menuItems = [
    const PopupMenuItem<String>(
      value: 'edit_profile',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(Icons.settings_outlined, color: Colors.white),
            SizedBox(width: 10),
            Text('تعديل البيانات', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ),
    const PopupMenuItem<String>(
      value: 'logout',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.white),
            SizedBox(width: 10),
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
      const PopupMenuItem<String>(
        value: 'user_management',
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.white),
              SizedBox(width: 10),
              Text('ادارة المستخدمين', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
      const PopupMenuItem<String>(
        value: 'manage_subjects',
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(Icons.class_, color: Colors.white),
              SizedBox(width: 10),
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

  if (userProfile?.role == 'Student') {
    menuItems.insert(
      1, // Insert after 'edit_profile'
      const PopupMenuItem<String>(
        value: 'enroll_in_courses',
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(Icons.school, color: Colors.white),
              SizedBox(width: 10),
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
      const PopupMenuItem<String>(
        value: 'select_subjects',
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(Icons.book, color: Colors.white),
              SizedBox(width: 10),
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
    case 'select_subjects':
      if (userProfile?.role == 'Student') {
        final selectedIds = await Navigator.push<List<String>>(
          context,
          MaterialPageRoute(
            builder:
                (context) => SubjectSelectionScreen(
                  previouslySelectedIds: userProfile?.enrolledSubjects ?? [],
                ),
          ),
        );
        if (selectedIds != null) {
          try {
            await Provider.of<UserProfileProvider>(
              context,
              listen: false,
            ).updateEnrolledSubjects(selectedIds);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your courses have been updated successfully.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to update courses. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        final selectedIds = await Navigator.push<List<String>>(
          context,
          MaterialPageRoute(
            builder:
                (context) => SubjectSelectionScreen(
                  previouslySelectedIds: userProfile?.teachingSubjects ?? [],
                ),
          ),
        );
        if (selectedIds != null) {
          try {
            final userProfileProvider = Provider.of<UserProfileProvider>(
              context,
              listen: false,
            );
            await userProfileProvider.updateTeachingSubjects(selectedIds);

            if (context.mounted) {
              final subjectProvider = Provider.of<SubjectProvider>(
                context,
                listen: false,
              );
              await subjectProvider.fetchAndFilterSubjects(
                userProfileProvider.userProfile,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Your subjects have been updated successfully.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update subjects: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
      break;
    case 'enroll_in_courses':
      final selectedIds = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder:
              (context) => SubjectSelectionScreen(
                previouslySelectedIds: userProfile?.enrolledSubjects ?? [],
              ),
        ),
      );
      if (selectedIds != null) {
        try {
          final userProfileProvider = Provider.of<UserProfileProvider>(
            context,
            listen: false,
          );
          await userProfileProvider.updateEnrolledSubjects(selectedIds);

          if (context.mounted) {
            final subjectProvider = Provider.of<SubjectProvider>(
              context,
              listen: false,
            );
            await subjectProvider.fetchAndFilterSubjects(
              userProfileProvider.userProfile,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your courses have been updated successfully.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update courses: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
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
                  child: const Text(
                    'تأكيد',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop(); // Dismiss the dialog
                    final storage = const FlutterSecureStorage();
                    await storage.deleteAll();
                    await FirebaseAuth.instance.signOut();

                    if (context.mounted) {
                      Provider.of<UserProfileProvider>(
                        context,
                        listen: false,
                      ).clearProfile();

                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        FirstLanding.id,
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                ),
                TextButton(
                  child: const Text('لا', textAlign: TextAlign.center),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Dismiss the dialog
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
