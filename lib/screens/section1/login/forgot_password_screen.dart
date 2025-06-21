import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  String _email = '';
  bool _isEmailValid = false;

  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final email = _email.toLowerCase().trim();
      try {
        // Check if user exists
        final userMethods = await _auth.fetchSignInMethodsForEmail(email);
        if (userMethods.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('لا يوجد مستخدم مسجل بهذا البريد الإلكتروني.', textAlign: TextAlign.center),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Send password reset email
        await _auth.sendPasswordResetEmail(email: email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.', textAlign: TextAlign.center),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'حدث خطأ ما.', textAlign: TextAlign.center),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.center,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: Responsive.paddingHorizontal(context, size: Space.xlarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'إستعادة كلمة المرور',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.text(context, size: TextSize.heading),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Responsive.space(context, size: Space.small)),
                    Text(
                      'أدخل بريدك الإلكتروني المسجل لإرسال رابط إعادة التعيين',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.text(context, size: TextSize.small),
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: Responsive.space(context, size: Space.xlarge)),
                    CustomTextField(
                      hint: 'الايميل الجامعي',
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      isValid: _isEmailValid,
                      onChanged: (value) {
                        setState(() {
                          _isEmailValid = _validateEmail(value) == null;
                          if (_isEmailValid) _email = value;
                        });
                      },
                    ),
                    SizedBox(height: Responsive.space(context, size: Space.xlarge) * 2),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sendPasswordResetEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.space(context, size: Space.small),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.space(context, size: Space.medium)),
                          ),
                        ),
                        child: Text(
                          'إرسال',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.text(context, size: TextSize.medium),
                            fontWeight: FontWeight.bold,
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
    );
  }
}
