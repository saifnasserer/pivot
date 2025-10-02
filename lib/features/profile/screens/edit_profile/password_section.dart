import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/custom_text_field.dart';
import 'package:pivot/features/profile/providers/edit_profile_provider.dart';

class PasswordSection extends StatefulWidget {
  final EditProfileState state;
  final WidgetRef widgetRef;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;

  const PasswordSection({
    super.key,
    required this.state,
    required this.widgetRef,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
  });

  @override
  State<PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends State<PasswordSection> {
  bool _isPasswordVisible = false;
  bool _isCurrentPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple text label for password section
        Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.space(context, size: Space.small),
          ),
          child: Text(
            'تغيير كلمة المرور (اختياري)',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        CustomTextField(
          controller: widget.currentPasswordController,
          hint: 'كلمة المرور الحالية',
          keyboardType: TextInputType.visiblePassword,
          obscureText: !_isCurrentPasswordVisible,
          onChanged:
              (value) =>
                  widget.widgetRef
                      .read(editProfileProvider.notifier)
                      .markPasswordAsChanged(),
          suffixIcon: IconButton(
            icon: Icon(
              _isCurrentPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
              });
            },
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        CustomTextField(
          controller: widget.newPasswordController,
          hint: 'كلمة المرور الجديدة',
          keyboardType: TextInputType.visiblePassword,
          obscureText: !_isPasswordVisible,
          onChanged:
              (value) =>
                  widget.widgetRef
                      .read(editProfileProvider.notifier)
                      .markPasswordAsChanged(),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        CustomTextField(
          controller: widget.confirmPasswordController,
          hint: 'تأكيد كلمة المرور الجديدة',
          keyboardType: TextInputType.visiblePassword,
          obscureText: !_isConfirmPasswordVisible,
          onChanged:
              (value) =>
                  widget.widgetRef
                      .read(editProfileProvider.notifier)
                      .markPasswordAsChanged(),
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
        ),
      ],
    );
  }
}
