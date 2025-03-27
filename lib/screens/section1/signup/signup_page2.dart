import 'package:flutter/material.dart';
import 'package:pivot/screens/section2/landing.dart';
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

  BoxDecoration _getDropdownDecoration(BuildContext context, bool isValid) {
    return BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(
        Responsive.space(context, size: Space.medium),
      ),
      border: Border.all(
        color: isValid ? Colors.green : Color(0xFFF7F7F7),
        width: isValid ? 2 : 1,
      ),
    );
  }

  TextStyle _getDropdownTextStyle(BuildContext context) {
    return TextStyle(
      color: Colors.white,
      fontSize: Responsive.text(context, size: TextSize.medium),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String? value,
    required List<String> items,
    required String hint,
    required bool isValid,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: _getDropdownDecoration(context, isValid),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: Colors.black,
        hint: Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: _getDropdownTextStyle(context),
          ),
        ),
        underline: Container(),
        items:
            items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        item,
                        textAlign: TextAlign.center,
                        style: _getDropdownTextStyle(context),
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
      ),
    );
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
                              child: _buildDropdown(
                                context: context,
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
                              child: _buildDropdown(
                                context: context,
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
                              child: _buildDropdown(
                                context: context,
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
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Handle form submission
                        Navigator.pushNamed(context, Landing.id);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: CircleBorder(),
                      minimumSize: Size(
                        Responsive.space(context, size: Space.xlarge) * 4,
                        Responsive.space(context, size: Space.xlarge) * 4,
                      ),
                      elevation: 5,
                    ),
                    child: Icon(
                      Icons.check,
                      size:
                          Responsive.text(context, size: TextSize.heading) *
                          1.5,
                      color: Colors.white,
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
}
