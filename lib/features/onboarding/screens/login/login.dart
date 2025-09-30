import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pivot/features/onboarding/screens/login/forgot_password_screen.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/widgets/custom_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/auth/providers/auth_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import '../../../../responsive.dart';
import 'dart:developer' as developer;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final userProfile = await authNotifier.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (userProfile != null && mounted) {
        // Set the user profile using Riverpod
        ref
            .read(userProfileProvider.notifier)
            .setLoggedInUserProfile(userProfile);
        ref.read(userProfileProvider.notifier).setUserProfile(userProfile);

        // Navigate to landing page
        Navigator.pushReplacementNamed(context, '/landing');
      }
    } on FirebaseAuthException catch (e) {
      // Log full error to console for debugging
      developer.log(
        'Firebase Auth Error during login',
        error: e,
        name: 'LoginPage',
      );
      developer.log('Error code: ${e.code}', name: 'LoginPage');
      developer.log('Error message: ${e.message}', name: 'LoginPage');

      // Show user-friendly error in UI
      if (mounted) {
        String userFriendlyError = 'فشل في تسجيل الدخول';

        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            userFriendlyError = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
            break;
          case 'user-disabled':
            userFriendlyError = 'تم تعطيل هذا الحساب';
            break;
          case 'too-many-requests':
            userFriendlyError = 'محاولات كثيرة جداً، حاول مرة أخرى لاحقاً';
            break;
          case 'network-request-failed':
            userFriendlyError = 'تحقق من اتصالك بالإنترنت';
            break;
        }

        setState(() {
          _errorMessage = userFriendlyError;
        });
      }
    } catch (e) {
      // Log full error to console for debugging
      developer.log(
        'Unexpected error during login',
        error: e,
        stackTrace: StackTrace.current,
        name: 'LoginPage',
      );

      // Show generic error in UI
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      'اهلاً بيك مرة تانية',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.heading,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(
                      height: Responsive.space(context, size: Space.large) * 2,
                    ),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      hint: 'البريد الإلكتروني',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال البريد الإلكتروني';
                        }
                        if (!value.contains('@')) {
                          return 'يرجى إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      hint: 'كلمة المرور',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    // Forgot Password Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup-1');
                          },
                          child: Text(
                            'إنشاء حساب جديد',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'نسيت الباسورد؟',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.medium),
                        ),
                        margin: EdgeInsets.only(
                          bottom: Responsive.space(context, size: Space.medium),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Login Button
                    _isLoading
                        ? Container(
                          width:
                              Responsive.space(context, size: Space.xlarge) * 4,
                          height:
                              Responsive.space(context, size: Space.xlarge) * 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black87,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                        : CircularButton(
                          onPressed: _handleLogin,
                          icon: Icons.check,
                          backgroundColor: Colors.black87,
                          iconColor: Colors.white,
                          elevation: 0,
                          iconSizeMultiplier: 1.5,
                          sizeMultiplier: 4,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
