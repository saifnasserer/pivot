import 'package:flutter/material.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class AddSubjectLinkDialog extends StatefulWidget {
  final List<Subject> subjects;

  const AddSubjectLinkDialog({super.key, required this.subjects});

  @override
  State<AddSubjectLinkDialog> createState() => _AddSubjectLinkDialogState();
}

class _AddSubjectLinkDialogState extends State<AddSubjectLinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      _selectedSubjectId = widget.subjects.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSubjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a subject')),
        );
        return;
      }
      Navigator.of(context).pop({
        'title': _titleController.text.trim(),
        'subjectId': _selectedSubjectId!,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDialog(
      title: 'إضافة محاضرة جديدة',
      subtitle: 'أدخل معلومات المحاضرة',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            UnifiedFormField(
              controller: _titleController,
              label: 'العنوان',
              hint: 'أدخل عنوان المحاضرة',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال العنوان';
                }
                return null;
              },
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            if (widget.subjects.isEmpty)
              Container(
                padding: Responsive.padding(context, size: Space.medium),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange,
                      size: Responsive.text(context, size: TextSize.medium),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Expanded(
                      child: Text(
                        'لا يوجد مواد متاحة للإضافة',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              UnifiedDropdownField<String>(
                value: _selectedSubjectId,
                items: widget.subjects.map((subject) => subject.id).toList(),
                itemToString:
                    (subjectId) =>
                        widget.subjects
                            .firstWhere((s) => s.id == subjectId)
                            .name,
                hint: 'اختر المادة',
                label: 'المادة',
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSubjectId = newValue;
                  });
                },
                validator:
                    (value) => value == null ? 'يرجى إختيار المادة' : null,
              ),
          ],
        ),
      ),
      confirmText: 'إضافة',
      confirmIcon: Icons.add,
      onConfirm: _submit,
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
