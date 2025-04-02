import 'package:flutter/material.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/models/custom_dropdown.dart';
import '../../../../responsive.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../models/user_profile.dart';
import 'package:uuid/uuid.dart';

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
  final List<String> _allDepartments = ['CS', 'IS', 'IT', 'SC', 'General'];

  // State variable for currently available departments
  List<String> _availableDepartments = [];

  final List<String> years = [
    'الفرقة الأولى',
    'الفرقة الثانية',
    'الفرقة الثالثة',
    'الفرقة الرابعة',
  ];
  final List<String> sections = ['1', '2', '3', '4', '5', '6', '7', '8'];

  @override
  void initState() {
    super.initState();
    // Initialize available departments with the full list
    _availableDepartments = List.from(_allDepartments);
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
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropdown(
                                value: selectedYear,
                                items: years,
                                hint: 'اختر الفرقة',
                                isValid: _isYearValid,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedYear = newValue;
                                    _isYearValid = newValue != null;
                                    // Update available departments based on selected year
                                    if (newValue == 'الفرقة الأولى' ||
                                        newValue == 'الفرقة الثانية') {
                                      _availableDepartments = ['General'];
                                      // If a different department was previously selected, reset it
                                      if (selectedDepartment != null &&
                                          selectedDepartment != 'General') {
                                        selectedDepartment = null;
                                        _isDepartmentValid = false;
                                      }
                                    } else {
                                      // Restore all departments if year is 3rd or 4th
                                      _availableDepartments = [
                                        'CS',
                                        'IS',
                                        'IT',
                                        'SC',
                                      ];
                                    }
                                  });
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_departmentFocus);
                                },
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Text(
                              'الفرقة',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropdown(
                                value: selectedDepartment,
                                items:
                                    _availableDepartments, // Use filtered list
                                hint: 'اختر القسم',
                                isValid: _isDepartmentValid,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedDepartment = newValue;
                                    _isDepartmentValid = newValue != null;
                                  });
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_sectionFocus);
                                },
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Text(
                              'القسم',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropdown(
                                value: selectedSection,
                                items: sections,
                                hint: 'اختر السكشن',
                                isValid: _isSectionValid,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedSection = newValue;
                                    _isSectionValid = newValue != null;
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Text(
                              'السكشن',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                              ),
                            ),
                          ],
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
                      onPressed: _submitSignup,
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

  void _submitSignup() {
    setState(() {
      _isYearValid = selectedYear != null;
      _isDepartmentValid = selectedDepartment != null;
      _isSectionValid = selectedSection != null;
    });

    if (_formKey.currentState!.validate() &&
        _isYearValid &&
        _isDepartmentValid &&
        _isSectionValid) {
      final userId = Uuid().v4();

      final newUserProfile = UserProfile(
        id: userId,
        name: widget.name,
        email: widget.email,
        level: selectedYear!,
        department: selectedDepartment!,
        section: selectedSection!,
      );

      Provider.of<UserProfileProvider>(
        context,
        listen: false,
      ).setUserProfile(newUserProfile);

      print('Signup successful for ${widget.email}');
      print('Phone: ${widget.phone}');
      print('Password: ${widget.password}');
      print('Section: $selectedSection');

      Navigator.pushNamedAndRemoveUntil(context, Landing.id, (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الفرقة والقسم والسكشن')),
      );
    }
  }
}
