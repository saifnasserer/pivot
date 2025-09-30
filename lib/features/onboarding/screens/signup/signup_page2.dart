import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/widgets/custom_dropdown.dart';
import '../../../../responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../services/permission_service.dart';
import '../../../../services/notification_service.dart';
import 'package:pivot/features/onboarding/screens/privacy_policy_screen.dart';
import 'package:pivot/features/auth/providers/auth_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';

class SignupPage2 extends ConsumerStatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String gender;

  const SignupPage2({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.gender,
  });

  @override
  ConsumerState<SignupPage2> createState() => _SignupPage2State();
}

class _SignupPage2State extends ConsumerState<SignupPage2> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();

  String _selectedDepartment = '';
  String _selectedLevel = '';
  String _selectedSection = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Initialize with default values or load from previous step
    _selectedDepartment = FormOptions.allDepartments.first;
    _selectedLevel = FormOptions.academicYears.first;
    _selectedSection = '1';
  }

  @override
  void dispose() {
    _departmentController.dispose();
    _levelController.dispose();
    _sectionController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the auth provider to actually create the user account
      final authNotifier = ref.read(authProvider.notifier);
      final userProfile = await authNotifier.signup(
        email: widget.email,
        password: widget.password,
        userData: {
          'name': widget.name,
          'department': _selectedDepartment,
          'level': _selectedLevel,
          'section': _selectedSection,
          'gender': widget.gender,
          'phone': widget.phone,
        },
      );

      if (userProfile != null && mounted) {
        // Set the user profile using Riverpod
        ref
            .read(userProfileProvider.notifier)
            .setLoggedInUserProfile(userProfile);
        ref.read(userProfileProvider.notifier).setUserProfile(userProfile);

        // Request permissions
        if (!kIsWeb) {
          await PermissionService.requestPhotosPermission();

          final notificationService = NotificationService();
          await notificationService.requestPermissionsExplicitly();
        }

        // Navigate to main app
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/landing');
        }
      } else {
        // Handle case where signup succeeded but no profile was returned
        if (mounted) {
          setState(() {
            _errorMessage =
                'فشل في إنشاء الملف الشخصي. يرجى المحاولة مرة أخرى.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'فشل في إنشاء الحساب. يرجى المحاولة مرة أخرى.';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
        } else if (e.code == 'weak-password') {
          errorMessage = 'كلمة المرور ضعيفة جداً';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'البريد الإلكتروني غير صحيح';
        }
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء إنشاء الحساب: $e';
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
                      'أكمل بياناتك الشخصية',
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
                      height: Responsive.space(context, size: Space.small),
                    ),

                    Text(
                      'هذه المعلومات ستساعدنا في تخصيص تجربتك',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),

                    // Department Dropdown
                    CustomDropdown(
                      value: _selectedDepartment,
                      items: FormOptions.allDepartments,
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartment = value!;
                        });
                      },
                      hint: 'اختر القسم',
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    // Level Dropdown
                    CustomDropdown(
                      value: _selectedLevel,
                      items: FormOptions.academicYears,
                      onChanged: (value) {
                        setState(() {
                          _selectedLevel = value!;
                        });
                      },
                      hint: 'اختر المستوى',
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    // Section Dropdown
                    CustomDropdown(
                      value: _selectedSection,
                      items: FormOptions.getSectionsForYear(
                        _selectedLevel,
                        _selectedDepartment,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedSection = value!;
                        });
                      },
                      hint: 'اختر الشعبة',
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    // Role Dropdown

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

                    // Privacy Policy Link
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrivacyPolicyScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'بالمتابعة، أنت توافق على سياسة الخصوصية',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    // Signup Button
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
                          onPressed: _handleSignup,
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
