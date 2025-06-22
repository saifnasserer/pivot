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
  late TextEditingController _englishNameController;

  final List<String> _departments = ['CS', 'IS', 'AI', 'SC', 'General'];
  final List<int> _years = List.generate(8, (i) => i + 1);

  List<String> _selectedDepartments = [];
  int? _selectedYear;

  bool get _isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _codeController = TextEditingController(text: widget.subject?.code ?? '');
    _englishNameController = TextEditingController(
      text: widget.subject?.englishName ?? '',
    );

    if (_isEditing) {
      _selectedYear = widget.subject!.year;
      _selectedDepartments =
          _departments.contains(widget.subject!.department)
              ? [widget.subject!.department]
              : [];
    } else {
      _selectedYear = _years.first;
      _selectedDepartments = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _englishNameController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDepartments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار قسم واحد على الأقل')),
        );
        return;
      }
      final newSubject = Subject(
        id: widget.subject?.id ?? '',
        name: _nameController.text,
        code: _codeController.text,
        year: _selectedYear!,
        department: _selectedDepartments.first,
        englishName: _englishNameController.text,
        description: widget.subject?.description,
        enrolledStudents: widget.subject?.enrolledStudents ?? [],
        doctorId: widget.subject?.doctorId,
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
                hint: 'عدد الساعات',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال عدد الساعات';
                  }
                  return null;
                },
              ),
              SizedBox(height: Responsive.space(context)),
              CustomTextField(
                controller: _englishNameController,
                hint: 'Subject Name (English)',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the English name';
                  }
                  return null;
                },
              ),
              SizedBox(height: Responsive.space(context)),
              GestureDetector(
                onTap: () async {
                  final result = await showDialog<List<String>>(
                    context: context,
                    builder: (context) {
                      List<String> tempSelected = List.from(
                        _selectedDepartments,
                      );
                      return StatefulBuilder(
                        builder: (context, setDialogState) {
                          return AlertDialog(
                            title: const Text('اختر الأقسام'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView(
                                shrinkWrap: true,
                                children:
                                    _departments.map((dep) {
                                      return CheckboxListTile(
                                        value: tempSelected.contains(dep),
                                        title: Text(dep),
                                        onChanged: (checked) {
                                          setDialogState(() {
                                            if (checked == true) {
                                              tempSelected.add(dep);
                                            } else {
                                              tempSelected.remove(dep);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, null),
                                child: const Text('إلغاء'),
                              ),
                              ElevatedButton(
                                onPressed:
                                    () => Navigator.pop(context, tempSelected),
                                child: const Text('تم'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                  if (result != null) {
                    setState(() {
                      _selectedDepartments = result;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.medium),
                    ),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDepartments.isEmpty
                              ? 'اختر الأقسام'
                              : _selectedDepartments.join(', '),
                          style: TextStyle(
                            color:
                                _selectedDepartments.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
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
