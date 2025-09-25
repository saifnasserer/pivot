import 'package:flutter/material.dart';

import 'package:pivot/widgets/custom_dropdown.dart';
import 'package:pivot/data/form_options.dart';
import 'edit_profile_provider.dart';
import 'package:pivot/responsive.dart';


class EducationalDetailsSection extends StatelessWidget {
  final EditProfileProvider provider;
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
    required this.provider,
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, color: Colors.green[600], size: 24),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'التفاصيل الدراسية',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          CustomDropdown(
            color: const Color(0xfff7f7f7),
            value: selectedYear,
            items: FormOptions.academicYears,
            hint: 'اختر الفرقة',
            onChanged: onYearChanged,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          CustomDropdown(
            color: const Color(0xfff7f7f7),
            value: selectedDepartment,
            items: availableDepartments,
            hint: 'اختر القسم',
            onChanged: onDepartmentChanged,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          CustomDropdown(
            color: const Color(0xfff7f7f7),
            value: selectedSection,
            items: availableSections,
            hint: 'اختر السكشن',
            onChanged: onSectionChanged,
          ),
        ],
      ),
    );
  }
}
