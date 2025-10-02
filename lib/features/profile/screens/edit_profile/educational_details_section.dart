import 'package:flutter/material.dart';
import 'package:pivot/widgets/custom_dropdown.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/features/profile/providers/edit_profile_provider.dart';
import 'package:pivot/responsive.dart';

class EducationalDetailsSection extends StatelessWidget {
  final EditProfileState state;
  final String? selectedYear;
  final String? selectedDepartment;
  final String? selectedSection;
  final List<String> availableDepartments;
  final List<String> availableSections;
  final Function(String?) onYearChanged;
  final Function(String?) onDepartmentChanged;
  final Function(String?) onSectionChanged;

  const EducationalDetailsSection({
    super.key,
    required this.state,
    required this.selectedYear,
    required this.selectedDepartment,
    required this.selectedSection,
    required this.availableDepartments,
    required this.availableSections,
    required this.onYearChanged,
    required this.onDepartmentChanged,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomDropdown(
          color: Colors.grey[50]!,
          value: selectedYear,
          items: FormOptions.academicYears,
          hint: 'اختر الفرقة',
          onChanged: onYearChanged,
          errorText: state.fieldErrors['level'],
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        CustomDropdown(
          color: Colors.grey[50]!,
          value: selectedDepartment,
          items: availableDepartments,
          hint: 'اختر القسم',
          onChanged: onDepartmentChanged,
          errorText: state.fieldErrors['department'],
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        CustomDropdown(
          color: Colors.grey[50]!,
          value: selectedSection,
          items: availableSections,
          hint: 'اختر السكشن',
          onChanged: onSectionChanged,
          errorText: state.fieldErrors['section'],
        ),
      ],
    );
  }
}
