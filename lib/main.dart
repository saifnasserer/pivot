import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/providers/settings_provider.dart';
import 'package:pivot/providers/super_admin_provider.dart';
import 'package:pivot/providers/guide_provider.dart';
import 'package:pivot/screens/section3/edit_profile.dart';
import 'package:pivot/services/remote_config_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/screens/section1/login/login.dart';
import 'package:pivot/screens/section1/auth_wrapper.dart';
import 'package:pivot/screens/section1/first_landing.dart';

import 'package:pivot/screens/section1/signup/signup_page1.dart';
// import 'package:pivot/screens/section1/signup/signup_page2.dart'; // Removed unused import
import 'package:pivot/screens/section2/admin_control.dart';
import 'package:pivot/screens/section2/adminstration/user_management_page.dart';
import 'package:pivot/screens/section2/adminstration/section_management_screen.dart';
import 'package:pivot/screens/section2/adminstration/global_subject_management_screen.dart';
import 'package:pivot/screens/section2/adminstration/send_notification_screen.dart';
import 'package:pivot/screens/section2/super_admin_panel/super_admin_panel_screen.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/section3/profile.dart';
import 'package:pivot/screens/section4/assistants/all_tasks.dart';
import 'package:pivot/screens/section4/assistants/assistant_profile.dart';
import 'package:pivot/screens/section4/doctor/doctor_profile.dart';

import 'package:provider/provider.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';

import 'package:pivot/providers/section_provider.dart'; // Import SectionProvider
import 'package:pivot/providers/bookmarks.dart'; // Import Bookmarks provider
import 'package:pivot/providers/scheduled_notification_provider.dart'; // Import ScheduledNotificationProvider
import 'package:pivot/providers/user_notification_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pivot/screens/section2/super_admin_panel/analytics_screen.dart';
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:pivot/services/notification_trigger_service.dart';
import 'dart:async';
import 'package:pivot/screens/section2/adminstration/add_user_screen.dart';
import 'package:pivot/screens/section3/feedback_screen.dart';
import 'package:pivot/screens/models/notification_test_widget.dart';
import 'package:pivot/screens/section2/adminstration/feedback_management_screen.dart';
import 'package:pivot/screens/section2/super_admin_panel/upcoming_notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Essential initializations only - these are required for app to function
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Firebase (essential)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase App Check (essential for security)
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'),
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest,
    );

    // Initialize Arabic date formatting (essential for UI)
    await initializeDateFormatting('ar');

    // Create the provider (don't load data yet)
    final userProfileProvider = UserProfileProvider();

    // Start the app immediately
    runApp(PivotWithNotifications(userProfileProvider: userProfileProvider));

    // Run non-critical initializations in background
    _initializeBackgroundServices(userProfileProvider);
  } catch (e) {
    debugPrint('Critical error during app initialization: $e');
    // Run app with minimal configuration
    final userProfileProvider = UserProfileProvider();
    runApp(PivotWithNotifications(userProfileProvider: userProfileProvider));
  }
}

// Background initialization function
void _initializeBackgroundServices(
  UserProfileProvider userProfileProvider,
) async {
  try {
    // Initialize cache service
    await CacheService.instance.init();
    debugPrint('Cache service initialized successfully');
  } catch (e) {
    debugPrint('Cache service initialization failed: $e');
  }

  try {
    // Initialize Remote Config
    await RemoteConfigService.instance.initialize();
    debugPrint('Remote config initialized successfully');
  } catch (e) {
    debugPrint('Remote config initialization failed: $e');
  }

  try {
    // Initialize notification service
    await NotificationService().initialize();
    debugPrint('Notification service initialized successfully');
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
  }

  try {
    // Load user profile if logged in
    if (FirebaseAuth.instance.currentUser != null) {
      await userProfileProvider.loadLoggedInUserProfile().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('User profile loading timed out in background');
          return false;
        },
      );
      debugPrint('User profile loaded successfully');
    }
  } catch (e) {
    debugPrint('User profile loading failed: $e');
  }

  // Set Firebase Auth persistence for web (non-blocking)
  if (kIsWeb) {
    try {
      FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      debugPrint('Firebase Auth persistence set for web');
    } catch (e) {
      debugPrint('Firebase Auth persistence failed: $e');
    }
  }

  // Run auto notifications after a delay to avoid blocking startup
  Future.delayed(const Duration(seconds: 5), () {
    try {
      // Automatic notifications are now initialized in _startPeriodicNotifications
      debugPrint('Auto notifications system ready');
    } catch (e) {
      debugPrint('Auto notifications failed: $e');
    }
  });
}

class Pivot extends StatelessWidget {
  const Pivot({super.key, required this.userProfileProvider});
  final UserProfileProvider userProfileProvider;

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
        ChangeNotifierProvider.value(value: userProfileProvider),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => Bookmarks()),
        ChangeNotifierProvider(create: (_) => DoctorSubjectProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SuperAdminProvider()),
        ChangeNotifierProvider(create: (_) => GuideProvider()),
        ChangeNotifierProvider(create: (_) => ScheduledNotificationProvider()),
        ChangeNotifierProvider(create: (_) => UserNotificationProvider()),
        Provider<RemoteConfigService>(
          create: (_) => RemoteConfigService.instance,
        ),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          // Handle the dynamic "tasks" route
          if (settings.name == EditProfile.id) {
            if (settings.arguments is UserProfile) {
              final userProfile = settings.arguments as UserProfile;
              return MaterialPageRoute(
                builder: (context) {
                  return EditProfile(userProfile: userProfile);
                },
              );
            }
            // Fallback for when arguments are not of the correct type
            return MaterialPageRoute(
              builder:
                  (_) => Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: const Center(
                      child: Text('Error: Invalid profile data.'),
                    ),
                  ),
            );
          }
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
        onUnknownRoute: (settings) {
          // Fallback for unknown routes
          debugPrint('Unknown route: ${settings.name}');
          return MaterialPageRoute(
            builder:
                (context) => Scaffold(
                  appBar: AppBar(title: const Text('Page Not Found')),
                  body: const Center(
                    child: Text('The requested page was not found.'),
                  ),
                ),
          );
        },
        initialRoute: AuthWrapper.id, // Set the initial route
        routes: {
          AuthWrapper.id: (context) => const AuthWrapper(),

          FirstLandingScreen.id: (context) => const FirstLandingScreen(),
          Signup_1.id: (context) => const Signup_1(),
          Login.id: (context) => const Login(),
          Landing.id: (context) => const Landing(),
          Profile.id: (context) => const Profile(),
          DoctorProfile.id: (context) => const DoctorProfile(),
          AdminControl.id: (context) => const AdminControl(),
          UserManagementPage.id: (context) => const UserManagementPage(),
          '/section-management': (context) => const SectionManagementScreen(),
          '/super-admin-panel': (context) => const SuperAdminPanelScreen(),
          '/send-notifications': (context) => const SendNotificationScreen(),
          GlobalSubjectManagementScreen.id:
              (context) => const GlobalSubjectManagementScreen(),
          AssistantProfile.id: (context) => const AssistantProfile(),
          TasksControl.id: (context) => const TasksControl(),
          AnalyticsScreen.id: (context) => const AnalyticsScreen(),
          AddUserScreen.id: (context) => const AddUserScreen(),
          FeedbackScreen.id: (context) => const FeedbackScreen(),
          FeedbackManagementScreen.id:
              (context) => const FeedbackManagementScreen(),
          NotificationTestWidget.id:
              (context) => const NotificationTestWidget(),
          UpcomingNotificationsScreen.id:
              (context) => const UpcomingNotificationsScreen(),
          // NotificationsScreen.id: (context) => const NotificationsScreen(),
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
              fontFamily: 'NotoSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(), // Ensure AuthWrapper is the home
        builder: (context, child) {
          // Add error boundary
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
      ),
    );
  }
}

// Add a StatefulWidget wrapper to handle periodic notifications
class PivotWithNotifications extends StatefulWidget {
  final UserProfileProvider userProfileProvider;

  const PivotWithNotifications({super.key, required this.userProfileProvider});

  @override
  State<PivotWithNotifications> createState() => _PivotWithNotificationsState();
}

class _PivotWithNotificationsState extends State<PivotWithNotifications> {
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _startPeriodicNotifications();
  }

  void _startPeriodicNotifications() {
    // Initialize automatic notifications on app start
    NotificationTriggerService().initializeAutomaticNotifications();

    // Run notifications every 15 minutes
    _notificationTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      try {
        NotificationTriggerService().checkAndSendPeriodicNotifications();
        NotificationTriggerService().processScheduledNotifications();
      } catch (e) {
        debugPrint('Error in periodic notifications: $e');
      }
    });

    // Clean up old notifications daily
    Timer.periodic(const Duration(days: 1), (timer) {
      try {
        NotificationTriggerService().cleanupOldNotifications();
      } catch (e) {
        debugPrint('Error cleaning up old notifications: $e');
      }
    });

    // Test function - remove this in production
    _testAutomaticNotifications();
  }

  // Test function to manually trigger automatic notifications
  void _testAutomaticNotifications() {
    // Run after 10 seconds to allow app to fully initialize
    Timer(const Duration(seconds: 10), () {
      debugPrint('Testing automatic notification system...');
      NotificationTriggerService().initializeAutomaticNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Pivot(userProfileProvider: widget.userProfileProvider),
    );
  }
}

// Error boundary widget to catch unhandled errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ في التطبيق: $_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontFamily: 'NotoSansArabic'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    // Set up error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter error caught: ${details.exception}');
      // Schedule the state update for after the current build frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = details.exception.toString();
          });
        }
      });
    };
  }
}
