import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pivot/widgets/custom_text_field.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

/// Dialog for adding/editing personal tasks (not section-based)
Future<void> showAddPersonalTaskDialog({
  required BuildContext context,
  required Function(Task) onSave,
  Task? task,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _AddEditPersonalTaskDialogContent(onSave: onSave, task: task);
    },
  );
}

class _AddEditPersonalTaskDialogContent extends ConsumerStatefulWidget {
  final Function(Task) onSave;
  final Task? task;

  const _AddEditPersonalTaskDialogContent({required this.onSave, this.task});

  @override
  ConsumerState<_AddEditPersonalTaskDialogContent> createState() =>
      _AddEditPersonalTaskDialogContentState();
}

class _AddEditPersonalTaskDialogContentState
    extends ConsumerState<_AddEditPersonalTaskDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.task != null;
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedDate =
        widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _selectedDate,
        importance:
            TaskImportance.low, // Always set to low (normal) for personal tasks
        isPersonal: true, // Personal tasks are always true
        completedBy: widget.task?.completedBy ?? [],
      );

      widget.onSave(task);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDialog(
      title: _isEditing ? 'تعديل تاسك' : 'إضافة تاسك شخصي',
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _saveTask,
      confirmText: _isEditing ? 'حفظ' : 'إضافة',
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              CustomTextField(
                controller: _titleController,
                hint: 'عنوان التاسك',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال عنوان التاسك';
                  }
                  return null;
                },
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Description Field
              CustomTextField(
                controller: _descriptionController,
                hint: 'وصف التاسك (اختياري)',
                maxLines: 3,
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                child: Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                        size: Responsive.space(context, size: Space.medium),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        child: Text(
                          'موعد التسليم: ${intl.DateFormat('yyyy-MM-dd', 'ar').format(_selectedDate)}',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
