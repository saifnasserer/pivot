import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/widgets/custom_dropdown.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/features/profile/providers/edit_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/custom_text_field.dart';

class BasicInfoSection extends ConsumerWidget {
  final EditProfileState state;
  final TextEditingController nameController;
  final String? selectedGender;
  final Function(String?) onGenderChanged;

  const BasicInfoSection({
    super.key,
    required this.state,
    required this.nameController,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        CustomTextField(
          controller: nameController,
          hint: 'الاسم',
          keyboardType: TextInputType.name,
          onChanged:
              (value) => ref
                  .read(editProfileProvider.notifier)
                  .updateBasicInfo(value, selectedGender ?? ''),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الاسم مطلوب';
            }
            return null;
          },
          errorText: state.fieldErrors['name'],
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        CustomDropdown(
          color: Colors.grey[50]!,
          value: selectedGender,
          items: FormOptions.genders,
          hint: 'النوع',
          onChanged: onGenderChanged,
          errorText: state.fieldErrors['gender'],
        ),
      ],
    );
  }
}
