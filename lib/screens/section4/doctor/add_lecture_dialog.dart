import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class AddLectureDialog extends StatefulWidget {
  final String subjectName;

  const AddLectureDialog({super.key, required this.subjectName});

  @override
  State<AddLectureDialog> createState() => _AddLectureDialogState();
}

class _AddLectureDialogState extends State<AddLectureDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Simulate a brief delay for better UX
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.of(context).pop(_titleController.text.trim());
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
      subtitle: 'إضافة محاضرة إلى مادة "${widget.subjectName}"',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Show the subject name as info
            Container(
              padding: Responsive.padding(context, size: Space.medium),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.medium),
                ),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: Colors.blue.shade700,
                    size: Responsive.text(context, size: TextSize.medium),
                  ),
                  SizedBox(width: Responsive.space(context, size: Space.small)),
                  Expanded(
                    child: Text(
                      'المادة: ${widget.subjectName}',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
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
