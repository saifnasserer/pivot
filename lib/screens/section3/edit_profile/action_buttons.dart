import 'package:flutter/material.dart';

import 'package:pivot/responsive.dart';
import 'edit_profile_provider.dart';

class ActionButtons extends StatelessWidget {
  final EditProfileProvider provider;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;

  const ActionButtons({
    super.key,
    required this.provider,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
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
      child:
          provider.isSaving
              ? Column(
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),
                  Text(
                    'يتم حفظ التغييرات...',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          provider.isFormValid
                              ? () {
                                provider.saveProfile(
                                  currentPassword:
                                      currentPasswordController.text.isNotEmpty
                                          ? currentPasswordController.text
                                          : null,
                                  newPassword:
                                      newPasswordController.text.isNotEmpty
                                          ? newPasswordController.text
                                          : null,
                                  confirmPassword:
                                      confirmPasswordController.text.isNotEmpty
                                          ? confirmPasswordController.text
                                          : null,
                                );
                              }
                              : null,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        'حفظ التغييرات',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: Text(
                        'إلغاء',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
