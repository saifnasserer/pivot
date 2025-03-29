import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import '../../../responsive.dart';

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
  bool _isPasswordVisible = false;

  bool _isEmailValid = false;

  bool _isPasswordValid = false;

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
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height:
                            Responsive.space(context, size: Space.xlarge) * 4,
                      ),
                      CircularButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Handle form submission
                            Navigator.pushNamed(context, Landing.id);
                          }
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
