import 'package:flutter/material.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/responsive.dart';

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
    final borderRadius = BorderRadius.circular(
      Responsive.space(context, size: Space.large),
    );
    final commonDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      fillColor: Colors.grey.shade100,
      filled: true,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      title: Text(
        'إضافة محاضرة جديدة',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextFormField(
                controller: _titleController,
                decoration: commonDecoration.copyWith(
                  labelText: 'العنوان',

                  alignLabelWithHint: true,
                ),
                textAlign: TextAlign.right,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال العنوان';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            if (widget.subjects.isEmpty)
              const Text('لا يوجد مواد متاحة للإضافة')
            else
              Directionality(
                textDirection: TextDirection.rtl,
                child: DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: commonDecoration.copyWith(
                    labelText: 'المادة',
                    alignLabelWithHint: true,
                  ),
                  items:
                      widget.subjects.map((Subject subject) {
                        return DropdownMenuItem<String>(
                          value: subject.id,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              subject.name,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSubjectId = newValue;
                    });
                  },
                  validator:
                      (value) => value == null ? 'يرجى إختيار المادة' : null,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  selectedItemBuilder:
                      (context) =>
                          widget.subjects.map((subject) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                subject.name,
                                textAlign: TextAlign.right,
                              ),
                            );
                          }).toList(),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          child: const Text('إلغاء'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.medium),
              vertical: Responsive.space(context, size: Space.small),
            ),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: _submit,
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
