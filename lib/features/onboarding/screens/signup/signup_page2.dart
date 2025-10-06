import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/widgets/custom_dropdown.dart';
import '../../../../responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../services/permission_service.dart';
import '../../../../services/notification_service.dart';
import 'package:pivot/features/onboarding/screens/privacy_policy_screen.dart';
import 'package:pivot/features/onboarding/screens/terms_of_service_screen.dart';
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
  bool _acceptedTerms = false;
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

    // Validate all fields are selected
    if (_selectedLevel.isEmpty) {
      setState(() {
        _errorMessage = 'الرجاء اختيار الفرقة';
      });
      return;
    }

    if (_selectedDepartment.isEmpty) {
      setState(() {
        _errorMessage = 'الرجاء اختيار القسم';
      });
      return;
    }

    if (_selectedSection.isEmpty) {
      setState(() {
        _errorMessage = 'الرجاء اختيار السكشن';
      });
      return;
    }

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'يجب الموافقة على شروط الخدمة وسياسة الخصوصية للمتابعة';
      });
      return;
    }

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
                              'كمل بياناتك الشخصية',
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
                              'المعلومات دي هتساعدنا نخلي تجربتك افضل',
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

                            // Level Dropdown (Always enabled - first step)
                            CustomDropdown(
                              value: _selectedLevel,
                              items: FormOptions.academicYears,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLevel = value!;
                                  // Reset department and section when level changes
                                  // Don't auto-populate - let user choose
                                  _selectedDepartment = '';
                                  _selectedSection = '';
                                });
                              },
                              hint: 'اختار الفرقة',
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),

                            // Department Dropdown (Enabled only if level is selected)
                            Opacity(
                              opacity: _selectedLevel.isEmpty ? 0.5 : 1.0,
                              child: IgnorePointer(
                                ignoring: _selectedLevel.isEmpty,
                                child: CustomDropdown(
                                  value: _selectedDepartment,
                                  items:
                                      _selectedLevel.isEmpty
                                          ? ['']
                                          : FormOptions.getDepartmentsForYear(
                                            _selectedLevel,
                                          ),
                                  onChanged: (value) {
                                    if (_selectedLevel.isEmpty) return;
                                    setState(() {
                                      _selectedDepartment = value!;
                                      // Reset section when department changes
                                      // Don't auto-populate - let user choose
                                      _selectedSection = '';
                                    });
                                  },
                                  hint: 'اختار القسم',
                                ),
                              ),
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),

                            // Section Dropdown (Enabled only if department is selected)
                            Opacity(
                              opacity:
                                  _selectedLevel.isEmpty ||
                                          _selectedDepartment.isEmpty
                                      ? 0.5
                                      : 1.0,
                              child: IgnorePointer(
                                ignoring:
                                    _selectedLevel.isEmpty ||
                                    _selectedDepartment.isEmpty,
                                child: CustomDropdown(
                                  value: _selectedSection,
                                  items:
                                      _selectedLevel.isEmpty ||
                                              _selectedDepartment.isEmpty
                                          ? ['']
                                          : _getAvailableSections(
                                            _selectedLevel,
                                            _selectedDepartment,
                                          ),
                                  onChanged: (value) {
                                    if (_selectedLevel.isEmpty ||
                                        _selectedDepartment.isEmpty)
                                      return;
                                    setState(() {
                                      _selectedSection = value!;
                                    });
                                  },
                                  hint: 'اختار السكشن',
                                ),
                              ),
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

                            // Terms of Service & Privacy Policy Acceptance
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                                vertical: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(
                                  Responsive.space(context, size: Space.medium),
                                ),
                                border: Border.all(
                                  color:
                                      _acceptedTerms
                                          ? Colors.green.shade300
                                          : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _acceptedTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _acceptedTerms = value ?? false;
                                      });
                                    },
                                    activeColor: Colors.green,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                      ),
                                      child: RichText(
                                        textDirection: TextDirection.rtl,
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: Responsive.text(
                                              context,
                                              size: TextSize.small,
                                            ),
                                            color: Colors.grey[700],
                                            height: 1.5,
                                          ),
                                          children: [
                                            const TextSpan(text: 'أوافق على '),
                                            TextSpan(
                                              text: 'شروط الخدمة',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              recognizer:
                                                  TapGestureRecognizer()
                                                    ..onTap = () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                                  const TermsOfServiceScreen(),
                                                        ),
                                                      );
                                                    },
                                            ),
                                            const TextSpan(text: ' و'),
                                            TextSpan(
                                              text: 'سياسة الخصوصية',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              recognizer:
                                                  TapGestureRecognizer()
                                                    ..onTap = () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                                  const PrivacyPolicyScreen(),
                                                        ),
                                                      );
                                                    },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.large,
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
                                : Opacity(
                                  opacity: _acceptedTerms ? 1.0 : 0.5,
                                  child: CircularButton(
                                    onPressed:
                                        _acceptedTerms
                                            ? () => _handleSignup()
                                            : () {},
                                    icon: Icons.check,
                                    backgroundColor: Colors.black87,
                                    iconColor: Colors.white,
                                    elevation: 0,
                                    iconSizeMultiplier: 1.5,
                                    sizeMultiplier: 4,
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
