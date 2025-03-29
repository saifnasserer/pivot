import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:pivot/screens/models/custom_dropdown.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});
  static final String id = 'edit';

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode yearFocusNode = FocusNode();
  final FocusNode departFocusNode = FocusNode();
  final FocusNode sectionFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  // Dropdown values
  String? selectedYear;
  String? selectedDepartment;
  String? selectedSection;

  // Validation flags
  bool _isYearValid = false;
  bool _isDepartmentValid = false;
  bool _isSectionValid = false;
  bool _isNameValid = false;
  // Dropdown options
  final List<String> years = ['الأولى', 'الثانية', 'الثالثة', 'الرابعة'];
  final List<String> departments = ['CS', 'IS', 'IT', 'SC'];
  final List<String> sections = ['1', '2', '3', '4', '5', '6', '7', '8'];
  @override
  void dispose() {
    nameFocusNode.dispose();
    yearFocusNode.dispose();
    departFocusNode.dispose();
    sectionFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
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

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال الاسم';
    }
    return null;
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: Responsive.space(context, size: Space.large) * 5,
                  backgroundColor: Colors.black,
                  child: Image.asset('assets/icon.png'),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                CustomTextField(
                  focusNode: nameFocusNode,
                  hint: 'الاسم',
                  keyboardType: TextInputType.name,
                  onChanged: (value) {
                    setState(() {
                      _isNameValid = _validateName(value) == null;
                    });
                  },
                  validator: (value) {
                    return _validateName(value);
                  },
                  isValid: _isNameValid,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                CustomDropdown(
                  color: Color(0xfff7f7f7),
                  value: selectedYear,
                  items: years,
                  hint: 'اختر الفرقة',
                  isValid: _isYearValid,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedYear = newValue;
                      _isYearValid = newValue != null;
                    });
                    FocusScope.of(context).requestFocus(departFocusNode);
                  },
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                CustomDropdown(
                  color: Color(0xfff7f7f7),
                  value: selectedDepartment,
                  items: departments,
                  hint: 'اختر القسم',
                  isValid: _isDepartmentValid,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedDepartment = newValue;
                      _isDepartmentValid = newValue != null;
                    });
                    FocusScope.of(context).requestFocus(sectionFocusNode);
                  },
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                CustomDropdown(
                  color: Color(0xfff7f7f7),
                  value: selectedSection,
                  items: sections,
                  hint: 'اختر السكشن',
                  isValid: _isSectionValid,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSection = newValue;
                      _isSectionValid = newValue != null;
                    });
                    FocusScope.of(context).requestFocus(passwordFocusNode);
                  },
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                CustomTextField(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: Responsive.text(context, size: TextSize.medium),
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  focusNode: passwordFocusNode,
                  hint: 'الباسورد',
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: !_isPasswordVisible,
                  onChanged: (value) {},
                  validator: (value) {
                    return _validatePassword(value);
                  },
                  isValid: false,
                ),
                SizedBox(height: Responsive.space(context, size: Space.large)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CircularButton(
                      onPressed: () {
                        // Validate all fields
                        bool isFormValid =
                            _isNameValid &&
                            _isYearValid &&
                            _isDepartmentValid &&
                            _isSectionValid;

                        if (isFormValid) {
                          // All fields are valid, show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم حفظ البيانات بنجاح')),
                          );

                          // Here you would save to database when implemented
                          // saveUserProfile();

                          // Navigate back
                          Navigator.pop(context);
                        } else {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('يرجى ملء البيانات بشكل صحيح'),
                            ),
                          );
                        }
                      },
                      icon: Icons.check,
                    ),
                    CircularButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icons.close,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
