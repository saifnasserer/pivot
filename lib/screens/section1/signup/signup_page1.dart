import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/screens/section1/signup/signup_page2.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/widgets/custom_dropdown.dart';
import 'package:pivot/widgets/custom_text_field.dart';
import '../../../responsive.dart';
import 'package:pivot/widgets/no_internet_message.dart';

class Signup_1 extends StatefulWidget {
  const Signup_1({super.key});
  static String id = 'signup1';
  @override
  State<Signup_1> createState() => _Signup_1State();
}

class _Signup_1State extends State<Signup_1> {
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
    if (!value.toLowerCase().endsWith('fci.bu.edu.eg')) {
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
        child: NoInternetMessage(
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/first-landing');
                },
              ),
            ),
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
                              hint: 'الايميل الجامعي',
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
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
                        height:
                            Responsive.space(context, size: Space.xlarge) * 4,
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
                name: _nameController.text,
                email: _emailController.text.toLowerCase().trim(),
                phone: _phoneController.text,
                password: _passwordController.text,
                gender: _gender,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('املي البيانات بشكل كامل')));
    }
  }
}
