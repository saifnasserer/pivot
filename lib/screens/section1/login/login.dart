import 'package:flutter/material.dart';
import 'package:pivot/screens/section1/login/forgot_password_screen.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/widgets/custom_text_field.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/auth/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../responsive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../services/local_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/permission_service.dart';
import '../../../services/notification_service.dart';
import 'package:pivot/widgets/no_internet_message.dart';

class Login extends ConsumerStatefulWidget {
  const Login({super.key});
  static String id = 'login';
  @override
  ConsumerState<Login> createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // Auth handled via Riverpod provider now
  final LocalAuthService _localAuthService = LocalAuthService();
  final _storage = const FlutterSecureStorage();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _email = '';
  String _password = '';
  bool _isPasswordVisible = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  // Loading comes from Riverpod's AuthState

  @override
  void initState() {
    super.initState();
    _initBiometrics();
    _emailController.addListener(() {
      setState(() {
        _isEmailValid = _validateEmail(_emailController.text) == null;
      });
    });
    _passwordController.addListener(() {
      setState(() {
        _isPasswordValid = _validatePassword(_passwordController.text) == null;
      });
    });
  }

  Future<void> _initBiometrics() async {
    // Biometric initialization for automatic credential saving
    // No UI changes needed since biometric login is handled in first_landing.dart
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Loading handled by Riverpod state

    try {
      final auth = ref.read(authProvider.notifier);
      UserProfile? userProfile = await auth.login(
        _email.toLowerCase().trim(),
        _password,
      );
      if (mounted && userProfile != null) {
        //debugprint('[Login] User profile received: ${userProfile.id}');
        final provider = legacy_provider.Provider.of<UserProfileProvider>(
          context,
          listen: false,
        );
        //debugprint('[Login] Setting logged in user profile...');
        provider.setLoggedInUserProfile(userProfile);
        //debugprint('[Login] Setting user profile...');
        provider.setUserProfile(userProfile);
        //debugprint('[Login] Profile set successfully');

        // Request notification permission after successful login
        await _requestNotificationPermission();

        // Automatically save credentials for biometric login
        await _enableBiometricAutomatically(
          _email.toLowerCase().trim(),
          _password,
        );

        // Navigate to landing screen after successful login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/landing');
        }
      } else {
        // Handle case where login succeeded but no profile was returned
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'فشل في تحميل الملف الشخصي. يرجى المحاولة مرة أخرى.',
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = 'فية مشكلة من فضلك حاول مرة تانية.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = 'الايميل أو الباسورد غلط';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage, textAlign: TextAlign.center),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ غير متوقع: $e', textAlign: TextAlign.center),
          backgroundColor: Colors.red,
        ),
      );
    } finally {}
  }

  Future<void> _enableBiometricAutomatically(
    String email,
    String password,
  ) async {
    if (kIsWeb) return;
    try {
      final isSupported = await _localAuthService.isBiometricSupported();
      if (isSupported) {
        await _storage.write(key: 'biometric_email', value: email);
        await _storage.write(key: 'biometric_password', value: password);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isBiometricEnabled', true);
        //debugprint('Biometrics enabled automatically.');
      }
    } catch (e) {
      //debugprint('Could not enable biometrics automatically: $e');
      // Fail silently, as this is a convenience feature
    }
  }

  // Request notification permission with user-friendly dialog
  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) return; // Notifications not supported on web

    try {
      // Use the new graceful approach from NotificationService
      final notificationService = NotificationService();
      final granted = await notificationService.requestPermissionsExplicitly();

      if (!granted && mounted) {
        // Show dialog to open settings if permission denied
        await PermissionService.requestNotificationPermissionWithRationale(
          context,
        );
      }
    } catch (e) {
      //debugprint('Error requesting notification permission: $e');
    }
  }

  Future<void> authenticateUser() async {
    if (kIsWeb) return;

    try {
      final authResult = await _localAuthService.authenticate('تسجيل الدخول');

      if (authResult.success && mounted) {
        final email = await _storage.read(key: 'biometric_email');
        final password = await _storage.read(key: 'biometric_password');

        if (email != null && password != null) {
          _emailController.text = email;
          _passwordController.text = password;
          _email = email;
          _password = password;
          await _login();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'فية مشكلة في تسجيل الدخول بالبصمة ممكن تجرب يدوي',
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (mounted && authResult.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authResult.errorMessage!,
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل المصادقة.', textAlign: TextAlign.center),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء المصادقة: $e',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return WillPopScope(
      onWillPop: () async {
        // Dismiss keyboard first if it's open
        FocusScope.of(context).unfocus();

        // Wait a bit for keyboard to dismiss
        await Future.delayed(const Duration(milliseconds: 100));

        // Navigate back to first landing instead of closing app
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/first-landing');
        }
        return false;
      },
      child: NoInternetMessage(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  // Dismiss keyboard first if it's open
                  FocusScope.of(context).unfocus();

                  // Wait a bit for keyboard to dismiss, then navigate
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/first-landing');
                    }
                  });
                },
              ),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: Responsive.paddingHorizontal(
                      context,
                      size: Space.xlarge,
                    ),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height:
                                  Responsive.space(
                                    context,
                                    size: Space.xlarge,
                                  ) *
                                  2,
                            ),
                            Padding(
                              padding: Responsive.paddingVertical(
                                context,
                                size: Space.small,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    hint: 'البريد الإلكتروني',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _validateEmail,
                                    isValid: _isEmailValid,
                                    onChanged: (value) => _email = value,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: Responsive.paddingVertical(
                                context,
                                size: Space.small,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    hint: 'الباسورد',
                                    validator: _validatePassword,
                                    obscureText: !_isPasswordVisible,
                                    isValid: _isPasswordValid,
                                    onChanged: (value) => _password = value,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: Responsive.text(
                                          context,
                                          size: TextSize.medium,
                                        ),
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (authState.error != null)
                              Padding(
                                padding: Responsive.paddingVertical(
                                  context,
                                  size: Space.small,
                                ),
                                child: Text(
                                  authState.error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: Responsive.paddingVertical(
                                context,
                                size: Space.small,
                              ),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'نسيت الباسورد ؟',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height:
                                  Responsive.space(
                                    context,
                                    size: Space.xlarge,
                                  ) *
                                  2,
                            ),
                            authState.isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : CircularButton(
                                  onPressed: _login,
                                  icon: Icons.check,
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
