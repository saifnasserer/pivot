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
              Icon(Icons.lock_outline, color: Colors.orange[600], size: 24),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'إعدادات كلمة المرور',
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
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey,
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
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
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
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
