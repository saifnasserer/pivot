import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class AddEditTaskDialog extends StatefulWidget {
  final Task? task;
  final bool isPersonal;

  const AddEditTaskDialog({super.key, this.task, this.isPersonal = false});

  @override
  State<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends State<AddEditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskImportance _selectedImportance;
  List<Map<String, String>> attachments = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedDate = widget.task?.dueDate ?? DateTime.now();
    _selectedImportance = widget.task?.importance ?? TaskImportance.mid;
    if (widget.task != null && widget.task!.attachments != null) {
      attachments = List<Map<String, String>>.from(widget.task!.attachments!);
    }
  }

  @override
  void didUpdateWidget(covariant AddEditTaskDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task != null && widget.task != oldWidget.task) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.dueDate;
      _selectedImportance = widget.task!.importance;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final newTask = Task(
        id: widget.task?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _selectedDate,
        importance: _selectedImportance,
        isPersonal: widget.isPersonal,
        completedBy: widget.task?.completedBy ?? [],
        sectionId: widget.task?.sectionId,
        subjectId: widget.task?.subjectId,
        assistantId: widget.task?.assistantId,
        attachments: attachments,
      );
      Navigator.of(context).pop(newTask);
    }
  }

  String _getImportanceArabicName(TaskImportance importance) {
    switch (importance) {
      case TaskImportance.high:
        return 'عالية';
      case TaskImportance.mid:
        return 'متوسطة';
      case TaskImportance.low:
        return 'منخفضة';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDialog(
      title: widget.task == null ? 'إضافة تاسك شخصية' : 'تعديل التاسك',
      subtitle:
          widget.task == null
              ? 'أدخل بيانات التاسك الجديدة'
              : 'قم بتعديل بيانات التاسك',
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'العنوان',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      borderSide: BorderSide(color: Color(0xFFF7F7F7)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال عنوان للتاسك';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Description Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'التفاصيل',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      borderSide: BorderSide(color: Color(0xFFF7F7F7)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 3,
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Due Date Selection
              Text(
                'تاريخ النهاية',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    color: Color(0xFFF7F7F7),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.black,
                        size: Responsive.space(context, size: Space.medium),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat.yMMMd('ar').format(_selectedDate),
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Importance Dropdown
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _getImportanceArabicName(_selectedImportance),
                  items:
                      TaskImportance.values
                          .map((imp) => _getImportanceArabicName(imp))
                          .toList()
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedImportance = TaskImportance.values.firstWhere(
                          (e) => _getImportanceArabicName(e) == newValue,
                        );
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'الأهمية',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      borderSide: BorderSide(color: Color(0xFFF7F7F7)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  alignment: Alignment.centerRight,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      confirmText: widget.task == null ? 'إضافة التاسك' : 'حفظ التعديلات',
      confirmIcon:
          widget.task == null
              ? Icons.add_circle_outline
              : Icons.save_alt_rounded,
      onConfirm: _saveForm,
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
