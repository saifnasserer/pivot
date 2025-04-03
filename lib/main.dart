import 'package:flutter/material.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section1/login/login.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section1/signup/signup_page1.dart';
// import 'package:pivot/screens/section1/signup/signup_page2.dart'; // Removed unused import
import 'package:pivot/screens/section2/adminstration/admin_control.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/section3/edit_profile.dart';
import 'package:pivot/screens/section3/profile.dart';
import 'package:pivot/screens/section4/assistants/all_tasks.dart';
import 'package:pivot/screens/section4/assistants/assistant_profile.dart';
import 'package:pivot/screens/section4/doctor/doctor_profile.dart';

import 'package:provider/provider.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/section_provider.dart'; // Import SectionProvider
import 'package:pivot/providers/bookmarks.dart'; // Import Bookmarks provider

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ar'); // Initialize Arabic date formatting
  runApp(const Pivot());
}

class Pivot extends StatelessWidget {
  const Pivot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(
          create: (_) => SectionProvider(),
        ), // Add SectionProvider
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => Bookmarks()), // Add Bookmarks provider
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          // Handle the dynamic "tasks" route
          if (settings.name == TasksControl.id) {
            // TasksControl screen retrieves the arguments itself using ModalRoute
            return MaterialPageRoute(
              builder: (context) {
                return const TasksControl(); // No need to pass args here
              },
              settings:
                  settings, // Pass settings along so TasksControl can read arguments
            );
          }
          // Let the routes map handle other routes
          // Or return null to trigger onUnknownRoute if defined
          return null;
        },
        routes: {
          FirstLanding.id: (context) => const FirstLanding(),
          Signup_1.id: (context) => const Signup_1(),
          Login.id: (context) => const Login(),
          Landing.id: (context) => const Landing(),
          Profile.id: (context) => const Profile(),
          EditProfile.id: (context) => const EditProfile(),
          DoctorProfile.id: (context) => const DoctorProfile(),
          AdminControl.id: (context) => const AdminControl(),
          AssistantProfile.id: (context) => AssistantProfile(),
          TasksControl.id: (context) => const TasksControl(),
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: Colors.black,
            secondary: Colors.white,
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: Colors.black87,
            contentTextStyle: TextStyle(color: Colors.white),
          ),
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
        home: const FirstLanding(),
      ),
    );
  }
}
