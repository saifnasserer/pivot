import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/custom_text_field.dart';

class BasicInfoStep extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String title;
  final String description;
  final Function(String) onTitleChanged;
  final Function(String) onDescriptionChanged;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const BasicInfoStep({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.title,
    required this.description,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: AnimatedBuilder(
            animation: slideAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: slideAnimation,
                child: Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: Responsive.padding(context, size: Space.large),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'المعلومات الأساسية',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.text(
                                            context,
                                            size: TextSize.heading,
                                          ) *
                                          1.2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Text(
                                    'أدخل العنوان والوصف للإعلان',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      color: Colors.blue[600],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Icon(
                              Icons.edit_note,
                              color: Colors.blue[700],
                              size:
                                  Responsive.space(context, size: Space.large) *
                                  1.5,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Title field
                      CustomTextField(
                        hint: 'العنوان',
                        controller: titleController,
                        onChanged: onTitleChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال العنوان';
                          }
                          if (value.length > 50) {
                            return 'العنوان طويل جداً (الحد الأقصى 50 حرف)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),

                      // Character count indicator
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${titleController.text.length}/50',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            color:
                                titleController.text.length > 45
                                    ? Colors.orange
                                    : titleController.text.length > 50
                                    ? Colors.red
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Description field - Larger fixed height
                      Container(
                        height:
                            Responsive.space(context, size: Space.large) * 15,
                        child: CustomTextField(
                          hint: 'الوصف',
                          controller: descriptionController,
                          onChanged: onDescriptionChanged,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال الوصف';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: null,
                          maxLines: null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
