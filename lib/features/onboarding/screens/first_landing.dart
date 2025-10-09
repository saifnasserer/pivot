import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:pivot/services/local_auth_service.dart';
import 'package:pivot/services/introduction_service.dart';
import 'package:pivot/widgets/no_internet_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../responsive.dart';

class FirstLandingScreen extends ConsumerStatefulWidget {
  const FirstLandingScreen({super.key});
  // = 'first_landing_screen';

  @override
  ConsumerState<FirstLandingScreen> createState() => _FirstLandingScreenState();
}

class _FirstLandingScreenState extends ConsumerState<FirstLandingScreen> {
  final AuthService _authService = AuthService();
  final LocalAuthService _localAuthService = LocalAuthService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _debugBiometricStatus(); // Add debug method call
  }

  /// Debug method to check biometric status on app start
  Future<void> _debugBiometricStatus() async {
    if (kDebugMode) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final isEnabled = prefs.getBool('isBiometricEnabled') ?? false;
        final isSupported = await _localAuthService.isBiometricSupported();
        final isEnrolled = await _localAuthService.isBiometricEnrolled();
        final credentials = await _storage.read(key: 'biometric_email');

        print('🔐 [BiometricDebug] Initial biometric status:');
        print('   🔧 Enabled: $isEnabled');
        print('   📱 Supported: $isSupported');
        print('   ✅ Enrolled: $isEnrolled');
        print('   📧 Has credentials: ${credentials != null}');
      } catch (e) {
        print('🔐 [BiometricDebug] Error checking biometric status: $e');
      }
    }
  }

  Future<void> _checkAuthState() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        UserProfile? userProfile = await _authService.getUserProfile(user.uid);
        if (mounted && userProfile != null) {
          ref.read(userProfileProvider.notifier).setUserProfile(userProfile);

          // Let AuthWrapper handle navigation automatically
          // This ensures consistent navigation flow and prevents conflicts
          return; // Exit after setting profile
        }
      } catch (e) {
        // Handle error fetching profile, sign out to be safe
        await _authService.signOut();
      }
    }
    // If user is null or profile fetch failed, show the login/signup page
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_isLoggingIn) return;

    setState(() {
      _isLoggingIn = true;
    });

    try {
      if (kIsWeb) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Check if credentials are stored (biometric is enabled by default on first login)
      final storedEmail = await _storage.read(key: 'biometric_email');
      final storedPassword = await _storage.read(key: 'biometric_password');
      final hasStoredCredentials =
          storedEmail != null && storedPassword != null;

      // Check if biometric is explicitly disabled by user
      final prefs = await SharedPreferences.getInstance();
      final isBiometricDisabled = prefs.getBool('isBiometricEnabled') == false;

      print('🔐 [BiometricLogin] Checking biometric availability...');
      print('   💾 Has stored credentials: $hasStoredCredentials');
      print('   🔧 Explicitly disabled by user: $isBiometricDisabled');

      // If credentials exist and biometric is not disabled, try biometric auth
      if (hasStoredCredentials && !isBiometricDisabled) {
        final isSupported = await _localAuthService.isBiometricSupported();
        final isEnrolled = await _localAuthService.isBiometricEnrolled();

        print('   📱 Device supports biometric: $isSupported');
        print('   ✅ Biometric enrolled on device: $isEnrolled');

        if (isSupported && isEnrolled) {
          print('🔐 [BiometricLogin] Attempting biometric authentication...');

          final authResult = await _localAuthService.authenticate('ابصم يباشا');

          if (authResult.success) {
            print('🔐 [BiometricLogin] Biometric authentication successful!');
            print('🔐 [BiometricLogin] Signing in with stored credentials...');

            UserProfile? userProfile = await _authService
                .signInWithEmailAndPassword(storedEmail, storedPassword);

            if (mounted && userProfile != null) {
              print(
                '🔐 [BiometricLogin] Login successful, navigating to landing...',
              );

              ref
                  .read(userProfileProvider.notifier)
                  .setLoggedInUserProfile(userProfile);
              ref
                  .read(userProfileProvider.notifier)
                  .setUserProfile(userProfile);

              if (mounted) {
                Navigator.pushReplacementNamed(context, '/landing');
              }
              return; // Exit after successful login
            } else if (mounted) {
              print('❌ [BiometricLogin] Failed to load user profile');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'فشل تسجيل الدخول بالبصمة. الرجاء تسجيل الدخول يدويًا.',
                  ),
                ),
              );
            }
          } else if (mounted && authResult.errorMessage != null) {
            print(
              '🔐 [BiometricLogin] Authentication failed: ${authResult.errorMessage}',
            );
            // User can try manual login
          } else {
            print('🔐 [BiometricLogin] Authentication cancelled by user');
          }
        } else {
          if (!isSupported) {
            print('📱 [BiometricLogin] Device does not support biometrics');
          }
          if (!isEnrolled) {
            print(
              '📱 [BiometricLogin] No fingerprints/face enrolled on device',
            );
          }
        }
      } else {
        if (!hasStoredCredentials) {
          print(
            '📦 [BiometricLogin] No credentials stored - first time login required',
          );
        }
        if (isBiometricDisabled) {
          print('🔧 [BiometricLogin] Biometric disabled by user in settings');
        }
      }

      // Fallback to manual login screen
      if (mounted) {
        print('🔐 [BiometricLogin] Navigating to manual login screen...');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('❌ [BiometricLogin] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في المصادقة: $e')));
        Navigator.pushReplacementNamed(context, '/login');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xff161616),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: NoInternetMessage(
        child: Scaffold(
          body: Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xff161616),
              image: DecorationImage(
                image: AssetImage('assets/images/Group 113.png'),
                opacity: 0.15,
                scale: 1.2,
              ),
            ),
            child: Padding(
              padding: Responsive.paddingHorizontal(
                context,
                size: Space.medium,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Debug button (only in debug mode)
                  if (kDebugMode)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: Responsive.space(context, size: Space.large),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          tooltip: 'إعادة تعيين الشاشة التعريفية',
                          onPressed: () async {
                            await IntroductionService.resetIntroduction();
                            if (mounted) {
                              Navigator.pushReplacementNamed(
                                context,
                                '/introduction-wrapper',
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            textAlign: TextAlign.right,
                            '! ... واخيراً',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  Responsive.text(
                                    context,
                                    size: TextSize.heading,
                                  ) *
                                  1.5,
                            ),
                          ),
                          Text(
                            textAlign: TextAlign.right,
                            'حياة جامعية منظمة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  Responsive.text(
                                    context,
                                    size: TextSize.heading,
                                  ) *
                                  2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.space(
                              context,
                              size: Space.large,
                            ),
                            vertical: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/signup-1');
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                              size: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                            ),
                            Text(
                              ' حساب جديد',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.medium),
                      ),
                      TextButton(
                        onPressed: _isLoggingIn ? null : _handleLogin,
                        child:
                            _isLoggingIn
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                    ),
                                    Text(
                                      ' تسجيل الدخول',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: Responsive.text(
                                          context,
                                          size: TextSize.medium,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.xlarge),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
