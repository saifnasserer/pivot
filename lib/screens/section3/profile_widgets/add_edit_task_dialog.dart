import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';


class AddEditTaskDialog extends StatefulWidget {
  final Task? task;
  final bool isPersonal;

  const AddEditTaskDialog({super.key, this.task, this.isPersonal = false});

  @override
  State<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends State<AddEditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskImportance _selectedImportance;
  List<Map<String, String>> attachments = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedDate = widget.task?.dueDate ?? DateTime.now();
    _selectedImportance = widget.task?.importance ?? TaskImportance.mid;
    if (widget.task != null && widget.task!.attachments != null) {
      attachments = List<Map<String, String>>.from(widget.task!.attachments!);
    }
  }

  @override
  void didUpdateWidget(covariant AddEditTaskDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task != null && widget.task != oldWidget.task) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.dueDate;
      _selectedImportance = widget.task!.importance;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final newTask = Task(
        id: widget.task?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _selectedDate,
        importance: _selectedImportance,
        isPersonal: widget.isPersonal,
        completedBy: widget.task?.completedBy ?? [],
        sectionId: widget.task?.sectionId,
        subjectId: widget.task?.subjectId,
        assistantId: widget.task?.assistantId,
        attachments: attachments,
      );
      Navigator.of(context).pop(newTask);
    }
  }

  String _getImportanceArabicName(TaskImportance importance) {
    switch (importance) {
      case TaskImportance.high:
        return 'عالية';
      case TaskImportance.mid:
        return 'متوسطة';
      case TaskImportance.low:
        return 'منخفضة';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
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

  @override
  Widget build(BuildContext context) {
    return UnifiedDialog(
      title: widget.task == null ? 'إضافة تاسك شخصية' : 'تعديل التاسك',
      subtitle:
          widget.task == null
              ? 'أدخل بيانات التاسك الجديدة'
              : 'قم بتعديل بيانات التاسك',
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'العنوان',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      borderSide: BorderSide(color: Color(0xFFF7F7F7)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال عنوان للتاسك';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Description Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'التفاصيل',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      borderSide: BorderSide(color: Color(0xFFF7F7F7)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 3,
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Due Date Selection
              Text(
                'تاريخ النهاية',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    color: Color(0xFFF7F7F7),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.black,
                        size: Responsive.space(context, size: Space.medium),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat.yMMMd('ar').format(_selectedDate),
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Importance Dropdown
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonFormField<String>(
                  value: _getImportanceArabicName(_selectedImportance),
                  items:
                      TaskImportance.values
                          .map((imp) => _getImportanceArabicName(imp))
                          .toList()
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedImportance = TaskImportance.values.firstWhere(
                          (e) => _getImportanceArabicName(e) == newValue,
                        );
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'الأهمية',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      borderSide: BorderSide(color: Color(0xFFF7F7F7)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  alignment: Alignment.centerRight,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Attachments Section
              Text(
                'المرفقات:',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),

              // Existing Attachments
              ...attachments.map(
                (att) => Container(
                  margin: EdgeInsets.only(
                    bottom: Responsive.space(context, size: Space.small),
                  ),
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.attach_file,
                      color: Colors.black,
                      size: Responsive.space(context, size: Space.medium),
                    ),
                    title: Text(
                      att['title'] ?? '',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      att['url'] ?? '',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      final url = att['url'];
                      if (url != null) {
                        // Open the URL (use url_launcher if needed)
                      }
                    },
                  ),
                ),
              ),

              // Add Attachment Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ElevatedButton.icon(
                  icon: Icon(
                    Icons.attach_file,
                    size: Responsive.space(context, size: Space.medium),
                  ),
                  label: Text(
                    'إرفاق ملف/صورة',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.medium),
                      vertical: Responsive.space(context, size: Space.small),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                    ),
                  ),
                  onPressed: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles();
                    if (result != null && result.files.single.path != null) {
                      final file = File(result.files.single.path!);
                      final fileName = result.files.single.name;
                      // Upload to Firebase Storage
                      final storageRef = firebase_storage
                          .FirebaseStorage
                          .instance
                          .ref()
                          .child(
                            'tasks/attachments/${DateTime.now().millisecondsSinceEpoch}_$fileName',
                          );
                      final uploadTask = storageRef.putFile(file);
                      final snapshot = await uploadTask.whenComplete(() {});
                      final downloadUrl = await snapshot.ref.getDownloadURL();
                      // Ask user for a title or use file name
                      String? linkTitle = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          String tempTitle = fileName;
                          final TextEditingController controller =
                              TextEditingController(text: fileName);
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.large),
                              ),
                            ),
                            backgroundColor: Colors.white,
                            title: Column(
                              children: [
                                Text(
                                  'تعديل اسم الملف',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.heading,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Text(
                                  'أدخل اسم الملف كما تريد أن يظهر في التاسك',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // File info card
                                Container(
                                  padding: EdgeInsets.all(
                                    Responsive.space(
                                      context,
                                      size: Space.medium,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(
                                      Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.attach_file,
                                        color: Colors.black,
                                        size: Responsive.space(
                                          context,
                                          size: Space.medium,
                                        ),
                                      ),
                                      SizedBox(
                                        width: Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'الملف المرفوع:',
                                              style: TextStyle(
                                                fontSize: Responsive.text(
                                                  context,
                                                  size: TextSize.small,
                                                ),
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              fileName,
                                              style: TextStyle(
                                                fontSize: Responsive.text(
                                                  context,
                                                  size: TextSize.medium,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.large,
                                  ),
                                ),

                                // Input field
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: 'أدخل اسم الملف الجديد',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          Responsive.space(
                                            context,
                                            size: Space.large,
                                          ),
                                        ),
                                        borderSide: BorderSide(
                                          color: Color(0xFFF7F7F7),
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      tempTitle = value;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            actionsPadding: EdgeInsets.symmetric(
                              horizontal: Responsive.space(
                                context,
                                size: Space.large,
                              ),
                              vertical: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            actionsAlignment: MainAxisAlignment.spaceBetween,
                            actions: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[600],
                                      padding: EdgeInsets.symmetric(
                                        horizontal: Responsive.space(
                                          context,
                                          size: Space.medium,
                                        ),
                                        vertical: Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          Responsive.space(
                                            context,
                                            size: Space.large,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'إلغاء',
                                      style: TextStyle(
                                        fontSize: Responsive.text(
                                          context,
                                          size: TextSize.medium,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        () => Navigator.pop(context, tempTitle),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: Responsive.space(
                                          context,
                                          size: Space.large,
                                        ),
                                        vertical: Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          Responsive.space(
                                            context,
                                            size: Space.large,
                                          ),
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'حفظ',
                                      style: TextStyle(
                                        fontSize: Responsive.text(
                                          context,
                                          size: TextSize.medium,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                      setState(() {
                        attachments.add({
                          'title': linkTitle ?? fileName,
                          'url': downloadUrl,
                        });
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      confirmText: widget.task == null ? 'إضافة التاسك' : 'حفظ التعديلات',
      confirmIcon:
          widget.task == null
              ? Icons.add_circle_outline
              : Icons.save_alt_rounded,
      onConfirm: _saveForm,
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
