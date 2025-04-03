import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pivot/screens/models/task.dart';

// Function to show the Add/Edit Task Dialog
Future<void> showAddTaskDialog({
  required BuildContext context,
  required String sectionId, // ID of the section the task belongs to
  required Function(Task) onSave, // Callback when task is saved
  Task? task, // Optional: Task object for editing
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap button!
    builder: (BuildContext dialogContext) {
      return _AddEditTaskDialogContent(
        sectionId: sectionId,
        onSave: onSave,
        task: task,
      );
    },
  );
}

// StatefulWidget for the dialog content to manage form state
class _AddEditTaskDialogContent extends StatefulWidget {
  final String sectionId;
  final Function(Task) onSave;
  final Task? task; // Existing task for editing

  const _AddEditTaskDialogContent({
    required this.sectionId,
    required this.onSave,
    this.task,
  });

  @override
  State<_AddEditTaskDialogContent> createState() =>
      _AddEditTaskDialogContentState();
}

class _AddEditTaskDialogContentState extends State<_AddEditTaskDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskImportance _selectedImportance;
  bool _isEditing = false;

  // Map TaskImportance enum values to display names
  final Map<TaskImportance, String> _importanceLabels = {
    TaskImportance.high: 'مهمه',
    TaskImportance.mid: 'نص نص',
    TaskImportance.low: 'عادي',
  };

  @override
  void initState() {
    super.initState();
    _isEditing = widget.task != null;

    // Initialize form fields based on whether we are editing or adding
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedDate =
        widget.task?.dueDate ??
        DateTime.now().add(const Duration(days: 1)); // Default to tomorrow
    _selectedImportance =
        widget.task?.importance ?? TaskImportance.mid; // Default to medium
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(), // Can't select past dates
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final newTask = Task(
        id: widget.task?.id, // Pass existing ID if editing, null otherwise
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDate,
        importance: _selectedImportance,
        sectionId: widget.sectionId,
        isCompleted:
            widget.task?.isCompleted ??
            false, // Retain completion status if editing
      );
      widget.onSave(newTask);
      Navigator.of(context).pop(); // Close the dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Consistent Styling Constants (borrowed from AddEditSectionDialog) ---
    final borderRadius = BorderRadius.circular(20);
    final inputPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 12.0,
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
      contentPadding: inputPadding,
      fillColor: Colors.grey.shade100,
      filled: true,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      labelStyle: TextStyle(
        color: Colors.black54,
        fontWeight: FontWeight.w500,
      ), // Added label style
    );
    final labelStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    // --- End Styling Constants ---

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ), // Consistent shape
      title: Text(
        _isEditing
            ? 'تعديل التاسك'
            : 'اضافة تاسك جديد', // More descriptive title
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        0,
      ), // Adjust padding
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'عنوان التاسك:',
                  style: labelStyle,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: commonDecoration.copyWith(
                    hintText: 'اكتب اسم التاسك',
                    // labelText: 'العنوان', // Label provided above
                  ),
                  textAlign: TextAlign.right,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اكتب اسم التاسك';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Text(
                  'تفاصيل التاسك:',
                  style: labelStyle,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: commonDecoration.copyWith(
                    hintText: 'أى تفاصيل إضافية...',
                    // labelText: 'تفاصيل التاسك', // Label provided above
                  ),
                  textAlign: TextAlign.right,
                  // maxLines: null, // Allow the field to expand vertically
                  // No validator needed for optional description
                ),
                const SizedBox(height: 16),

                Text(
                  'آخر ميعاد للتسليم:',
                  style: labelStyle,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                // --- Improved Date Picker ---
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: borderRadius,
                  child: InputDecorator(
                    decoration: commonDecoration.copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, dd MMMM yyyy',
                            'ar',
                          ).format(_selectedDate), // More detailed format
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Icon(
                          Icons.calendar_month_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                // --- End Improved Date Picker ---
                const SizedBox(height: 16),

                Text('الأهمية:', style: labelStyle, textAlign: TextAlign.right),
                const SizedBox(height: 8),
                DropdownButtonFormField<TaskImportance>(
                  value: _selectedImportance,
                  decoration: commonDecoration.copyWith(
                    // labelText: 'الاهمية', // Label provided above
                  ),
                  items:
                      TaskImportance.values.map((TaskImportance importance) {
                        return DropdownMenuItem<TaskImportance>(
                          value: importance,
                          child: Text(
                            _importanceLabels[importance] ??
                                'N/A', // Use mapped label
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyLarge, // Consistent style
                          ),
                        );
                      }).toList(),
                  onChanged: (TaskImportance? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedImportance = newValue;
                      });
                    }
                  },
                  isExpanded: true,
                ),
                const SizedBox(height: 24), // Add some space before actions
              ],
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween, // Space out buttons
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          child: const Text('إلغاء'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton.icon(
          icon: Icon(
            _isEditing
                ? Icons.save_alt_rounded
                : Icons.add_circle_outline_rounded,
          ),
          label: Text(_isEditing ? 'حفظ التعديلات' : 'إضافة التاسك'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 2,
          ),
          onPressed: _saveTask,
        ),
      ],
    );
  }
}
