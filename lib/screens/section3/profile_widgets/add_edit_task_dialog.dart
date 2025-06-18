import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;
import 'package:pivot/screens/models/custom_dropdown.dart';
import 'package:pivot/screens/models/custom_text_field.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedDate = widget.task?.dueDate ?? DateTime.now();
    _selectedImportance = widget.task?.importance ?? TaskImportance.mid;
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
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          widget.task == null ? 'إضافة مهمة شخصية' : 'تعديل المهمة',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _titleController,
                  hint: 'العنوان',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال عنوان للمهمة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  hint: 'التفاصيل',
                  maxLines: 3,
                  minLines: 3,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () => _selectDate(context),
                    title: const Text('تاريخ النهاية'),
                    subtitle: Text(
                      DateFormat.yMMMd('ar').format(_selectedDate),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomDropdown(
                  hint: 'الأهمية',
                  color: const Color(0xFFF7F7F7),
                  value: _getImportanceArabicName(_selectedImportance),
                  items:
                      TaskImportance.values
                          .map((imp) => _getImportanceArabicName(imp))
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
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _saveForm, child: const Text('حفظ')),
        ],
        actionsAlignment: MainAxisAlignment.end,
      ),
    );
  }
}
