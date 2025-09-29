import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/widgets/custom_text_field.dart';
import 'package:pivot/widgets/no_internet_message.dart';
import 'package:pivot/responsive.dart';

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
  bool _isLoading = false;

  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final email = _email.toLowerCase().trim();

      setState(() {
        _isLoading = true;
      });

      try {
        // Try to send password reset email directly
        // Firebase will handle the user existence check internally
        await _auth.sendPasswordResetEmail(email: email);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.\n\n💡 نصائح:\n• تحقق من مجلد الرسائل غير المرغوب فيها\n• أضف Pivot@engseif.com إلى جهات الاتصال\n• قد يستغرق وصول البريد دقيقة أو دقيقتين',
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'حدث خطأ ما.';

        switch (e.code) {
          case 'invalid-email':
            errorMessage = 'البريد الإلكتروني غير صحيح.';
            break;
          case 'user-not-found':
            errorMessage = 'لا يوجد مستخدم مسجل بهذا البريد الإلكتروني.';
            break;
          case 'too-many-requests':
            errorMessage = 'تم إرسال طلبات كثيرة. يرجى المحاولة لاحقاً.';
            break;
          case 'network-request-failed':
            errorMessage = 'خطأ في الاتصال بالإنترنت. يرجى التحقق من اتصالك.';
            break;
          default:
            errorMessage = e.message ?? 'حدث خطأ ما.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, textAlign: TextAlign.center),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: NoInternetMessage(
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
                  padding: Responsive.paddingHorizontal(
                    context,
                    size: Space.xlarge,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'إستعادة كلمة المرور',
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
                        height: Responsive.space(context, size: Space.small),
                      ),
                      Text(
                        'أدخل بريدك الإلكتروني المسجل لإرسال رابط إعادة التعيين',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.xlarge),
                      ),
                      CustomTextField(
                        hint: 'البريد الإلكتروني',
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
                      SizedBox(
                        height:
                            Responsive.space(context, size: Space.xlarge) * 2,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _sendPasswordResetEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.large),
                              ),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    'إرسال',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
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
      ),
    );
  }
}
