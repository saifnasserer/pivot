import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/models/custom_dropdown.dart';
import '../../../../responsive.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart'; // Import AuthService
import '../../../services/local_auth_service.dart';
import '../../../providers/settings_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Signup_2 extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String password;

  const Signup_2({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  static String id = 'signup2';
  @override
  State<Signup_2> createState() => _Signup_2State();
}

class _Signup_2State extends State<Signup_2> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _yearFocus = FocusNode();
  final FocusNode _departmentFocus = FocusNode();
  final FocusNode _sectionFocus = FocusNode();
  bool _isYearValid = false;
  bool _isDepartmentValid = false;
  bool _isSectionValid = false;

  String? selectedYear;
  String? selectedDepartment;
  String? selectedSection;

  // Store the full list of departments
  final List<String> _allDepartments = ['CS', 'IS', 'AI', 'SC', 'General'];

  // State variable for currently available departments
  List<String> _availableDepartments = [];

  final List<String> years = [
    'الفرقة الأولى',
    'الفرقة الثانية',
    'الفرقة الثالثة',
    'الفرقة الرابعة',
  ];
  List<String> _availableSections = [];

  // Declare and initialize AuthService
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Initialize available departments with the full list
    _availableDepartments = List.from(_allDepartments);
  }

  Future<void> _promptEnableBiometrics(
    String uid,
    String email,
    String password,
  ) async {
    if (kIsWeb) {
      debugPrint('[Biometric Prompt] Running on web, skipping.');
      return;
    }

    debugPrint('[Biometric Prompt] Checking for biometrics on device...');
    final bool canAuth = await LocalAuthService.canAuthenticate();
    debugPrint('[Biometric Prompt] Can device authenticate? -> $canAuth');

    if (mounted && canAuth) {
      debugPrint(
        '[Biometric Prompt] SUCCESS: Device supports biometrics, showing prompt.',
      );
      final bool enable =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('تمكين تسجيل الدخول بالبصمة'),
                  content: const Text(
                    'هل ترغب في استخدام بصمة الإصبع أو معرف الوجه لتسجيل الدخول بشكل أسرع في المرة القادمة؟',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('لاحقاً'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('تمكين'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (enable) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled_$uid', true);

        // Securely store credentials
        const storage = FlutterSecureStorage();
        await storage.write(key: 'email', value: email);
        await storage.write(key: 'password', value: password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تمكين تسجيل الدخول بالبصمة.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم التسجيل بنجاح.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, Landing.id);
    }
  }

  @override
  void dispose() {
    _yearFocus.dispose();
    _departmentFocus.dispose();
    _sectionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                          height: Responsive.space(context, size: Space.xlarge),
                        ),
                        Text(
                          'تفاصيل الكلية',
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
                          height: Responsive.space(context, size: Space.xlarge),
                        ),
                        CustomDropdown(
                          value: selectedYear,
                          items: years,
                          hint: 'اختر الفرقة',
                          isValid: _isYearValid,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedYear = newValue;
                              _isYearValid = true;
                              selectedDepartment = null;
                              _isDepartmentValid = false;
                              selectedSection = null;
                              _isSectionValid = false;
                              _availableSections = []; // Clear sections

                              if (newValue == 'الفرقة الأولى' ||
                                  newValue == 'الفرقة الثانية') {
                                _availableDepartments =
                                    _allDepartments
                                        .where((d) => d == 'General')
                                        .toList();
                              } else {
                                _availableDepartments =
                                    _allDepartments
                                        .where((d) => d != 'General')
                                        .toList();
                              }
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_departmentFocus);
                            });
                          },
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        CustomDropdown(
                          value: selectedDepartment,
                          items: _availableDepartments,
                          hint: 'اختر القسم',
                          isValid: _isDepartmentValid,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedDepartment = newValue;
                              _isDepartmentValid = true;
                              selectedSection = null; // Reset section
                              _isSectionValid = false;

                              if (newValue == 'General') {
                                _availableSections = ['Not Applicable'];
                                selectedSection = 'Not Applicable';
                                _isSectionValid = true;
                              } else if (newValue != null) {
                                final settingsProvider =
                                    Provider.of<SettingsProvider>(
                                      context,
                                      listen: false,
                                    );
                                final count =
                                    settingsProvider.sectionCounts[newValue] ??
                                    8; // Default to 8
                                _availableSections = List.generate(
                                  count,
                                  (i) => (i + 1).toString(),
                                );
                              } else {
                                _availableSections = [];
                              }
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_sectionFocus);
                            });
                          },
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        CustomDropdown(
                          value: selectedSection,
                          items: _availableSections,
                          hint: 'اختر السكشن',
                          isValid: _isSectionValid,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSection = newValue;
                              _isSectionValid = true;
                            });
                            FocusScope.of(context).unfocus();
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
                      onPressed: _submitForm,
                      icon: Icons.check,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    setState(() {
      _isYearValid = selectedYear != null;
      _isDepartmentValid = selectedDepartment != null;
      _isSectionValid = selectedSection != null;
    });

    if (!_isYearValid || !_isDepartmentValid || !_isSectionValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار الفرقة والقسم والسكشن')),
        );
      }
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Map<String, dynamic> userData = {
        'name': widget.name,
        'department': selectedDepartment,
        'level': selectedYear,
        'section': selectedSection,
        'profileImageUrl': null,
      };

      try {
        UserProfile? userProfile = await _authService
            .signUpWithEmailAndPassword(
              widget.email,
              widget.password,
              userData,
            );

        if (mounted) {
          Provider.of<UserProfileProvider>(
            context,
            listen: false,
          ).setUserProfile(userProfile!);
          // Ask to enable biometrics before navigating
          await _promptEnableBiometrics(
            userProfile.id,
            widget.email,
            widget.password,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم التسجيل بنجاح.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            Landing.id,
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'كلمة المرور ضعيفة جدًا.';
            break;
          case 'email-already-in-use':
            errorMessage = 'هذا البريد الإلكتروني مستخدم بالفعل.';
            break;
          case 'invalid-email':
            errorMessage = 'البريد الإلكتروني غير صالح.';
            break;
          default:
            errorMessage = 'حدث خطأ غير متوقع. حاول مرة أخرى.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
