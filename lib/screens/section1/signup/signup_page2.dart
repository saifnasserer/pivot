import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/providers/settings_provider.dart';
import 'package:pivot/screens/models/custom_dropdown.dart';
import 'package:pivot/screens/section2/landing.dart';
import '../../../../responsive.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../services/permission_service.dart';
import '../../../services/notification_service.dart';

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
  bool _isLoading = false;

  String? selectedYear;
  String? selectedDepartment;
  String? selectedSection;

  List<String> _availableDepartments = [];
  List<String> _availableSections = [];

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _availableDepartments = FormOptions.getDepartmentsForYear(null);
    // Fetch section counts after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).fetchSectionCounts();
    });
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
      // Use the new graceful approach from NotificationService
      final notificationService = NotificationService();
      final granted = await notificationService.requestPermissionsExplicitly();

      if (!granted && mounted) {
        // Show dialog to open settings if permission denied
        await PermissionService.requestNotificationPermissionWithRationale(
          context,
        );
      }
    } catch (e) {
      //debugprint('Error requesting notification permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // Show loading indicator if section counts are still loading
    if (settingsProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedYear = newValue;

                              // Reset and update dependent dropdowns
                              selectedDepartment = null;
                              selectedSection = null;

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
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedDepartment = newValue;
                              selectedSection = null;

                              // Get section count from settings provider
                              if (selectedDepartment != null &&
                                  settingsProvider.sectionCounts.containsKey(
                                    selectedDepartment,
                                  )) {
                                final sectionCount =
                                    settingsProvider
                                        .sectionCounts[selectedDepartment] ??
                                    0;
                                _availableSections = List<String>.generate(
                                  sectionCount,
                                  (i) => '${i + 1}',
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
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSection = newValue;
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
    if (selectedYear == null ||
        selectedDepartment == null ||
        selectedSection == null) {
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

        if (mounted && userProfile != null) {
          //debugprint(
          // '[Signup] User profile created successfully: ${userProfile.name}',
          // );

          // Set the user profile in the provider
          final provider = Provider.of<UserProfileProvider>(
            context,
            listen: false,
          );
          provider.setLoggedInUserProfile(userProfile);

          //debugprint(
          // '[Signup] Profile set in provider, waiting for AuthWrapper to detect...',
          // );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم التسجيل بنجاح.'),
                backgroundColor: Colors.green,
              ),
            );
            //debugprint(
            //   '[Signup] Success message shown, AuthWrapper should navigate to Landing',
            // );

            // Force navigation to Landing if AuthWrapper doesn't detect it
            // Use a shorter delay to reduce main thread blocking
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                //debugprint('[Signup] Forcing navigation to Landing...');
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/landing', (route) => false);
              }
            });
          }

          // Move heavy operations to background
          Future.microtask(() async {
            try {
              // Request notification permission after successful signup
              await _requestNotificationPermission();

              // Force a rebuild by triggering notifyListeners again
              await Future.delayed(const Duration(milliseconds: 50));
              if (mounted) {
                provider.notifyListeners();
              }
            } catch (e) {
              //debugprint('[Signup] Background operations failed: $e');
            }
          });
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
