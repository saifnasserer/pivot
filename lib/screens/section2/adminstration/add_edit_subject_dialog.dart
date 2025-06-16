import 'package:flutter/material.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/custom_text_field.dart';

Future<Subject?> showAddEditSubjectDialog(
  BuildContext context, {
  Subject? subject,
}) {
  return showDialog<Subject>(
    context: context,
    builder: (context) {
      return AddEditSubjectDialog(subject: subject);
    },
  );
}

class AddEditSubjectDialog extends StatefulWidget {
  final Subject? subject;

  const AddEditSubjectDialog({super.key, this.subject});

  @override
  State<AddEditSubjectDialog> createState() => _AddEditSubjectDialogState();
}

class _AddEditSubjectDialogState extends State<AddEditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;

  final List<String> _departments = ['CS', 'IS', 'AI', 'SC', 'General'];
  final List<int> _years = List.generate(8, (i) => i + 1);

  String? _selectedDepartment;
  int? _selectedYear;

  bool get _isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _codeController = TextEditingController(text: widget.subject?.code ?? '');

    if (_isEditing) {
      _selectedYear = widget.subject!.year;
      _selectedDepartment =
          _departments.contains(widget.subject!.department)
              ? widget.subject!.department
              : null;
    } else {
      _selectedYear = _years.first;
      _selectedDepartment = _departments.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final newSubject = Subject(
        id: widget.subject?.id ?? '',
        name: _nameController.text,
        code: _codeController.text,
        year: _selectedYear!,
        department: _selectedDepartment!,
      );
      Navigator.of(context).pop(newSubject);
    }
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: const BorderSide(color: Color(0xFFF7F7F7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: const BorderSide(color: Color(0xFFF7F7F7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: const BorderSide(color: Colors.black),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل المادة' : 'إضافة مادة',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: Responsive.text(context, size: TextSize.heading),
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _nameController,
                hint: 'اسم المادة',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم';
                  }
                  return null;
                },
              ),
              SizedBox(height: Responsive.space(context)),
              CustomTextField(
                controller: _codeController,
                hint: 'كود المادة',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال كود';
                  }
                  return null;
                },
              ),
              SizedBox(height: Responsive.space(context)),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                hint: const Text('القسم'),
                items:
                    _departments.map((String department) {
                      return DropdownMenuItem<String>(
                        value: department,
                        child: Text(department),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                  });
                },
                decoration: _getInputDecoration('القسم'),
                validator:
                    (value) => value == null ? 'الرجاء اختيار قسم' : null,
              ),
              SizedBox(height: Responsive.space(context)),
              DropdownButtonFormField<int>(
                value: _selectedYear,
                hint: const Text('الفصل الدراسي'),
                items:
                    _years.map((int year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text('الفصل الدراسي $year'),
                      );
                    }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedYear = newValue;
                    });
                  }
                },
                decoration: _getInputDecoration('الفصل الدراسي'),
                validator:
                    (value) => value == null ? 'الرجاء اختيار فصل دراسي' : null,
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          onPressed: _onSave,
          child: const Text('حفظ', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
