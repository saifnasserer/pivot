import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/profile/providers/edit_profile_provider.dart';
import 'package:pivot/responsive.dart';

class ActionButtons extends ConsumerWidget {
  final EditProfileState state;
  final WidgetRef widgetRef;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;

  const ActionButtons({
    super.key,
    required this.state,
    required this.widgetRef,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.isSaving
        ? Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              Text(
                'يتم حفظ التغييرات...',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        )
        : Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        state.hasUnsavedChanges
                            ? [Colors.green[400]!, Colors.green[600]!]
                            : [Colors.grey[300]!, Colors.grey[400]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      state.hasUnsavedChanges
                          ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [],
                ),
                child: ElevatedButton(
                  onPressed:
                      state.isFormValid && state.hasUnsavedChanges
                          ? () {
                            widgetRef
                                .read(editProfileProvider.notifier)
                                .saveProfile(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    state.hasUnsavedChanges
                        ? 'حفظ التغييرات'
                        : 'لا توجد تغييرات',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.text(context, size: TextSize.medium),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: Responsive.space(context, size: Space.medium)),
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.text(context, size: TextSize.medium),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
  }
}
