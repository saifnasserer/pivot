import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/models/subject_model.dart';


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
  bool _isSubmitting = false;

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

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSubjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار مادة'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Simulate a brief delay for better UX
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.of(context).pop({
          'title': _titleController.text.trim(),
          'subjectId': _selectedSubjectId!,
        });
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
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
              label: 'عنوان المحاضرة',
              hint: 'أدخل عنوان المحاضرة',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال عنوان المحاضرة';
                }
                if (value.trim().length < 3) {
                  return 'يجب أن يكون العنوان 3 أحرف على الأقل';
                }
                return null;
              },
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            if (widget.subjects.isEmpty)
              Container(
                padding: Responsive.padding(context, size: Space.medium),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.medium),
                  ),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
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
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
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
                    (value) => value == null ? 'يرجى اختيار المادة' : null,
              ),
          ],
        ),
      ),
      confirmText: _isSubmitting ? 'جاري الإضافة...' : 'إضافة',
      confirmIcon: _isSubmitting ? Icons.hourglass_empty : Icons.add,
      onConfirm: _isSubmitting ? null : _submit,
      onCancel: _isSubmitting ? null : () => Navigator.of(context).pop(),
    );
  }
}
