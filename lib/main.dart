import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/providers/settings_provider.dart';
import 'package:pivot/providers/super_admin_provider.dart';
import 'package:pivot/providers/guide_provider.dart';
import 'package:pivot/services/remote_config_service.dart';
import 'package:pivot/features/teams/screens/screens.dart';
import 'package:pivot/features/profile/screens/edit_profile/edit_profile.dart'
    deferred as edit_profile;
import 'package:pivot/responsive.dart';
import 'package:pivot/features/administration/screens/assistants/profile/assistant_profile_main.dart';
import 'package:pivot/features/administration/screens/doctor/profile/doctor_profile.dart';
import 'package:pivot/features/onboarding/screens/login/login.dart';
import 'package:pivot/features/onboarding/screens/auth_wrapper.dart';
import 'package:pivot/features/onboarding/screens/first_landing.dart';
import 'package:pivot/features/onboarding/screens/introduction_wrapper.dart';

import 'package:pivot/features/onboarding/screens/signup/signup_page1.dart';
import 'package:pivot/features/onboarding/screens/signup/signup_page2.dart';
import 'package:pivot/features/home/screens/admin_control.dart';
import 'package:pivot/features/home/screens/adminstration/user_management_page.dart'
    deferred as user_management_page;
import 'package:pivot/features/home/screens/adminstration/section_management_screen.dart'
    deferred as section_management_screen;
import 'package:pivot/features/home/screens/adminstration/global_subject_management_screen.dart'
    deferred as global_subject_management_screen;
import 'package:pivot/features/notifications/screens/screens.dart'
    deferred as send_notification_screen;
import 'package:pivot/features/home/screens/super_admin_panel/super_admin_panel_screen.dart'
    deferred as super_admin_panel_screen;
import 'package:pivot/features/home/screens/landing.dart';
import 'package:pivot/features/profile/screens/profile/profile.dart';

import 'package:pivot/features/tasks/screens/screens.dart';
import 'package:pivot/features/subjects/screens/screens.dart';

import 'package:provider/provider.dart' as legacy_provider;
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/task_provider.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';

import 'package:pivot/providers/section_provider.dart'; // Import SectionProvider
import 'package:pivot/providers/bookmarks.dart'; // Import Bookmarks provider
import 'package:pivot/providers/material_links_provider.dart'; // Import MaterialLinksProvider

import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/features/home/screens/super_admin_panel/analytics_screen.dart'
    deferred as analytics_screen;
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:pivot/services/local_notification_service.dart';
import 'package:pivot/services/permission_service.dart';
import 'dart:async';
import 'package:pivot/features/home/screens/adminstration/add_user_screen.dart'
    deferred as add_user_screen;
import 'package:pivot/features/profile/screens/feedback_screen.dart'
    deferred as feedback_screen;
import 'package:pivot/features/notifications/screens/screens.dart';
import 'package:pivot/features/home/screens/adminstration/feedback_management_screen.dart'
    deferred as feedback_management_screen;
import 'package:pivot/features/settings/screens/screens.dart';
import 'package:pivot/providers/team_provider.dart';
import 'package:pivot/providers/teams_provider.dart';
import 'package:pivot/features/profile/screens/profile/profile_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pivot/services/fcm_token_manager.dart';
import 'package:pivot/services/remote_config_bridge_service.dart';
import 'web_service_worker.dart';
import 'firebase_options.dart';
import 'widgets/platform_service.dart';
import 'widgets/ios_install_instructions_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Route name constants
const String routeUserManagement = '/user-management';
const String routeGlobalSubjectManagement = '/global-subject-management';
const String routeEditProfile = '/edit-profile';
const String routeFeedback = '/feedback';
const String routeAnalytics = '/analytics';
const String routeSectionManagement = '/section-management';
const String routeSuperAdminPanel = '/super-admin-panel';
const String routeFeedbackManagement = '/feedback-management';
const String routeSendNotifications = '/send-notifications';
const String routeAddUser = '/add-user';
const String routeUpdateManagement = '/update-management';

Future<void> _configureFirebaseAuth() async {
  try {
    // Set auth persistence
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

    // Configure auth settings for better error handling
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: kDebugMode,
      forceRecaptchaFlow: false, // Disable reCAPTCHA for testing
    );

    // Clear any existing sessions to prevent credential issues
    if (kDebugMode) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        // Ignore sign out errors
      }
    }
  } catch (e) {
    // Ignore configuration errors in production
    if (kDebugMode) {
      print('Firebase Auth configuration error: $e');
    }
  }
}

Future<void> _initializeAppCheck() async {
  try {
    // Try to initialize App Check to prevent the warning
    // This is optional and won't break the app if it fails
    if (kDebugMode) {
      print('App Check initialization skipped in debug mode');
    }
  } catch (e) {
    // App Check is optional, ignore errors
    if (kDebugMode) {
      print('App Check initialization error (ignored): $e');
    }
  }
}

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

  // Enable Firestore offline persistence for better performance
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Configure Firebase Auth settings
  await _configureFirebaseAuth();

  // Initialize App Check if available
  await _initializeAppCheck();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('ar');

  await CacheService.instance.init();

  final userProfileProvider = UserProfileProvider();

  runApp(
    ProviderScope(
      child: PivotWithNotifications(userProfileProvider: userProfileProvider),
    ),
  );

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
  try {
    await messaging.requestPermission();
  } catch (_) {}
  try {
    await registerServiceWorkerWeb();
  } catch (_) {}
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Optionally handle foreground message
  });
}

void _initializeAppBackgroundServices(
  UserProfileProvider userProfileProvider,
) async {
  if (kIsWeb) {
    _setupFirebaseMessagingWeb().catchError((_) {});
  }

  // Add error handling for Google Play Services
  try {
    await RemoteConfigService.instance.initialize();

    // Initialize Remote Config Bridge Service
    await RemoteConfigBridgeService().initialize();
  } catch (e) {}

  if (FirebaseAuth.instance.currentUser != null) {
    userProfileProvider
        .loadLoggedInUserProfile()
        .timeout(const Duration(seconds: 10))
        .catchError((error) {
          return false;
        });
  }

  try {
    // Initialize local notifications on mobile platforms
    if (!kIsWeb) {
      LocalNotificationService.instance.initialize();
      // Ensure notification permission is requested every launch if not granted
      try {
        await PermissionService.requestNotificationPermission();
      } catch (_) {}
    }

    // Initialize FCM token manager
    FCMTokenManager().initialize().catchError((error) {});

    // final notificationTrigger = NotificationTriggerService();
    // Completely disabled automatic notification sending to prevent test notifications and timeouts
    // notificationTrigger.startBatchProcessing();
    // Timer.periodic(const Duration(minutes: 15), (_) {
    //   notificationTrigger.checkAndSendPeriodicNotifications();
    // });
    // Timer.periodic(const Duration(days: 1), (_) {
    //   notificationTrigger.cleanupOldNotifications();
    // });
  } catch (e) {}

  if (kIsWeb) {
    FirebaseAuth.instance.setPersistence(Persistence.LOCAL).catchError((_) {});
  }
}

// Cached deferred loading futures
final Map<String, Future<void>> _deferredFutures = {};

Future<void> _getCachedDeferredFuture(
  String key,
  Future<void> Function() loader,
) {
  if (!_deferredFutures.containsKey(key)) {
    _deferredFutures[key] = loader();
  }
  return _deferredFutures[key]!;
}

class Pivot extends StatelessWidget {
  const Pivot({super.key, required this.userProfileProvider});
  final UserProfileProvider userProfileProvider;

  @override
  Widget build(BuildContext context) {
    return legacy_provider.MultiProvider(
      providers: [
        legacy_provider.ChangeNotifierProvider(
          create: (_) => AnnouncementProvider(),
        ),
        legacy_provider.ChangeNotifierProvider(
          create: (_) => SectionProvider(),
        ), // Add SectionProvider
        legacy_provider.ChangeNotifierProvider(create: (_) => TaskProvider()),
        legacy_provider.ChangeNotifierProvider(
          create: (_) => ScheduleProvider(),
        ),
        legacy_provider.ChangeNotifierProvider.value(
          value: userProfileProvider,
        ),
        legacy_provider.ChangeNotifierProvider(
          create: (_) => SubjectProvider(),
        ),
        legacy_provider.ChangeNotifierProvider(create: (_) => Bookmarks()),
        legacy_provider.ChangeNotifierProvider(
          create: (_) => DoctorSubjectProvider(),
        ),
        legacy_provider.ChangeNotifierProvider(
          create: (_) => MaterialLinksProvider(),
        ),
        legacy_provider.ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
        legacy_provider.ChangeNotifierProvider(
          create: (_) => SuperAdminProvider(),
        ),
        legacy_provider.ChangeNotifierProvider(create: (_) => GuideProvider()),
        legacy_provider.Provider<RemoteConfigService>(
          create: (_) => RemoteConfigService.instance,
        ),
        legacy_provider.ChangeNotifierProvider(create: (_) => TeamProvider()),
        legacy_provider.ChangeNotifierProvider(create: (_) => TeamsProvider()),
        legacy_provider.ChangeNotifierProvider(
          create:
              (context) => ProfileProvider(
                userProfileProvider: context.read<UserProfileProvider>(),
                scheduleProvider: context.read<ScheduleProvider>(),
                taskProvider: context.read<TaskProvider>(),
                subjectProvider: context.read<SubjectProvider>(),
                sectionProvider: context.read<SectionProvider>(),
              ),
        ),
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
          '/signup-1': (context) => const SignupPage1(),
          '/signup-2': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            if (args == null) {
              // Fallback to first landing if no arguments
              return const FirstLandingScreen();
            }
            return SignupPage2(
              name: args['name'] ?? '',
              email: args['email'] ?? '',
              phone: args['phone'] ?? '',
              password: args['password'] ?? '',
              gender: args['gender'] ?? 'ذكر',
            );
          },
          '/login': (context) => const LoginPage(),
          '/landing': (context) => const Landing(),
          '/profile': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final initialTabIndex = args is int ? args : null;
            return Profile(initialTabIndex: initialTabIndex);
          },
          '/doctor-profile': (context) => const DoctorProfile(),
          '/admin-control': (context) => const AdminControl(),
          '/assistant-profile': (context) => const AssistantProfileMain(),
          '/notification-test': (context) => const NotificationTestWidget(),
          // Deferred and custom routes
          routeUserManagement:
              (context) => FutureBuilder(
                future: _getCachedDeferredFuture(
                  'user_management',
                  user_management_page.loadLibrary,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return user_management_page.UserManagementPage();
                  }
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          routeGlobalSubjectManagement:
              (context) => FutureBuilder(
                future: _getCachedDeferredFuture(
                  'global_subject_management',
                  global_subject_management_screen.loadLibrary,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return global_subject_management_screen.GlobalSubjectManagementScreen();
                  }
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          routeEditProfile:
              (context) => FutureBuilder(
                future: _getCachedDeferredFuture(
                  'edit_profile',
                  edit_profile.loadLibrary,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return edit_profile.EditProfile();
                  }
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          routeFeedback:
              (context) => FutureBuilder(
                future: _getCachedDeferredFuture(
                  'feedback',
                  feedback_screen.loadLibrary,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return feedback_screen.FeedbackScreen();
                  }
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          routeAnalytics:
              (context) => FutureBuilder(
                future: _getCachedDeferredFuture(
                  'analytics',
                  analytics_screen.loadLibrary,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return analytics_screen.AnalyticsScreen();
                  }
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          routeSectionManagement:
              (context) => FutureBuilder(
                future: _getCachedDeferredFuture(
                  'section_management',
                  section_management_screen.loadLibrary,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return section_management_screen.SectionManagementScreen();
                  }
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          routeSuperAdminPanel:
              (context) => FutureBuilder(
                future: _getCachedDeferredFuture(
                  'super_admin_panel',
                  super_admin_panel_screen.loadLibrary,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return super_admin_panel_screen.SuperAdminPanelScreen();
                  }
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          routeFeedbackManagement:
              (context) => FutureBuilder(
                future: _getCachedDeferredFuture(
                  'feedback_management',
                  feedback_management_screen.loadLibrary,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return feedback_management_screen.FeedbackManagementScreen();
                  }
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          routeSendNotifications:
              (context) => FutureBuilder(
                future: _getCachedDeferredFuture(
                  'send_notifications',
                  send_notification_screen.loadLibrary,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return send_notification_screen.SendNotificationScreen();
                  }
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          routeAddUser:
              (context) => FutureBuilder(
                future: _getCachedDeferredFuture(
                  'add_user',
                  add_user_screen.loadLibrary,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return add_user_screen.AddUserScreen();
                  }
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          routeUpdateManagement: (context) => const UpdateManagementScreen(),
          '/teams': (context) => const TeamsScreen(),
          '/subject-selection': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            final previouslySelectedIds =
                args?['previouslySelectedIds'] as List<String>? ?? [];
            return SubjectSelectionScreen(
              previouslySelectedIds: previouslySelectedIds,
            );
          },
          '/tasks-control': (context) {
            return TasksControl(
              key: UniqueKey(),
            ); // sectionId is accessed inside TasksControl
          },
          '/notifications-test': (context) => const NotificationTestWidget(),
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
      NotificationService().initialize(context).catchError((e) {});
    });
    _startPeriodicNotifications();
  }

  void _startPeriodicNotifications() {
    // DISABLED: Automatic notifications to prevent test notifications
    // Initialize automatic notifications on app start
    // NotificationTriggerService().initializeAutomaticNotifications();

    // Run notifications every 15 minutes
    // _notificationTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
    //   try {
    //     NotificationTriggerService().checkAndSendPeriodicNotifications();
    //     NotificationTriggerService().processScheduledNotifications();
    //   } catch (e) {}
    // });

    // Clean up old notifications daily
    // Timer.periodic(const Duration(days: 1), (timer) {
    //   try {
    //     NotificationTriggerService().cleanupOldNotifications();
    //   } catch (e) {}
    // });

    // Test function - remove this in production
    // _testAutomaticNotifications();
  }

  // Test function to manually trigger automatic notifications
  // void _testAutomaticNotifications() {
  //   // Run after 10 seconds to allow app to fully initialize
  //   Timer(const Duration(seconds: 10), () {
  //     NotificationTriggerService().initializeAutomaticNotifications();
  //   });
  // }

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

  // @override
  // void initState() {
  //   super.initState();
  //   // Set up error handling
  //   FlutterError.onError = (FlutterErrorDetails details) {
  //     // Schedule the state update for after the current build frame completes
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (mounted) {
  //         setState(() {
  //           _error = details.exception.toString();
  //         });
  //       }
  //     });
  //   };
  // }
}
