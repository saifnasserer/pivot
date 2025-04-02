import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/screens/section1/signup/signup_page2.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import '../../../responsive.dart';

class Signup_1 extends StatefulWidget {
  const Signup_1({super.key});
  static String id = 'signup1';
  @override
  State<Signup_1> createState() => _Signup_1State();
}

class _Signup_1State extends State<Signup_1> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _isPasswordVisible = false;

  String _name = '';
  String _email = '';
  String _phone = '';
  String _password = '';

  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPhoneValid = false;
  bool _isPasswordValid = false;

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال الاسم';
    }
    return null;
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

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال رقم الموبايل';
    }
    if (!RegExp(r'^(0)[0-9]{10}$').hasMatch(value)) {
      return 'رقم الموبايل غير صحيح';
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
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.xlarge,
                            ),
                          ),
                          Text(
                            'البيانات الاساسية',
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
                            focusNode: _nameFocus,
                            hint: 'الاسم',
                            validator: _validateName,
                            isValid: _isNameValid,
                            onEditingComplete: () {
                              FocusScope.of(context).requestFocus(_emailFocus);
                            },
                            onChanged: (value) {
                              setState(() {
                                _name = value;
                                _isNameValid = _validateName(value) == null;
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
                            focusNode: _emailFocus,
                            hint: 'الايميل الجامعي',
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            isValid: _isEmailValid,
                            onEditingComplete: () {
                              FocusScope.of(context).requestFocus(_phoneFocus);
                            },
                            onChanged: (value) {
                              setState(() {
                                _email = value;
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
                            focusNode: _phoneFocus,
                            hint: 'رقم الموبيل',
                            validator: _validatePhone,
                            keyboardType: TextInputType.phone,
                            isValid: _isPhoneValid,
                            onEditingComplete: () {
                              FocusScope.of(
                                context,
                              ).requestFocus(_passwordFocus);
                            },
                            onChanged: (value) {
                              setState(() {
                                _phone = value;
                                _isPhoneValid = _validatePhone(value) == null;
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
                                _password = value;
                                _isPasswordValid =
                                    _validatePassword(value) == null;
                              });
                            },
                            onEditingComplete: () {
                              FocusScope.of(context).unfocus();
                              _submitPage1();
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.xlarge) * 4,
                    ),
                    Padding(
                      padding: Responsive.paddingHorizontal(
                        context,
                        size: Space.large,
                      ),
                      child: CircularButton(
                        onPressed: _submitPage1,
                        icon: Icons.arrow_forward,
                      ),
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

  void _submitPage1() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => Signup_2(
                name: _name,
                email: _email,
                phone: _phone,
                password: _password,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول المطلوبة بشكل صحيح'),
        ),
      );
    }
  }
}
