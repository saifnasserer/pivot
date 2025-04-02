import 'package:flutter/material.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section3/edit_profile.dart' show EditProfile;
import 'package:provider/provider.dart';

Future<dynamic> profile_options(BuildContext context) {
  return showMenu(
    context: context,
    position: RelativeRect.fromLTRB(100, 80, 0, 0),
    color: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    items: [
      PopupMenuItem(
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
        onTap: () {
          Navigator.pushNamed(context, EditProfile.id);
        },
      ),
      PopupMenuItem(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.white),
              SizedBox(width: 10),
              Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        onTap: () {
          Provider.of<UserProfileProvider>(
            context,
            listen: false,
          ).clearProfile();
          Navigator.pushNamedAndRemoveUntil(
            context,
            FirstLanding.id,
            (Route<dynamic> route) => false,
          );
        },
      ),
    ],
  );
}
