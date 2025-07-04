import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section1/login/forgot_password_screen.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../responsive.dart';
import '../../../services/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../services/local_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/permission_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  static String id = 'login';
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();
  final LocalAuthService _localAuthService = LocalAuthService();
  final _storage = const FlutterSecureStorage();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _email = '';
  String _password = '';
  bool _isPasswordVisible = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isBiometricAvailable = false;
  bool _isLoading = false;

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
    if (!kIsWeb) {
      final isAvailable = await _localAuthService.isBiometricSupported();
      final prefs = await SharedPreferences.getInstance();
      final isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable && isBiometricEnabled;
        });
      }
    }
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

    setState(() {
      _isLoading = true;
    });

    try {
      UserProfile? userProfile = await _authService.signInWithEmailAndPassword(
        _email.toLowerCase().trim(),
        _password,
      );
      if (mounted && userProfile != null) {
        //debugprint('[Login] User profile received: ${userProfile.id}');
        final provider = Provider.of<UserProfileProvider>(
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

        // Add a small delay to ensure AuthWrapper can detect the profile
        //debugprint('[Login] Waiting for AuthWrapper to detect profile...');
        await Future.delayed(const Duration(milliseconds: 100));
        //debugprint(
        // '[Login] Login process completed, waiting for navigation...',
        // );

        // Force AuthWrapper to check current user state
        final authService = AuthService();
        final currentUser = authService.getCurrentUser();
        if (currentUser != null) {
          //debugprint('[Login] Current user confirmed: ${currentUser.uid}');

          // Add a short delay then navigate directly
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              //debugprint('[Login] Navigating to Landing screen');
              Navigator.pushReplacementNamed(context, Landing.id);
            }
          });
        }

        // Don't navigate directly to Landing - let AuthWrapper handle it
        // The AuthWrapper will detect the authenticated state and navigate automatically
        // This prevents conflicts between direct navigation and AuthWrapper's auth state handling
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        if (mounted) {
          setState(() {
            _isBiometricAvailable = true;
          });
        }
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
      // Use existing static method from PermissionService
      bool granted = await PermissionService.requestStoragePermission();

      if (!granted && mounted) {
        // Show dialog to open settings if permission denied
        await PermissionService.requestStoragePermissionWithRationale(context);
      }
    } catch (e) {
      //debugprint('Error requesting notification permission: $e');
    }
  }

  Future<void> authenticateUser() async {
    if (kIsWeb) return;

    try {
      final bool didAuthenticate = await _localAuthService.authenticate(
        'تسجيل الدخول',
      );

      if (didAuthenticate && mounted) {
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
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, FirstLandingScreen.id);
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
                              Responsive.space(context, size: Space.xlarge) * 2,
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
                                hint: 'الايميل الجامعي',
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
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ],
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
                                  builder: (context) => ForgotPasswordScreen(),
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
                              Responsive.space(context, size: Space.xlarge) * 2,
                        ),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
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
    );
  }
}
