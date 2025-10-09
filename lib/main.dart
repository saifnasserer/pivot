import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Legacy provider imports removed - now using Riverpod
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
import 'package:pivot/features/onboarding/screens/terms_of_service_screen.dart';
import 'package:pivot/features/onboarding/screens/community_guidelines_screen.dart';
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/features/home/screens/super_admin_panel/analytics_screen.dart'
    deferred as analytics_screen;
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:pivot/services/local_notification_service.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/services/session_persistence_service.dart';
import 'package:pivot/services/offline_queue_service.dart';
import 'package:pivot/services/sync_manager.dart';
import 'package:pivot/services/notification_controller.dart';
import 'dart:async';
import 'package:pivot/features/home/screens/adminstration/add_user_screen.dart'
    deferred as add_user_screen;
import 'package:pivot/features/profile/screens/feedback_screen.dart'
    deferred as feedback_screen;
import 'package:pivot/features/notifications/screens/screens.dart';
import 'package:pivot/features/home/screens/adminstration/feedback_management_screen.dart'
    deferred as feedback_management_screen;
import 'package:pivot/features/settings/screens/screens.dart';
// Legacy provider imports removed - now using Riverpod
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pivot/services/fcm_token_manager.dart';
import 'web_service_worker.dart';
import 'firebase_options.dart';
import 'widgets/platform_service.dart';
import 'widgets/ios_install_instructions_screen.dart';
import 'widgets/android_landing_screen.dart';
import 'package:flutter/foundation.dart';
// Import the background handler (platform-specific)
import 'package:pivot/services/notification_service.dart' as notif_service;

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

  // Early check for iOS/Android web - show landing screen immediately without initialization
  if (kIsWeb) {
    // Check if user explicitly wants to skip platform check (from "Continue on Web" button)
    final skipPlatformCheck =
        Uri.base.queryParameters['skip_platform_check'] == 'true';

    if (!skipPlatformCheck) {
      // Check platform early to avoid unnecessary initialization
      if (PlatformService.isIOSWeb()) {
        runApp(
          const MaterialApp(
            home: IOSInstallInstructionsScreen(),
            debugShowCheckedModeBanner: false,
          ),
        );
        return; // Exit early, no need for Firebase initialization
      } else if (PlatformService.isAndroidWeb()) {
        runApp(
          const MaterialApp(
            home: AndroidLandingScreen(),
            debugShowCheckedModeBanner: false,
          ),
        );
        return; // Exit early, no need for Firebase initialization
      }
    }

    // For other web platforms (desktop) or skip_platform_check=true, show loading indicator
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

  // Register FCM background message handler (must be called before runApp)
  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(
        notif_service.firebaseMessagingBackgroundHandler,
      );
      print('✅ FCM background handler registered');
    } catch (e) {
      print('❌ Error registering FCM background handler: $e');
    }
  }

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

  // Initialize cache service for offline data storage
  await CacheService.instance.init();

  // Initialize offline service for connectivity monitoring
  print('🔌 Initializing OfflineService...');
  await OfflineService().initialize();

  // Initialize offline queue service for syncing operations
  print('📦 Initializing OfflineQueueService...');
  await OfflineQueueService().init();

  // Clean up old queued operations (older than 7 days)
  await OfflineQueueService().clearOldOperations(7);

  // Check and clear expired sessions
  print('🔐 Checking session persistence...');
  await SessionPersistenceService().clearExpiredSession();

  runApp(const ProviderScope(child: PivotWithNotifications()));

  if (kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppBackgroundServices();
    });
  } else {
    _initializeAppBackgroundServices();
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

void _initializeAppBackgroundServices() async {
  if (kIsWeb) {
    _setupFirebaseMessagingWeb().catchError((_) {});
  }

  // Add error handling for Google Play Services
  try {
    await RemoteConfigService.instance.initialize();
  } catch (e) {}

  // User profile initialization is handled by AuthWrapper using Riverpod
  // The AuthWrapper checks for authenticated users and loads profiles automatically
  // via ref.read(userProfileProvider.notifier).loadLoggedInUserProfile()

  try {
    // Initialize local notifications on mobile platforms
    if (!kIsWeb) {
      print('🔔 Initializing local notification service...');
      try {
        await LocalNotificationService.instance.initialize();
        print('✅ Local notification service initialized');
      } catch (e) {
        print(
          '❌ CRITICAL: Local notification service failed to initialize: $e',
        );
      }

      // Initialize notification controller and listeners
      print('🔔 Initializing notification controller...');
      try {
        await NotificationController.initialize();
        print('✅ Notification controller initialized');
      } catch (e) {
        print('❌ CRITICAL: Notification controller failed to initialize: $e');
      }

      // Ensure notification permission is requested every launch if not granted
      print('🔔 Requesting notification permissions...');
      try {
        await PermissionService.requestNotificationPermission();
        print('✅ Notification permissions requested');
      } catch (e) {
        print('⚠️ Could not request notification permissions: $e');
      }
    }

    // Initialize FCM token manager
    print('🔔 Initializing FCM token manager...');
    try {
      await FCMTokenManager().initialize();
      print('✅ FCM token manager initialized');
    } catch (error) {
      print('❌ FCM token manager initialization error: $error');
    }

    // final notificationTrigger = NotificationTriggerService();
    // Completely disabled automatic notification sending to prevent test notifications and timeouts
    // notificationTrigger.startBatchProcessing();
    // Timer.periodic(const Duration(minutes: 15), (_) {
    //   notificationTrigger.checkAndSendPeriodicNotifications();
    // });
    // Timer.periodic(const Duration(days: 1), (_) {
    //   notificationTrigger.cleanupOldNotifications();
    // });
  } catch (e) {
    print('❌ Error in background services initialization: $e');
  }

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
  const Pivot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return MaterialApp(
          navigatorKey: NotificationController.navigatorKey,
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
              // Check if user wants to skip platform check (from "Continue on Web")
              (kIsWeb &&
                      Uri.base.queryParameters['skip_platform_check'] == 'true')
                  ? const AuthWrapper()
                  : PlatformService.isIOSWeb()
                  ? const IOSInstallInstructionsScreen()
                  : PlatformService.isAndroidWeb()
                  ? const AndroidLandingScreen()
                  : const AuthWrapper(),
          routes: {
            '/ios-install-instructions':
                (context) => const IOSInstallInstructionsScreen(),
            '/android-landing': (context) => const AndroidLandingScreen(),
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
            '/terms-of-service': (context) => const TermsOfServiceScreen(),
            '/community-guidelines':
                (context) => const CommunityGuidelinesScreen(),
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
              return SubjectSelectionScreenWithProviders(
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
        );
      },
    );
  }
}

// Add a ConsumerStatefulWidget wrapper to handle periodic notifications and sync
class PivotWithNotifications extends ConsumerStatefulWidget {
  const PivotWithNotifications({super.key});

  @override
  ConsumerState<PivotWithNotifications> createState() =>
      _PivotWithNotificationsState();
}

class _PivotWithNotificationsState
    extends ConsumerState<PivotWithNotifications> {
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();

      // Initialize SyncManager for automatic offline queue syncing
      try {
        ref.read(syncManagerProvider);
        print('✅ SyncManager initialized via provider');
      } catch (e) {
        print('⚠️ SyncManager initialization error: $e');
      }
    });
    _startPeriodicNotifications();
  }

  Future<void> _initializeNotifications() async {
    print('🔔 Starting notification service initialization...');

    try {
      await NotificationService().initialize(context);
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ CRITICAL: NotificationService initialization failed: $e');

      // Show user-friendly error if in context
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تفعيل الإشعارات. قد لا تستقبل التذكيرات.'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'حسناً',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
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
      child: ErrorBoundary(child: const Pivot()),
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
