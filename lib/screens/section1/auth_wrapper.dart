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
  }

  Future<void> _initializeAuth() async {
    try {
      // Remove the unnecessary delay - Firebase is already initialized in main()
      if (!mounted) return;

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

    // Check if profile is already loaded (from main.dart)
    try {
      final provider = Provider.of<UserProfileProvider>(context, listen: false);
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

      // If not loaded, fetch it (for fresh logins) - reduced timeout to 5s
      debugPrint('[AuthWrapper] Profile not loaded. Loading profile...');
      final bool profileLoaded = await provider
          .loadLoggedInUserProfile()
          .timeout(
            const Duration(seconds: 5), // Reduced from 15s to 5s
            onTimeout: () {
              debugPrint('[AuthWrapper] Profile loading timed out');
              return false;
            },
          );

      if (!mounted) return;

      if (profileLoaded) {
        debugPrint(
          '[AuthWrapper] Profile loaded successfully. Setting state to authenticated.',
        );
        if (mounted) {
          setState(() => _status = AuthStatus.authenticated);
        }
      } else {
        debugPrint(
          '[AuthWrapper] Profile loading failed or timed out. Signing out.',
        );
        try {
          await _authService.signOut();
        } catch (signOutError) {
          debugPrint('[AuthWrapper] Error signing out: $signOutError');
        }
        if (mounted) {
          setState(() {
            _status = AuthStatus.error;
            _errorMessage =
                'فشل تحميل الملف الشخصي أو انتهت المهلة. تحقق من اتصالك بالإنترنت أو حاول مرة أخرى.';
          });
        }
      }
    } catch (e) {
      debugPrint(
        '[AuthWrapper] Error during profile loading: $e. Signing out.',
      );
      try {
        await _authService.signOut();
      } catch (signOutError) {
        debugPrint('[AuthWrapper] Error signing out: $signOutError');
      }
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

    switch (_status) {
      case AuthStatus.checking:
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.black),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
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
        return Consumer<UserProfileProvider>(
          builder: (context, userProfileProvider, child) {
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
          },
        );
      case AuthStatus.unauthenticated:
        return const FirstLandingScreen();
      case AuthStatus.error:
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
                    _errorMessage ?? 'حدث خطأ غير متوقع.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _retryAuth,
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
  }
}
