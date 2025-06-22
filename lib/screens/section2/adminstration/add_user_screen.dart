import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:pivot/providers/super_admin_provider.dart';
import 'package:provider/provider.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/screens/models/custom_dropdown.dart';

class AddUserScreen extends StatefulWidget {
  static const String id = 'add_user_screen';
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();

  String? _selectedYear;
  String? _selectedDepartment;
  String? _selectedSection;
  String _selectedGender = FormOptions.genders.first;
  String _selectedRole = 'Student';

  bool _isLoading = false;

  List<String> _availableDepartments = [];
  List<String> _availableSections = [];

  @override
  void initState() {
    super.initState();
    _availableDepartments = FormOptions.getDepartmentsForYear(null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

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

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for Student and Admin roles
    if ((_selectedRole == 'Student' || _selectedRole == 'Admin') &&
        (_selectedYear == null ||
            _selectedDepartment == null ||
            _selectedSection == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع حقول الكلية'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      final userCredential = await authService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (userCredential.user != null) {
        final userProfile = UserProfile(
          id: userCredential.user!.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _selectedRole,
          department: _selectedDepartment ?? '',
          level: _selectedYear ?? '',
          section: _selectedSection ?? '',
          gender: _selectedGender,
          fcmToken: '',
        );
        await authService.createUserProfile(userProfile);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المستخدم بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في إضافة المستخدم: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'إضافة مستخدم جديد',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: Responsive.padding(context, size: Space.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCard(
                  title: 'البيانات الأساسية',
                  icon: Icons.person,
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      hint: 'الاسم (يفضل ثنائي و بالعربي)',
                      validator: _validateName,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    CustomTextField(
                      controller: _emailController,
                      hint: 'الايميل الجامعي',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    CustomTextField(
                      controller: _passwordController,
                      hint: 'الباسورد',
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    CustomTextField(
                      controller: _phoneController,
                      hint: 'رقم الموبيل',
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    CustomDropdown(
                      hint: 'النوع',
                      value: _selectedGender,
                      items: FormOptions.genders,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue!;
                        });
                      },
                      isValid: true,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    CustomDropdown(
                      hint: 'الدور',
                      value: _selectedRole,
                      items: ['Student', 'Admin', 'miniProfessor', 'Professor'],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue!;
                          // Reset college fields when role changes
                          if (newValue != 'Student' && newValue != 'Admin') {
                            _selectedYear = null;
                            _selectedDepartment = null;
                            _selectedSection = null;
                            _availableDepartments = [];
                            _availableSections = [];
                          }
                        });
                      },
                      isValid: true,
                    ),
                  ],
                ),
                SizedBox(height: Responsive.space(context, size: Space.large)),
                if (_selectedRole == 'Student' || _selectedRole == 'Admin')
                  _buildCard(
                    title: 'الكلية',
                    icon: Icons.school_outlined,
                    children: [
                      CustomDropdown(
                        value: _selectedYear,
                        items: FormOptions.academicYears,
                        hint: 'اختر الفرقة',
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedYear = newValue;
                            _selectedDepartment = null;
                            _selectedSection = null;
                            _availableDepartments =
                                FormOptions.getDepartmentsForYear(newValue);
                            _availableSections = [];
                          });
                        },
                        isValid:
                            (_selectedRole == 'Student' ||
                                    _selectedRole == 'Admin')
                                ? _selectedYear != null
                                : true,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      CustomDropdown(
                        value: _selectedDepartment,
                        items: _availableDepartments,
                        hint: 'اختر القسم',
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDepartment = newValue;
                            _selectedSection = null;
                            _availableSections = FormOptions.getSectionsForYear(
                              _selectedYear,
                              newValue,
                            );
                          });
                        },
                        isValid:
                            (_selectedRole == 'Student' ||
                                    _selectedRole == 'Admin')
                                ? _selectedDepartment != null
                                : true,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      CustomDropdown(
                        value: _selectedSection,
                        items: _availableSections,
                        hint: 'اختر السكشن',
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSection = newValue;
                          });
                        },
                        isValid:
                            (_selectedRole == 'Student' ||
                                    _selectedRole == 'Admin')
                                ? _selectedSection != null
                                : true,
                      ),
                    ],
                  ),
                if (_selectedRole == 'Student' || _selectedRole == 'Admin')
                  SizedBox(
                    height: Responsive.space(context, size: Space.large),
                  ),
                if (_selectedYear == 'الفرقة الأولى' &&
                    (_selectedRole == 'Student' || _selectedRole == 'Admin'))
                  CustomTextField(
                    controller: _studentIdController,
                    hint: 'رقم الطالب',
                    validator: (value) {
                      if (_selectedYear == 'الفرقة الأولى' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'يرجى إدخال رقم الطالب';
                      }
                      return null;
                    },
                  ),
                if (_selectedYear == 'الفرقة الأولى' &&
                    (_selectedRole == 'Student' || _selectedRole == 'Admin'))
                  SizedBox(
                    height: Responsive.space(context, size: Space.large),
                  ),
                Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.black, Color(0xFF424242)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
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
                              'إضافة المستخدم',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xfff7f7f7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.black, size: 28),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          ...children,
        ],
      ),
    );
  }
}
