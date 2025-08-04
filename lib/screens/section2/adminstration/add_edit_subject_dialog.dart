import 'package:flutter/material.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
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
  late TextEditingController _hoursController;
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
    _hoursController = TextEditingController(
      text: widget.subject?.hours.toString() ?? '',
    );
    _englishNameController = TextEditingController(
      text: widget.subject?.englishName ?? '',
    );

    if (_isEditing) {
      _selectedYear = widget.subject!.year;
      _selectedDepartments =
          widget.subject!.departments
              .where((d) => _departments.contains(d))
              .toList();
    } else {
      _selectedYear = _years.first;
      _selectedDepartments = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hoursController.dispose();
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
      final hours = int.tryParse(_hoursController.text);
      if (hours == null || hours <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال عدد ساعات صحيح')),
        );
        return;
      }
      final newSubject = Subject(
        id: widget.subject?.id ?? '',
        name: _nameController.text,
        hours: hours,
        year: _selectedYear!,
        departments: List<String>.from(_selectedDepartments),
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
    return UnifiedDialog(
      title: _isEditing ? 'تعديل المادة' : 'إضافة مادة',
      subtitle:
          _isEditing ? 'تعديل معلومات المادة' : 'أدخل معلومات المادة الجديدة',
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
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
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              CustomTextField(
                controller: _hoursController,
                hint: 'عدد الساعات',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال عدد الساعات';
                  }
                  final hours = int.tryParse(value);
                  if (hours == null || hours <= 0) {
                    return 'الرجاء إدخال عدد ساعات صحيح';
                  }
                  return null;
                },
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
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
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              GestureDetector(
                onTap: () async {
                  final result = await showDialog<List<String>>(
                    context: context,
                    builder: (context) {
                      List<String> tempSelected = List.from(
                        _selectedDepartments,
                      );
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return UnifiedDialog(
                            title: 'اختر الأقسام',
                            subtitle: 'حدد الأقسام المرتبطة بالمادة',
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
                                          setState(() {
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
                            confirmText: 'تم',
                            confirmIcon: Icons.check,
                            onConfirm:
                                () => Navigator.pop(context, tempSelected),
                            onCancel:
                                () => Navigator.pop(
                                  context,
                                  _selectedDepartments,
                                ),
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
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              UnifiedDropdownField<int>(
                value: _selectedYear,
                items: _years,
                itemToString: (year) => 'الفصل الدراسي $year',
                hint: 'اختر الفصل الدراسي',
                label: 'الفصل الدراسي',
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedYear = newValue;
                    });
                  }
                },
                validator:
                    (value) => value == null ? 'الرجاء اختيار فصل دراسي' : null,
              ),
            ],
          ),
        ),
      ),
      confirmText: 'حفظ',
      confirmIcon: Icons.save,
      onConfirm: _onSave,
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
