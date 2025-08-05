import 'package:flutter/material.dart';

import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/custom_dropdown.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:pivot/data/form_options.dart';
import 'edit_profile_provider.dart';

class BasicInfoSection extends StatelessWidget {
  final EditProfileProvider provider;
  final TextEditingController nameController;
  final String? selectedGender;
  final Function(String?) onGenderChanged;

  const BasicInfoSection({
    super.key,
    required this.provider,
    required this.nameController,
    required this.selectedGender,
    required this.onGenderChanged,
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
              Icon(Icons.person_outline, color: Colors.blue[600], size: 24),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'المعلومات الأساسية',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          CustomTextField(
            controller: nameController,
            hint: 'الاسم',
            keyboardType: TextInputType.name,
            onChanged:
                (value) =>
                    provider.updateBasicInfo(value, selectedGender ?? ''),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الاسم مطلوب';
              }
              return null;
            },
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          CustomDropdown(
            color: const Color(0xfff7f7f7),
            value: selectedGender,
            items: FormOptions.genders,
            hint: 'النوع',
            onChanged: onGenderChanged,
          ),
        ],
      ),
    );
  }
}
