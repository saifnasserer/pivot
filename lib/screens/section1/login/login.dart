import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
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

    try {
      UserProfile? userProfile = await _authService.signInWithEmailAndPassword(
          _email.toLowerCase().trim(), _password);
      if (mounted && userProfile != null) {
        final provider =
            Provider.of<UserProfileProvider>(context, listen: false);
        provider.setLoggedInUserProfile(userProfile);
        provider.setUserProfile(userProfile);

        await _promptEnableBiometric(
          _email.toLowerCase().trim(),
          _password,
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          Landing.id,
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          errorMessage = 'اما فية غلط في البيانات او المستخدم غير مسجل';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة المرور غير صحيحة.';
          break;
        case 'invalid-email':
          errorMessage = 'البريد الإلكتروني غير صالح.';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا المستخدم.';
          break;
        default:
          errorMessage = 'حدث خطأ غير متوقع. حاول مرة أخرى.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.text(context) * .9,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _promptEnableBiometric(
    String email,
    String password,
  ) async {
    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    final isBiometricSupported = await _localAuthService.isBiometricSupported();
    final isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;

    if (isBiometricSupported && !isBiometricEnabled) {
      final bool wantsToEnable = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Enable Biometric Login'),
              content: const Text(
                  'Would you like to enable biometric login for faster access?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          ) ??
          false;

      if (wantsToEnable) {
        await _storage.write(key: 'biometric_email', value: email);
        await _storage.write(key: 'biometric_password', value: password);
        await prefs.setBool('isBiometricEnabled', true);
        if (mounted) {
          setState(() {
            _isBiometricAvailable = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric login enabled.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> authenticateUser() async {
    if (kIsWeb) return;

    try {
      final bool didAuthenticate = await _localAuthService.authenticate(
        'Please authenticate to log in',
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
                  'Biometric credentials not found. Please log in manually.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred during authentication: $e'),
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
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: Responsive.paddingHorizontal(context, size: Space.xlarge),
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
                          height: Responsive.space(context, size: Space.xlarge) *
                              2,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'البريد الإلكتروني',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              CustomTextField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                hint: 'ادخل بريدك الإلكتروني',
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                isValid: _isEmailValid,
                                onChanged: (value) => _email = value,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'كلمة المرور',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              CustomTextField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                hint: 'ادخل كلمة المرور',
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
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ForgotPasswordScreen(),
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
                              Responsive.space(context, size: Space.xlarge) *
                                  2,
                        ),
                        CircularButton(
                          onPressed: _login,
                          icon: Icons.check,
                        ),
                        if (_isBiometricAvailable)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: ElevatedButton.icon(
                              onPressed: authenticateUser,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Login using Biometric'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.grey.shade200,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
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
