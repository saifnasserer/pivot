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
  }

  Future<void> _initializeAuth() async {
    try {
      // Add a small delay to ensure Firebase is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      _authSubscription = _authService.authStateChanges.listen(
        _handleAuthState,
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

      // If not loaded, fetch it (for fresh logins)
      debugPrint('[AuthWrapper] Profile not loaded. Loading profile...');
      // Add a timeout (e.g., 15 seconds)
      final bool profileLoaded = await provider
          .loadLoggedInUserProfile()
          .timeout(
            const Duration(seconds: 15),
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
        await _authService.signOut();
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
