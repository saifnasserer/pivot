import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/providers/settings_provider.dart';
import 'package:pivot/screens/models/custom_dropdown.dart';
import '../../../../responsive.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart'; // Import AuthService
import '../../../services/local_auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../services/permission_service.dart';

class Signup_2 extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String gender;

  const Signup_2({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.gender,
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
  bool _isLoading = false;

  String? selectedYear;
  String? selectedDepartment;
  String? selectedSection;

  List<String> _availableDepartments = [];
  List<String> _availableSections = [];

  // Declare and initialize AuthService
  final AuthService _authService = AuthService();
  final LocalAuthService _localAuthService = LocalAuthService();
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _availableDepartments = FormOptions.getDepartmentsForYear(null);
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
    final bool canAuth = await _localAuthService.isBiometricSupported();
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
        await prefs.setBool('isBiometricEnabled', true);

        // Securely store credentials
        await _storage.write(key: 'biometric_email', value: email);
        await _storage.write(key: 'biometric_password', value: password);

        debugPrint(
          '[Biometric Prompt] SUCCESS: Biometrics enabled and credentials stored.',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تمكين تسجيل الدخول بالبصمة.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      debugPrint(
        '[Biometric Prompt] FAILED: Device does not support biometrics.',
      );
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

  // Request notification permission with user-friendly dialog
  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) return; // Notifications not supported on web

    try {
      // Use existing static method from PermissionService
      bool granted = await PermissionService.requestStoragePermission();

      if (!granted && mounted) {
        // Show dialog to open settings if permission denied
        await PermissionService.requestStoragePermissionWithRationale(context);
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final sectionCounts = settingsProvider.sectionCounts;
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
                          items: FormOptions.academicYears,
                          hint: 'اختر الفرقة',
                          isValid: _isYearValid,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedYear = newValue;
                              _isYearValid = true;

                              // Reset and update dependent dropdowns
                              selectedDepartment = null;
                              _isDepartmentValid = false;
                              selectedSection = null;
                              _isSectionValid = false;

                              _availableDepartments =
                                  FormOptions.getDepartmentsForYear(newValue);
                              _availableSections = [];
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

                              if (selectedDepartment != null &&
                                  sectionCounts.containsKey(
                                    selectedDepartment,
                                  )) {
                                _availableSections = List<String>.generate(
                                  sectionCounts[selectedDepartment]!,
                                  (i) => '${i + 1}',
                                );
                              } else {
                                _availableSections = [];
                              }
                              if (!_availableSections.contains(
                                selectedSection,
                              )) {
                                selectedSection = null;
                                _isSectionValid = false;
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
                              _isSectionValid =
                                  newValue != null && newValue.isNotEmpty;
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
                    child:
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : CircularButton(
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

      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic> userData = {
        'name': widget.name,
        'department': selectedDepartment,
        'level': selectedYear,
        'section': selectedSection,
        'profileImageUrl': null,
        'gender': widget.gender,
        'registrationDate': DateTime.now().toIso8601String(),
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

          // Request notification permission after successful signup
          await _requestNotificationPermission();

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
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
