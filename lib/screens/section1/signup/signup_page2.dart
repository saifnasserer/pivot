import 'package:flutter/material.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/models/custom_dropdown.dart';
import '../../../../responsive.dart';

class Signup_2 extends StatefulWidget {
  const Signup_2({super.key});
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

  final List<String> years = [
    'الفرقة الأولى',
    'الفرقة الثانية',
    'الفرقة الثالثة',
    'الفرقة الرابعة',
  ];
  final List<String> departments = ['CS', 'IS', 'IT', 'SC'];
  final List<String> sections = ['1', '2', '3', '4', '5', '6', '7', '8'];

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
                                items: departments,
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
                  CircularButton(
                    onPressed: () {
                      // Check if all dropdowns have values selected
                      bool allDropdownsValid = 
                          selectedYear != null && 
                          selectedDepartment != null && 
                          selectedSection != null;
                      
                      // Update the validity state for visual feedback
                      setState(() {
                        _isYearValid = selectedYear != null;
                        _isDepartmentValid = selectedDepartment != null;
                        _isSectionValid = selectedSection != null;
                      });
                      
                      // Only navigate if both form validation and dropdown validation pass
                      if (_formKey.currentState!.validate() && allDropdownsValid) {
                        Navigator.pushNamed(context, Landing.id);
                      } else {
                        // Show a snackbar with error message if validation fails
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'برجاء اختيار جميع البيانات المطلوبة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.red[400],
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: Icons.check,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
