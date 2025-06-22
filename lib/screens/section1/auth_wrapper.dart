import 'dart:async';

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section1/first_landing.dart';

import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:pivot/responsive.dart';

enum AuthStatus { checking, authenticated, unauthenticated, error }

class AuthWrapper extends StatefulWidget {
  static const String id = 'auth_wrapper';
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthStatus _status = AuthStatus.checking;
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;
  String? _errorMessage;
  bool _isInitialized = false;
  Timer? _periodicCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializeAuth();

    // Add a timeout to prevent infinite loading (reduced from 30s to 10s)
    Timer(const Duration(seconds: 10), () {
      if (mounted && _status == AuthStatus.checking && _isInitialized) {
        debugPrint(
          '[AuthWrapper] Initialization timeout reached, showing error',
        );
        setState(() {
          _status = AuthStatus.error;
          _errorMessage = 'انتهت مهلة التحميل. يرجى إعادة تشغيل التطبيق.';
        });
      }
    });

    // Add periodic check for auth state (every 2 seconds)
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isInitialized) {
        final currentUser = _authService.getCurrentUser();
        if (currentUser != null && _status == AuthStatus.unauthenticated) {
          debugPrint(
            '[AuthWrapper] Periodic check found authenticated user: ${currentUser.uid}',
          );
          _handleAuthState(currentUser);
        } else if (currentUser == null && _status == AuthStatus.authenticated) {
          debugPrint(
            '[AuthWrapper] Periodic check found no user, setting unauthenticated',
          );
          _handleAuthState(null);
        }
      }
    });
  }

  Future<void> _initializeAuth() async {
    try {
      // Remove the unnecessary delay - Firebase is already initialized in main()
      if (!mounted) return;

      // Check current user immediately
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        debugPrint(
          '[AuthWrapper] Current user found during initialization: ${currentUser.uid}',
        );
        await _handleAuthState(currentUser);
      }

      // Add timeout for auth subscription (reduced timeout)
      _authSubscription = _authService.authStateChanges.listen(
        _handleAuthState,
        onError: (error) {
          debugPrint('[AuthWrapper] Auth stream error: $error');
          if (mounted) {
            setState(() {
              _status = AuthStatus.error;
              _errorMessage =
                  'فشل في الاتصال بخدمة المصادقة. يرجى إعادة تشغيل التطبيق.';
            });
          }
        },
      );
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('[AuthWrapper] Error initializing auth: $e');
      if (mounted) {
        setState(() {
          _status = AuthStatus.error;
          _errorMessage = 'فشل في تهيئة التطبيق. يرجى إعادة تشغيل التطبيق.';
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleAuthState(User? user) async {
    debugPrint('[AuthWrapper] Auth state changed. User: ${user?.uid}');

    if (!mounted) return;

    // Check auth status from stream
    if (user == null) {
      debugPrint(
        '[AuthWrapper] User is null. Setting state to unauthenticated.',
      );
      try {
        Provider.of<UserProfileProvider>(context, listen: false).clearProfile();
      } catch (e) {
        debugPrint('[AuthWrapper] Error clearing profile: $e');
      }
      if (mounted) {
        setState(() => _status = AuthStatus.unauthenticated);
      }
      return;
    }

    debugPrint('[AuthWrapper] User is authenticated: ${user.uid}');

    // Check if profile is already loaded (from login/signup flow)
    try {
      final provider = Provider.of<UserProfileProvider>(context, listen: false);

      debugPrint('[AuthWrapper] Checking if profile is already loaded...');
      debugPrint(
        '[AuthWrapper] Current profile: ${provider.loggedInUserProfile?.id}',
      );
      debugPrint('[AuthWrapper] Expected profile: ${user.uid}');

      // First check if profile is already loaded and matches current user
      if (provider.loggedInUserProfile != null &&
          provider.loggedInUserProfile!.id == user.uid) {
        debugPrint(
          '[AuthWrapper] Profile already loaded. Setting state to authenticated.',
        );
        if (mounted) {
          setState(() => _status = AuthStatus.authenticated);
        }
        return;
      }

      debugPrint('[AuthWrapper] Profile not found immediately, waiting...');

      // Add a small delay to allow for profile to be set by login/signup flow
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('[AuthWrapper] After delay - checking profile again...');
      debugPrint(
        '[AuthWrapper] Current profile: ${provider.loggedInUserProfile?.id}',
      );

      // Check again after delay (in case profile was set during login)
      if (provider.loggedInUserProfile != null &&
          provider.loggedInUserProfile!.id == user.uid) {
        debugPrint(
          '[AuthWrapper] Profile found after delay. Setting state to authenticated.',
        );
        if (mounted) {
          setState(() => _status = AuthStatus.authenticated);
        }
        return;
      }

      debugPrint(
        '[AuthWrapper] Profile still not found, trying to load from Firestore...',
      );

      // Only try to load from Firestore if no profile is set (for app startup)
      final bool profileLoaded = await provider
          .loadLoggedInUserProfile()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('[AuthWrapper] Profile loading timed out');
              return false;
            },
          );

      if (!mounted) return;

      if (profileLoaded) {
        debugPrint(
          '[AuthWrapper] Profile loaded successfully from Firestore. Setting state to authenticated.',
        );
        if (mounted) {
          setState(() => _status = AuthStatus.authenticated);
        }
      } else {
        debugPrint(
          '[AuthWrapper] Profile loading failed. User may not have a profile yet.',
        );
        // Don't sign out immediately, just show error state
        if (mounted) {
          setState(() {
            _status = AuthStatus.error;
            _errorMessage = 'فشل تحميل الملف الشخصي. تأكد من وجود حساب صحيح.';
          });
        }
      }
    } catch (e) {
      debugPrint('[AuthWrapper] Error during profile loading: $e');
      if (mounted) {
        setState(() {
          _status = AuthStatus.error;
          _errorMessage =
              'حدث خطأ أثناء تحميل الملف الشخصي. يرجى المحاولة مرة أخرى.';
        });
      }
    }
  }

  void _retryAuth() {
    setState(() {
      _status = AuthStatus.checking;
      _errorMessage = null;
    });
    // Re-subscribe to auth state (simulate a fresh start)
    _authSubscription?.cancel();
    _initializeAuth();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while initializing
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.black),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'جاري تحميل التطبيق...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use Consumer to listen to UserProfileProvider changes
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        debugPrint(
          '[AuthWrapper] Consumer called - Status: $_status, Profile: ${userProfileProvider.loggedInUserProfile?.id}',
        );

        // Check if we have a logged-in user but are still in checking state
        if (_status == AuthStatus.checking &&
            userProfileProvider.loggedInUserProfile != null) {
          final currentUser = _authService.getCurrentUser();
          debugPrint(
            '[AuthWrapper] Checking profile match - Current user: ${currentUser?.uid}, Profile: ${userProfileProvider.loggedInUserProfile!.id}',
          );
          if (currentUser != null &&
              currentUser.uid == userProfileProvider.loggedInUserProfile!.id) {
            debugPrint(
              '[AuthWrapper] Consumer detected profile change, setting authenticated state',
            );
            // Use a post-frame callback to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _status = AuthStatus.authenticated);
              }
            });
          }
        }

        switch (_status) {
          case AuthStatus.checking:
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.black),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'جاري التحقق من الحساب...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                  ],
                ),
              ),
            );

          case AuthStatus.authenticated:
            // Use a Consumer to ensure the Landing screen is only built after
            // the UserProfileProvider has been updated and has a valid profile.
            if (userProfileProvider.loggedInUserProfile == null) {
              // This state should be brief, show a loading indicator.
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.black),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      Text(
                        'جاري تحميل الملف الشخصي...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Landing();

          case AuthStatus.unauthenticated:
            return const FirstLandingScreen();

          case AuthStatus.error:
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Padding(
                  padding: Responsive.paddingHorizontal(
                    context,
                    size: Space.large,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      Text(
                        _errorMessage ?? 'حدث خطأ غير متوقع',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),
                      ElevatedButton(
                        onPressed: _retryAuth,
                        child: Text(
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
      },
    );
  }
}
