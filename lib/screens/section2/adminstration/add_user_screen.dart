import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/custom_text_field.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/widgets/custom_dropdown.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class AddUserScreen extends StatefulWidget {
  // = 'add_user_screen';
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
  final _subjectSearchController = TextEditingController();

  String? _selectedYear;
  String? _selectedDepartment;
  String? _selectedSection;
  String _selectedGender = FormOptions.genders.first;
  String _selectedRole = 'Student';

  bool _isLoading = false;
  bool _showSubjectSelection = false;
  final Set<String> _selectedSubjectIds = {};
  String _subjectSearchQuery = '';

  List<String> _availableDepartments = [];
  List<String> _availableSections = [];

  @override
  void initState() {
    super.initState();
    _availableDepartments = FormOptions.getDepartmentsForYear(null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubjectProvider>(context, listen: false).fetchAllSubjects();
      Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).fetchSectionCounts();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _subjectSearchController.dispose();
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

  void _toggleSubjectSelection(Subject subject) {
    setState(() {
      if (_selectedSubjectIds.contains(subject.id)) {
        _selectedSubjectIds.remove(subject.id);
      } else {
        _selectedSubjectIds.add(subject.id);
      }
    });
  }

  List<Subject> _getFilteredSubjects() {
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    if (_subjectSearchQuery.isEmpty) {
      return subjectProvider.allSubjects;
    }
    return subjectProvider.allSubjects.where((subject) {
      return subject.name.toLowerCase().contains(
            _subjectSearchQuery.toLowerCase(),
          ) ||
          subject.englishName.toLowerCase().contains(
            _subjectSearchQuery.toLowerCase(),
          ) ||
          subject.departments.any(
            (dept) =>
                dept.toLowerCase().contains(_subjectSearchQuery.toLowerCase()),
          );
    }).toList();
  }

  Widget _buildSubjectCard(Subject subject) {
    final isSelected = _selectedSubjectIds.contains(subject.id);
    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.medium),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _toggleSubjectSelection(subject),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: Responsive.padding(context, size: Space.large),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    Wrap(
                      spacing: Responsive.space(context, size: Space.small),
                      runSpacing: Responsive.space(context, size: Space.tiny),
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'القسم: ${subject.departments.join(', ')}',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ساعات: ${subject.hours}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.black : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, child) {
        if (subjectProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.black),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'جاري تحميل المواد...',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        if (subjectProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'حدث خطأ: ${subjectProvider.error}',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        if (subjectProvider.allSubjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'لا توجد مواد متاحة',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final filteredSubjects = _getFilteredSubjects();
        if (filteredSubjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'لا توجد نتائج للبحث',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: Responsive.padding(context, size: Space.large),
          itemCount: filteredSubjects.length,
          itemBuilder: (context, index) {
            final subject = filteredSubjects[index];
            return _buildSubjectCard(subject);
          },
        );
      },
    );
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
          teachingSubjects: _selectedSubjectIds.toList(),
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
                          // Show subject selection for Professor and miniProfessor
                          _showSubjectSelection =
                              (newValue == 'Professor' ||
                                  newValue == 'miniProfessor');
                          if (!_showSubjectSelection) {
                            _selectedSubjectIds.clear();
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

                            // Get section count from settings provider
                            final settingsProvider =
                                Provider.of<SettingsProvider>(
                                  context,
                                  listen: false,
                                );
                            if (newValue != null &&
                                settingsProvider.sectionCounts.containsKey(
                                  newValue,
                                )) {
                              final sectionCount =
                                  settingsProvider.sectionCounts[newValue] ?? 0;
                              _availableSections = List<String>.generate(
                                sectionCount,
                                (i) => '${i + 1}',
                              );
                            } else {
                              _availableSections = [];
                            }
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
                if (_showSubjectSelection)
                  _buildCard(
                    title: 'المواد',
                    icon: Icons.menu_book_outlined,
                    children: [
                      // Search field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: _subjectSearchController,
                          onChanged: (value) {
                            setState(() {
                              _subjectSearchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'البحث في المواد...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                            contentPadding: Responsive.padding(
                              context,
                              size: Space.medium,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      // Selected subjects count
                      if (_selectedSubjectIds.isNotEmpty)
                        Container(
                          padding: Responsive.padding(
                            context,
                            size: Space.small,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                                size: 16,
                              ),
                              SizedBox(
                                width: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              Text(
                                'تم اختيار ${_selectedSubjectIds.length} مادة',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      // Subjects count info
                      Consumer<SubjectProvider>(
                        builder: (context, subjectProvider, child) {
                          final filteredSubjects = _getFilteredSubjects();
                          return Container(
                            padding: Responsive.padding(
                              context,
                              size: Space.small,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[600],
                                  size: 16,
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Text(
                                  'عرض ${filteredSubjects.length} من ${subjectProvider.allSubjects.length} مادة',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      // Subjects list with scrollable container
                      Container(
                        constraints: BoxConstraints(
                          maxHeight:
                              Responsive.height(context) *
                              0.4, // 40% of screen height
                        ),
                        child: SingleChildScrollView(
                          child: _buildSubjectsList(),
                        ),
                      ),
                    ],
                  ),
                if (_showSubjectSelection)
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
                      padding: Responsive.paddingVertical(
                        context,
                        size: Space.tiny,
                      ),
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
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
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
      padding: Responsive.padding(context, size: Space.large),
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
                padding: Responsive.padding(context, size: Space.small),
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
                  fontSize: Responsive.text(context, size: TextSize.heading),
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
