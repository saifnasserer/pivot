import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/screens/section2/landing.dart';
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

  // Common decoration for all text fields
  InputDecoration _getInputDecoration(
    BuildContext context,
    String hint, {
    Widget? suffixIcon,
    bool? isValid,
  }) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: BorderSide(color: Color(0xFFF7F7F7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: BorderSide(
          color: isValid == true ? Colors.green : Color(0xFFF7F7F7),
          width: isValid == true ? 2 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: BorderSide(
          color: isValid == true ? Colors.green : Colors.black,
          width: isValid == true ? 2 : 1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: BorderSide(color: Colors.red),
      ),
      hintText: hint,
      filled: true,
      fillColor: Color(0xFFF7F7F7),
      hintStyle: TextStyle(
        color: Colors.black,
        fontSize: Responsive.text(context, size: TextSize.medium),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      suffixIcon: suffixIcon,
    );
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
                            TextFormField(
                              focusNode: _emailFocus,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_passwordFocus);
                              },
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isEmailValid = _validateEmail(value) == null;
                                });
                              },
                              decoration: _getInputDecoration(
                                context,
                                'الايميل الجامعي',
                                isValid: _isEmailValid,
                              ),
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            TextFormField(
                              focusNode: _passwordFocus,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.done,
                              obscureText: !_isPasswordVisible,
                              validator: _validatePassword,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isPasswordValid =
                                      _validatePassword(value) == null;
                                });
                              },
                              decoration: _getInputDecoration(
                                context,
                                'الباسورد',
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
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height:
                            Responsive.space(context, size: Space.xlarge) * 4,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Handle form submission
                            Navigator.pushNamed(context, Landing.id);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          shape: CircleBorder(),
                          minimumSize: Size(
                            Responsive.space(context, size: Space.xlarge) * 4,
                            Responsive.space(context, size: Space.xlarge) * 4,
                          ),
                          elevation: 5,
                        ),
                        child: Icon(
                          Icons.check,
                          size:
                              Responsive.text(context, size: TextSize.heading) *
                              1.5,
                          color: Colors.white,
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
    );
  }
}
