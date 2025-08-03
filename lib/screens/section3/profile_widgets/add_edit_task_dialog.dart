import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;
import 'package:pivot/screens/models/custom_dropdown.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:pivot/responsive.dart';

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
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          widget.task == null ? 'إضافة مهمة شخصية' : 'تعديل المهمة',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _titleController,
                  hint: 'العنوان',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال عنوان للمهمة';
                    }
                    return null;
                  },
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                CustomTextField(
                  controller: _descriptionController,
                  hint: 'التفاصيل',
                  maxLines: 3,
                  minLines: 3,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Container(
                  padding: Responsive.paddingVertical(
                    context,
                    size: Space.small,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () => _selectDate(context),
                    title: const Text('تاريخ النهاية'),
                    subtitle: Text(
                      DateFormat.yMMMd('ar').format(_selectedDate),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: Colors.teal,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                CustomDropdown(
                  hint: 'الأهمية',
                  color: const Color(0xFFF7F7F7),
                  value: _getImportanceArabicName(_selectedImportance),
                  items:
                      TaskImportance.values
                          .map((imp) => _getImportanceArabicName(imp))
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
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'المرفقات:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...attachments.map(
                  (att) => ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(att['title'] ?? ''),
                    subtitle: Text(att['url'] ?? ''),
                    onTap: () async {
                      final url = att['url'];
                      if (url != null) {
                        // Open the URL (use url_launcher if needed)
                      }
                    },
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('إرفاق ملف/صورة'),
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
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              padding: EdgeInsets.all(
                                Responsive.space(context, size: Space.large),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header with icon
                                  Container(
                                    padding: EdgeInsets.all(
                                      Responsive.space(
                                        context,
                                        size: Space.medium,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      Icons.edit_note,
                                      size:
                                          Responsive.space(
                                            context,
                                            size: Space.large,
                                          ) *
                                          2,
                                      color: Colors.teal[700],
                                    ),
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.medium,
                                    ),
                                  ),

                                  // Title
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

                                  // Subtitle
                                  Text(
                                    'أدخل اسم الملف كما تريد أن يظهر في المهمة',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ),
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),

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
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.attach_file,
                                          color: Colors.teal[600],
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

                                  // Input field using CustomTextField
                                  CustomTextField(
                                    hint: 'أدخل اسم الملف الجديد',
                                    controller: controller,
                                    onChanged: (value) {
                                      tempTitle = value;
                                    },
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),

                                  // Action buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              vertical: Responsive.space(
                                                context,
                                                size: Space.medium,
                                              ),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            'إلغاء',
                                            style: TextStyle(
                                              fontSize: Responsive.text(
                                                context,
                                                size: TextSize.medium,
                                              ),
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                      ),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              () => Navigator.pop(
                                                context,
                                                tempTitle,
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal[600],
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              vertical: Responsive.space(
                                                context,
                                                size: Space.medium,
                                              ),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          ElevatedButton(onPressed: _saveForm, child: const Text('حفظ')),
        ],
        actionsAlignment: MainAxisAlignment.end,
      ),
    );
  }
}
