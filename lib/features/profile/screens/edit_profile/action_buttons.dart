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
          state.isSaving
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
                          state.isFormValid && state.hasUnsavedChanges
                              ? () {
                                widgetRef
                                    .read(editProfileProvider.notifier)
                                    .saveProfile(
                                      currentPassword:
                                          currentPasswordController
                                                  .text
                                                  .isNotEmpty
                                              ? currentPasswordController.text
                                              : null,
                                      newPassword:
                                          newPasswordController.text.isNotEmpty
                                              ? newPasswordController.text
                                              : null,
                                      confirmPassword:
                                          confirmPasswordController
                                                  .text
                                                  .isNotEmpty
                                              ? confirmPasswordController.text
                                              : null,
                                    );
                              }
                              : null,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        state.hasUnsavedChanges
                            ? 'حفظ التغييرات'
                            : 'لا توجد تغييرات',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            state.hasUnsavedChanges
                                ? Colors.green[600]
                                : Colors.grey[400],
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
