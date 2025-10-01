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
import 'package:pivot/features/settings/providers/settings_provider.dart';

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
  Map<String, int> _sectionCounts = {};

  @override
  void initState() {
    super.initState();
    // Delay provider fetch until after widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(settingsProvider.notifier).fetchSectionCounts();
      }
    });
  }

  void _initializeForm() {
    // Initialize with default values or load from previous step
    _selectedLevel = FormOptions.academicYears.first;
    _selectedDepartment =
        FormOptions.getDepartmentsForYear(_selectedLevel).first;
    _selectedSection =
        _getAvailableSections(_selectedLevel, _selectedDepartment).first;
  }

  List<String> _getAvailableSections(String level, String department) {
    // For first and second year (General department), use section count from settings
    if (level == 'الفرقة الأولى' || level == 'الفرقة الثانية') {
      final count = _sectionCounts['General'] ?? 8;
      return List.generate(count, (index) => (index + 1).toString());
    }

    // For third and fourth year, use department-specific section counts
    if (_sectionCounts.containsKey(department)) {
      final count = _sectionCounts[department] ?? 2;
      return List.generate(count, (index) => (index + 1).toString());
    }

    return ['1', '2']; // Default fallback
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
        // Request permissions
        if (!kIsWeb) {
          await PermissionService.requestPhotosPermission();

          final notificationService = NotificationService();
          await notificationService.requestPermissionsExplicitly();
        }

        // Navigate to auth wrapper which will properly initialize cache and load profile
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth-wrapper');
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
    // Watch the settings provider to get section counts
    final settingsState = ref.watch(settingsProvider);

    // Update section counts when they're loaded
    if (settingsState.sectionCounts.isNotEmpty && _sectionCounts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _sectionCounts = settingsState.sectionCounts;
          });
          _initializeForm();
        }
      });
    }

    // Show loading if settings are still loading or section counts are empty
    final isLoading =
        settingsState.isLoading ||
        (settingsState.sectionCounts.isEmpty && _sectionCounts.isEmpty);

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
          child:
              isLoading
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.black87),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        Text(
                          'جاري تحميل البيانات...',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                  : Center(
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
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
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
                              height: Responsive.space(
                                context,
                                size: Space.large,
                              ),
                            ),

                            // Level Dropdown
                            CustomDropdown(
                              value: _selectedLevel,
                              items: FormOptions.academicYears,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLevel = value!;
                                  // Update department based on selected level
                                  final availableDepartments =
                                      FormOptions.getDepartmentsForYear(
                                        _selectedLevel,
                                      );
                                  // Reset department if current selection is not available
                                  if (!availableDepartments.contains(
                                    _selectedDepartment,
                                  )) {
                                    _selectedDepartment =
                                        availableDepartments.first;
                                  }
                                  // Update section based on new level and department
                                  final availableSections =
                                      _getAvailableSections(
                                        _selectedLevel,
                                        _selectedDepartment,
                                      );
                                  if (availableSections.isNotEmpty &&
                                      !availableSections.contains(
                                        _selectedSection,
                                      )) {
                                    _selectedSection = availableSections.first;
                                  }
                                });
                              },
                              hint: 'اختر المستوى',
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),

                            // Department Dropdown
                            CustomDropdown(
                              value: _selectedDepartment,
                              items: FormOptions.getDepartmentsForYear(
                                _selectedLevel,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value!;
                                  // Update section based on new department
                                  final availableSections =
                                      _getAvailableSections(
                                        _selectedLevel,
                                        _selectedDepartment,
                                      );
                                  if (availableSections.isNotEmpty &&
                                      !availableSections.contains(
                                        _selectedSection,
                                      )) {
                                    _selectedSection = availableSections.first;
                                  }
                                });
                              },
                              hint: 'اختر القسم',
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),

                            // Section Dropdown
                            CustomDropdown(
                              value: _selectedSection,
                              items: _getAvailableSections(
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
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),

                            // Role Dropdown

                            // Error Message
                            if (_errorMessage != null)
                              Container(
                                padding: EdgeInsets.all(
                                  Responsive.space(context, size: Space.medium),
                                ),
                                margin: EdgeInsets.only(
                                  bottom: Responsive.space(
                                    context,
                                    size: Space.medium,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
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
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),

                            // Signup Button
                            _isLoading
                                ? Container(
                                  width:
                                      Responsive.space(
                                        context,
                                        size: Space.xlarge,
                                      ) *
                                      4,
                                  height:
                                      Responsive.space(
                                        context,
                                        size: Space.xlarge,
                                      ) *
                                      4,
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
