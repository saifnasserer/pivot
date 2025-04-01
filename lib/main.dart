import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section1/login/login.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section1/signup/signup_page1.dart';
import 'package:pivot/screens/section1/signup/signup_page2.dart';
import 'package:pivot/screens/section2/adminstration/admin_control.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/section3/edit_profile.dart';
import 'package:pivot/screens/section3/profile.dart';
import 'package:pivot/screens/section4/doctor_profile.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/announcement_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Pivot());
}

class Pivot extends StatelessWidget {
  const Pivot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
      ],
      child: MaterialApp(
        routes: {
          FirstLanding.id: (context) => const FirstLanding(),
          Signup_1.id: (context) => const Signup_1(),
          Login.id: (context) => const Login(),
          Signup_2.id: (context) => const Signup_2(),
          Landing.id: (context) => const Landing(),
          Profile.id: (context) => const Profile(),
          EditProfile.id: (context) => const EditProfile(),
          DoctorProfile.id: (context) => const DoctorProfile(),
          AdminControl.id: (context) => const AdminControl(),
        },
        theme: ThemeData(
          fontFamily: 'NotoSansArabic',
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: Responsive.text(context, size: TextSize.heading),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const Landing(),
      ),
    );
  }
}
