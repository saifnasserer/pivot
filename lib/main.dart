import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/providers/settings_provider.dart';
import 'package:pivot/providers/super_admin_provider.dart';
import 'package:pivot/providers/guide_provider.dart';
import 'package:pivot/screens/section2/teams.dart';
import 'package:pivot/screens/section3/edit_profile.dart'
    deferred as edit_profile;
import 'package:pivot/services/remote_config_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section1/login/login.dart';
import 'package:pivot/screens/section1/auth_wrapper.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section1/introduction_wrapper.dart';

import 'package:pivot/screens/section1/signup/signup_page1.dart';
// import 'package:pivot/screens/section1/signup/signup_page2.dart'; // Removed unused import
import 'package:pivot/screens/section2/admin_control.dart';
import 'package:pivot/screens/section2/adminstration/user_management_page.dart'
    deferred as user_management_page;
import 'package:pivot/screens/section2/adminstration/section_management_screen.dart'
    deferred as section_management_screen;
import 'package:pivot/screens/section2/adminstration/global_subject_management_screen.dart'
    deferred as global_subject_management_screen;
import 'package:pivot/screens/section2/adminstration/send_notification_screen.dart'
    deferred as send_notification_screen;
import 'package:pivot/screens/section2/super_admin_panel/super_admin_panel_screen.dart'
    deferred as super_admin_panel_screen;
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/section3/profile.dart';
import 'package:pivot/screens/section4/assistants/assistant_profile.dart';
import 'package:pivot/screens/section4/doctor/doctor_profile.dart';
import 'package:pivot/screens/section4/assistants/all_tasks.dart';

import 'package:provider/provider.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';

import 'package:pivot/providers/section_provider.dart'; // Import SectionProvider
import 'package:pivot/providers/bookmarks.dart'; // Import Bookmarks provider
import 'package:pivot/providers/scheduled_notification_provider.dart'; // Import ScheduledNotificationProvider
import 'package:pivot/providers/user_notification_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pivot/screens/section2/super_admin_panel/analytics_screen.dart'
    deferred as analytics_screen;
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:pivot/services/notification_trigger_service.dart';
import 'dart:async';
import 'package:pivot/screens/section2/adminstration/add_user_screen.dart'
    deferred as add_user_screen;
import 'package:pivot/screens/section3/feedback_screen.dart'
    deferred as feedback_screen;
import 'package:pivot/screens/models/notification_test_widget.dart';
import 'package:pivot/screens/section2/adminstration/feedback_management_screen.dart'
    deferred as feedback_management_screen;
import 'package:pivot/screens/section2/super_admin_panel/upcoming_notifications_screen.dart'
    deferred as upcoming_notifications_screen;
import 'package:pivot/providers/team_provider.dart';
import 'package:pivot/providers/teams_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'web_service_worker.dart';
import 'firebase_options.dart';
import 'widgets/platform_service.dart';
import 'widgets/ios_install_instructions_screen.dart';

// Route name constants
const String routeUserManagement = '/user-management';
const String routeGlobalSubjectManagement = '/global-subject-management';
const String routeEditProfile = '/edit-profile';
const String routeFeedback = '/feedback';
const String routeAnalytics = '/analytics';
const String routeSectionManagement = '/section-management';
const String routeSuperAdminPanel = '/super-admin-panel';
const String routeFeedbackManagement = '/feedback-management';
const String routeUpcomingNotifications = '/upcoming-notifications';
const String routeSendNotifications = '/send-notifications';
const String routeAddUser = '/add-user';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show a loading indicator for web before runApp
  if (kIsWeb) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('ar');

  await CacheService.instance.init();

  final userProfileProvider = UserProfileProvider();

  runApp(PivotWithNotifications(userProfileProvider: userProfileProvider));

  if (kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppBackgroundServices(userProfileProvider);
    });
  } else {
    _initializeAppBackgroundServices(userProfileProvider);
  }
}

Future<void> _setupFirebaseMessagingWeb() async {
  final messaging = FirebaseMessaging.instance;
  messaging.requestPermission().catchError((_) {});
  registerServiceWorkerWeb().catchError((_) {});
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Optionally handle foreground message
  });
}

void _initializeAppBackgroundServices(UserProfileProvider userProfileProvider) {
  if (kIsWeb) {
    _setupFirebaseMessagingWeb().catchError((_) {});
  }
  RemoteConfigService.instance.initialize().catchError((_) {});
  if (FirebaseAuth.instance.currentUser != null) {
    userProfileProvider
        .loadLoggedInUserProfile()
        .timeout(const Duration(seconds: 10))
        .catchError((_) {});
  }
  final notificationTrigger = NotificationTriggerService();
  notificationTrigger.startBatchProcessing();
  Timer.periodic(const Duration(minutes: 15), (_) {
    notificationTrigger.checkAndSendPeriodicNotifications();
  });
  Timer.periodic(const Duration(days: 1), (_) {
    notificationTrigger.cleanupOldNotifications();
  });
  if (kIsWeb) {
    FirebaseAuth.instance.setPersistence(Persistence.LOCAL).catchError((_) {});
  }
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
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => TeamsProvider()),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          // Remove EditProfile and TasksControl special cases; handle via routes map and arguments
          return null;
        },
        onUnknownRoute: (settings) {
          // Fallback for unknown routes
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
        home:
            PlatformService.isIOSWeb()
                ? const IOSInstallInstructionsScreen()
                : const AuthWrapper(),
        // PlatformService.isIOSWeb()
        //     ? const IOSInstallInstructionsScreen()
        //     : const AuthWrapper(),
        routes: {
          '/ios-install-instructions':
              (context) => const IOSInstallInstructionsScreen(),
          '/auth-wrapper': (context) => const AuthWrapper(),
          '/introduction-wrapper': (context) => const IntroductionWrapper(),
          '/first-landing': (context) => const FirstLandingScreen(),
          '/signup-1': (context) => const Signup_1(),
          '/login': (context) => const Login(),
          '/landing': (context) => const Landing(),
          '/profile': (context) => const Profile(),
          '/doctor-profile': (context) => const DoctorProfile(),
          '/admin-control': (context) => const AdminControl(),
          '/assistant-profile': (context) => const AssistantProfile(),
          '/notification-test': (context) => const NotificationTestWidget(),
          // Deferred and custom routes
          routeUserManagement:
              (context) => FutureBuilder(
                future: user_management_page.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return user_management_page.UserManagementPage();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          routeGlobalSubjectManagement:
              (context) => FutureBuilder(
                future: global_subject_management_screen.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return global_subject_management_screen.GlobalSubjectManagementScreen();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          routeEditProfile:
              (context) => FutureBuilder(
                future: edit_profile.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return edit_profile.EditProfile();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          routeFeedback:
              (context) => FutureBuilder(
                future: feedback_screen.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return feedback_screen.FeedbackScreen();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          routeAnalytics:
              (context) => FutureBuilder(
                future: analytics_screen.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return analytics_screen.AnalyticsScreen();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          routeSectionManagement:
              (context) => FutureBuilder(
                future: section_management_screen.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return section_management_screen.SectionManagementScreen();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          routeSuperAdminPanel:
              (context) => FutureBuilder(
                future: super_admin_panel_screen.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return super_admin_panel_screen.SuperAdminPanelScreen();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          routeFeedbackManagement:
              (context) => FutureBuilder(
                future: feedback_management_screen.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return feedback_management_screen.FeedbackManagementScreen();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          routeUpcomingNotifications:
              (context) => FutureBuilder(
                future: upcoming_notifications_screen.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return upcoming_notifications_screen.UpcomingNotificationsScreen();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          routeSendNotifications:
              (context) => FutureBuilder(
                future: send_notification_screen.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return send_notification_screen.SendNotificationScreen();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          routeAddUser:
              (context) => FutureBuilder(
                future: add_user_screen.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return add_user_screen.AddUserScreen();
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
          '/teams': (context) => const TeamsScreen(),
          '/tasks-control': (context) {
            final sectionId =
                ModalRoute.of(context)?.settings.arguments as String?;
            return TasksControl(
              key: UniqueKey(),
            ); // sectionId is accessed inside TasksControl
          },
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
          dropdownMenuTheme: DropdownMenuThemeData(
            menuStyle: MenuStyle(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                ),
              ),
              alignment: AlignmentDirectional.centerEnd,
            ),
            textStyle: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.black,
              locale: Locale('ar'),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Add error boundary
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.0)),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().initialize(context).catchError((e) {
        debugPrint('❌ Notification service init failed: $e');
      });
    });
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
      } catch (e) {}
    });

    // Clean up old notifications daily
    Timer.periodic(const Duration(days: 1), (timer) {
      try {
        NotificationTriggerService().cleanupOldNotifications();
      } catch (e) {}
    });

    // Test function - remove this in production
    _testAutomaticNotifications();
  }

  // Test function to manually trigger automatic notifications
  void _testAutomaticNotifications() {
    // Run after 10 seconds to allow app to fully initialize
    Timer(const Duration(seconds: 10), () {
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ErrorBoundary(
        child: Pivot(userProfileProvider: widget.userProfileProvider),
      ),
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
            padding: Responsive.padding(context, size: Space.large),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'حدث خطأ في التطبيق: $_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black87,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.large)),
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
