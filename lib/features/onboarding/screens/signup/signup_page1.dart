import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/widgets/custom_dropdown.dart';
import 'package:pivot/widgets/custom_text_field.dart';
import '../../../../responsive.dart';
import 'package:pivot/widgets/no_internet_message.dart';

class SignupPage1 extends StatefulWidget {
  const SignupPage1({super.key});
  static String id = 'signup1';
  @override
  State<SignupPage1> createState() => _SignupPage1State();
}

class _SignupPage1State extends State<SignupPage1> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _isPasswordVisible = false;
  String _gender = 'ذكر';

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

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.dark,
        ),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: NoInternetMessage(
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/first-landing');
                  },
                ),
              ),
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Form(
                  key: _formKey,
                  child: Center(
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
                                    size: Space.large,
                                  ),
                                ),
                                Text(
                                  'البيانات الاساسية',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize:
                                        Responsive.text(
                                          context,
                                          size: TextSize.heading,
                                        ) *
                                        1.3,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Text(
                                  'ادخل بياناتك الاساسية',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.xlarge,
                                  ),
                                ),
                                CustomTextField(
                                  controller: _nameController,
                                  focusNode: _nameFocus,
                                  hint: 'الاسم (يفضل ثنائي و بالعربي)',
                                  validator: _validateName,
                                  onEditingComplete: () {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_emailFocus);
                                  },
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.medium,
                                  ),
                                ),
                                CustomTextField(
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  hint: 'البريد الإلكتروني',
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  textDirection: TextDirection.ltr,
                                  onEditingComplete: () {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_phoneFocus);
                                  },
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.medium,
                                  ),
                                ),
                                CustomTextField(
                                  controller: _phoneController,
                                  focusNode: _phoneFocus,
                                  hint: 'رقم الموبيل',
                                  validator: _validatePhone,
                                  keyboardType: TextInputType.phone,
                                  textDirection: TextDirection.ltr,
                                  onEditingComplete: () {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_passwordFocus);
                                  },
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.medium,
                                  ),
                                ),
                                CustomTextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  hint: 'الباسورد',
                                  validator: _validatePassword,
                                  textInputAction: TextInputAction.done,
                                  obscureText: !_isPasswordVisible,
                                  textDirection: TextDirection.ltr,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  onEditingComplete: () {
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.medium,
                                  ),
                                ),
                                CustomDropdown(
                                  hint: 'النوع',
                                  value: _gender,
                                  items: FormOptions.genders,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _gender = newValue!;
                                    });
                                  },
                                  isValid: true,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.xlarge,
                            ),
                          ),
                          Padding(
                            padding: Responsive.paddingHorizontal(
                              context,
                              size: Space.large,
                            ),
                            child: CircularButton(
                              onPressed: _submitPage1,
                              icon: Icons.arrow_forward_ios,
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
      ),
    );
  }

  void _submitPage1() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushNamed(
        context,
        '/signup-2',
        arguments: {
          'name': _nameController.text,
          'email': _emailController.text.toLowerCase().trim(),
          'phone': _phoneController.text,
          'password': _passwordController.text,
          'gender': _gender,
        },
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('املي البيانات بشكل كامل')));
    }
  }
}
