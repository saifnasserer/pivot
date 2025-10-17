import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/task.dart';

class FormFieldsFeature {
  /// Build title field
  Widget buildTitleField({
    required BuildContext context,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    final borderRadius = BorderRadius.circular(
      Responsive.space(context, size: Space.large),
    );
    final commonDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      fillColor: Colors.grey.shade100,
      filled: true,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontWeight: FontWeight.w500,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'عنوان التاسك:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.right,
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        TextFormField(
          controller: controller,
          decoration: commonDecoration.copyWith(hintText: 'اكتب اسم التاسك'),
          textAlign: TextAlign.right,
          validator: validator,
        ),
      ],
    );
  }

  /// Build description field
  Widget buildDescriptionField({
    required BuildContext context,
    required TextEditingController controller,
  }) {
    final borderRadius = BorderRadius.circular(
      Responsive.space(context, size: Space.large),
    );
    final commonDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      fillColor: Colors.grey.shade100,
      filled: true,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontWeight: FontWeight.w500,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفاصيل التاسك:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.right,
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        TextFormField(
          controller: controller,
          decoration: commonDecoration.copyWith(
            hintText: 'أى تفاصيل إضافية...',
          ),
          textAlign: TextAlign.right,
          maxLines: 2,
        ),
      ],
    );
  }

  /// Build due date field
  Widget buildDueDateField({
    required BuildContext context,
    required DateTime selectedDate,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تاريخ التسليم:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.right,
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.large),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.blue.shade700,
                    size: Responsive.space(context, size: Space.medium),
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'آخر ميعاد للتسليم',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        intl.DateFormat(
                          'dd/MM/yyyy',
                          'ar',
                        ).format(selectedDate),
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build importance field
  Widget buildImportanceField({
    required BuildContext context,
    required TaskImportance selectedImportance,
    required Function(TaskImportance) onChanged,
  }) {
    final Map<TaskImportance, String> importanceLabels = {
      TaskImportance.high: 'مهمه',
      TaskImportance.mid: 'نص نص',
      TaskImportance.low: 'عادي',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأهمية:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.right,
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        Container(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getImportanceColor(selectedImportance).withOpacity(0.1),
                _getImportanceColor(selectedImportance).withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _getImportanceColor(selectedImportance).withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            boxShadow: [
              BoxShadow(
                color: _getImportanceColor(selectedImportance).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      Responsive.space(context, size: Space.small),
                    ),
                    decoration: BoxDecoration(
                      color: _getImportanceColor(
                        selectedImportance,
                      ).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      color: _getImportanceColor(selectedImportance),
                      size: Responsive.space(context, size: Space.medium),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        importanceLabels[selectedImportance] ?? 'N/A',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'أولوية التاسك',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<TaskImportance>(
                initialValue: selectedImportance,
                onSelected: onChanged,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: _getImportanceColor(selectedImportance),
                  size: Responsive.space(context, size: Space.large),
                ),
                itemBuilder:
                    (BuildContext context) =>
                        TaskImportance.values.map((TaskImportance importance) {
                          return PopupMenuItem<TaskImportance>(
                            value: importance,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag_rounded,
                                  color: _getImportanceColor(importance),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  importanceLabels[importance] ?? 'N/A',
                                  style: TextStyle(
                                    fontWeight:
                                        importance == selectedImportance
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get importance color
  Color _getImportanceColor(TaskImportance importance) {
    switch (importance) {
      case TaskImportance.high:
        return Colors.red.shade400;
      case TaskImportance.mid:
        return Colors.amber.shade600;
      case TaskImportance.low:
        return Colors.green.shade400;
    }
  }
}
