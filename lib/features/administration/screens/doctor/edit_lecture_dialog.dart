import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class EditLectureDialog extends StatefulWidget {
  final String currentTitle;
  final String subjectName;

  const EditLectureDialog({
    super.key,
    required this.currentTitle,
    required this.subjectName,
  });

  @override
  State<EditLectureDialog> createState() => _EditLectureDialogState();
}

class _EditLectureDialogState extends State<EditLectureDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
  }

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
      title: 'تعديل عنوان المحاضرة',
      subtitle: 'تعديل عنوان المحاضرة في مادة "${widget.subjectName}"',
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
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.medium),
                ),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: Colors.green.shade700,
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
                        color: Colors.green.shade700,
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
              label: 'عنوان المحاضرة الجديد',
              hint: 'أدخل العنوان الجديد للمحاضرة',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال عنوان المحاضرة';
                }
                if (value.trim().length < 3) {
                  return 'يجب أن يكون العنوان 3 أحرف على الأقل';
                }
                if (value.trim() == widget.currentTitle) {
                  return 'العنوان الجديد يجب أن يختلف عن العنوان الحالي';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      confirmText: _isSubmitting ? 'جاري التحديث...' : 'تحديث',
      confirmIcon: _isSubmitting ? Icons.hourglass_empty : Icons.edit,
      onConfirm: _isSubmitting ? null : _submit,
      onCancel: _isSubmitting ? null : () => Navigator.of(context).pop(),
    );
  }
}

