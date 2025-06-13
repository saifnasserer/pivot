import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/models/user_profile.dart';
// import 'package:pivot/models/user_profile.dart';
// import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
// import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import '../../../responsive.dart';
import '../../../services/auth_service.dart';

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

  // Add an instance of AuthService
  final AuthService _authService = AuthService();

  String _email = '';
  String _password = '';

  bool _isPasswordVisible = false;

  bool _isEmailValid = false;

  bool _isPasswordValid = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        UserProfile? userProfile = await _authService
            .signInWithEmailAndPassword(_email, _password);
        if (userProfile != null) {
          // Login successful, navigate to landing page
          Navigator.pushNamedAndRemoveUntil(
            context,
            Landing.id,
            (route) => false,
          );
        } else {
          // Login failed, show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'اما فية غلط في البيانات او المستخدم غير مسجل',
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
        // Handle any exceptions during login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    if (!value.endsWith('fci.bu.edu.eg')) {
      return 'لازم يكون ايميل كلية حاسبات';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value.length < 8) {
      return 'الباسورد علي الاقل 8 حروف';
    }
    return null;
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Align(
              alignment: Alignment.center,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: Responsive.paddingHorizontal(
                          context,
                          size: Space.xlarge,
                        ),
                        child: Column(
                          // crossAxisAlignment: CrossAxisAlignment.center,
                          // mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.xlarge,
                              ),
                            ),
                            Text(
                              'تسجيل الدخول',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.xlarge,
                              ),
                            ),
                            CustomTextField(
                              focusNode: _emailFocus,
                              hint: 'الايميل الجامعي',
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              isValid: _isEmailValid,
                              onEditingComplete: () {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_passwordFocus);
                              },
                              onChanged: (value) {
                                setState(() {
                                  _isEmailValid = _validateEmail(value) == null;
                                  if (_isEmailValid) _email = value;
                                });
                              },
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            CustomTextField(
                              focusNode: _passwordFocus,
                              hint: 'الباسورد',
                              validator: _validatePassword,
                              textInputAction: TextInputAction.done,
                              obscureText: !_isPasswordVisible,
                              isValid: _isPasswordValid,
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
                              onChanged: (value) {
                                setState(() {
                                  _isPasswordValid =
                                      _validatePassword(value) == null;
                                  if (_isPasswordValid) _password = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: TextButton(
                          onPressed: () {
                            // يمكن إضافة التنقل إلى صفحة استعادة كلمة المرور هنا
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
                            Responsive.space(context, size: Space.xlarge) * 4,
                      ),
                      CircularButton(
                        onPressed: () {
                          // if (_formKey.currentState!.validate() &&
                          //     _email == 'seif@fci.bu.edu.eg') {
                          //   UserProfile user = UserProfile(
                          //     department: 'SC',
                          //     id: 'adminID',
                          //     level: 'الثالثة',
                          //     name: 'سيف ناصر',
                          //     section: '1',
                          //   );
                          //   Provider.of<UserProfileProvider>(
                          //     context,
                          //     listen: false,
                          //   ).setUserProfile(user);
                          //   // Handle form submission
                          //   Navigator.pushNamedAndRemoveUntil(
                          //     context,
                          //     Landing.id,
                          //     (route) => false,
                          //   );
                          // } else {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     SnackBar(
                          //       content: Text(
                          //         'اما فية غلط في البيانات او المستخدم غير مسجل',
                          //         textAlign: TextAlign.center,
                          //         style: TextStyle(
                          //           fontSize: Responsive.text(context) * .9,
                          //           fontWeight: FontWeight.bold,
                          //         ),
                          //       ),
                          //       backgroundColor: Colors.red,
                          //     ),
                          //   );
                          // }
                          _login();
                        },
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
    );
  }
}
