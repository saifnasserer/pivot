import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pivot/responsive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/services/storage_optimization_service.dart';
import 'package:image_picker/image_picker.dart';

// Function to show the Add/Edit Task Dialog
Future<void> showAddTaskDialog({
  required BuildContext context,
  required Function(Task) onSave,
  required String subjectId,
  String? initialSectionId,
  Task? task,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: Provider.of<SubjectProvider>(context),
          ),
          ChangeNotifierProvider.value(
            value: Provider.of<SectionProvider>(context),
          ),
          ChangeNotifierProvider.value(
            value: Provider.of<UserProfileProvider>(context),
          ),
        ],
        child: _AddEditTaskDialogContent(
          onSave: onSave,
          task: task,
          subjectId: subjectId,
          initialSectionId: initialSectionId,
        ),
      );
    },
  );
}

class _AddEditTaskDialogContent extends StatefulWidget {
  final Function(Task) onSave;
  final Task? task;
  final String subjectId;
  final String? initialSectionId;
  const _AddEditTaskDialogContent({
    required this.onSave,
    this.task,
    required this.subjectId,
    this.initialSectionId,
  });
  @override
  State<_AddEditTaskDialogContent> createState() =>
      _AddEditTaskDialogContentState();
}

class _AddEditTaskDialogContentState extends State<_AddEditTaskDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskImportance _selectedImportance;
  String? _selectedSubjectId;
  String? _selectedSectionId;
  bool _isLoadingSections = false;
  List<Map<String, String>> attachments = [];
  bool _isEditing = false;

  final Map<TaskImportance, String> _importanceLabels = {
    TaskImportance.high: 'مهمه',
    TaskImportance.mid: 'نص نص',
    TaskImportance.low: 'عادي',
  };

  @override
  void initState() {
    super.initState();
    _isEditing = widget.task != null;
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedDate =
        widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedImportance = widget.task?.importance ?? TaskImportance.mid;
    _selectedSubjectId = widget.subjectId;
    if (_isEditing && widget.task != null) {
      _selectedSectionId = widget.task!.sectionId;
    } else if (widget.initialSectionId != null) {
      _selectedSectionId = widget.initialSectionId;
    }
    if (_isEditing && widget.task?.attachments != null) {
      attachments = List<Map<String, String>>.from(widget.task!.attachments!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInitialData());
  }

  Future<void> _fetchInitialData() async {
    final sectionProvider = Provider.of<SectionProvider>(
      context,
      listen: false,
    );
    await sectionProvider.fetchSectionsForUserSubjects([_selectedSubjectId!]);
    if (sectionProvider.sections.isNotEmpty) {
      // Only set _selectedSectionId if it is not already set or not found in the list
      final found = sectionProvider.sections.any(
        (s) => s.id == _selectedSectionId,
      );
      if (!found) {
        setState(() => _selectedSectionId = sectionProvider.sections.first.id);
      }
    }
    setState(() => _isLoadingSections = false);
  }

  void _onSectionChanged(String? newSectionId) {
    setState(() {
      _selectedSectionId = newSectionId;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSubjectId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('من فضلك اختر المادة')));
        return;
      }
      final newTask = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDate,
        importance: _selectedImportance,
        subjectId: _selectedSubjectId!,
        sectionId: _selectedSectionId!,
        attachments: attachments,
      );
      widget.onSave(newTask);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(
      Responsive.space(context, size: Space.large),
    );
    final commonDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      fillColor: Colors.grey.shade100,
      filled: true,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontWeight: FontWeight.w500,
      ),
    );
    final labelStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    return Consumer2<SectionProvider, UserProfileProvider>(
      builder: (context, sectionProvider, userProfileProvider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            title: Text(
              _isEditing ? 'تعديل التاسك' : 'اضافة تاسك جديد',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'عنوان التاسك:',
                      style: labelStyle,
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    TextFormField(
                      controller: _titleController,
                      decoration: commonDecoration.copyWith(
                        hintText: 'اكتب اسم التاسك',
                      ),
                      textAlign: TextAlign.right,
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'اكتب اسم التاسك'
                                  : null,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'تفاصيل التاسك:',
                      style: labelStyle,
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: commonDecoration.copyWith(
                        hintText: 'أى تفاصيل إضافية...',
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'آخر ميعاد للتسليم:',
                                style: labelStyle,
                                textAlign: TextAlign.right,
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              InkWell(
                                onTap: () => _selectDate(context),
                                borderRadius: borderRadius,
                                child: InputDecorator(
                                  decoration: commonDecoration,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          intl.DateFormat(
                                            'dd/MM/yyyy',
                                            'ar',
                                          ).format(_selectedDate),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.medium),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'الأهمية:',
                                style: labelStyle,
                                textAlign: TextAlign.right,
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              DropdownButtonFormField<TaskImportance>(
                                value: _selectedImportance,
                                decoration: commonDecoration,
                                items:
                                    TaskImportance.values.map((
                                      TaskImportance importance,
                                    ) {
                                      return DropdownMenuItem<TaskImportance>(
                                        value: importance,
                                        child: Text(
                                          _importanceLabels[importance] ??
                                              'N/A',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyLarge,
                                          textAlign: TextAlign.right,
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (TaskImportance? newValue) {
                                  if (newValue != null) {
                                    setState(
                                      () => _selectedImportance = newValue,
                                    );
                                  }
                                },
                                isExpanded: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    _AttachmentSection(
                      attachments: attachments,
                      onAddAttachment:
                          (att) => setState(() => attachments.add(att)),
                      onRemoveAttachment:
                          (i) => setState(() => attachments.removeAt(i)),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: borderRadius),
                ),
                child: const Text('إلغاء'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton.icon(
                icon: Icon(
                  _isEditing
                      ? Icons.save_alt_rounded
                      : Icons.add_circle_outline_rounded,
                ),
                label: Text(_isEditing ? 'حفظ التعديلات' : 'إضافة التاسك'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                ),
                onPressed: _saveTask,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttachmentSection extends StatelessWidget {
  final List<Map<String, String>> attachments;
  final void Function(Map<String, String>) onAddAttachment;
  final void Function(int) onRemoveAttachment;
  const _AttachmentSection({
    required this.attachments,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (attachments.isNotEmpty) ...[
          Text(
            'المرفقات:',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(attachments.length, (index) {
                  final att = attachments[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.attach_file, size: 20),
                    title: Text(
                      att['title'] ?? '',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onRemoveAttachment(index),
                    ),
                    onTap: () async {
                      final url = att['url'];
                      if (url != null) {
                        try {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تعذر فتح الملف'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('خطأ في فتح الملف: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
        ],
        ElevatedButton.icon(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.any,
              allowMultiple: false,
            );
            if (result != null && result.files.single.path != null) {
              final file = File(result.files.single.path!);
              final fileName = result.files.single.name;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Text('جاري رفع الملف...'),
                          ],
                        ),
                      ),
                    ),
              );
              try {
                final storageService = StorageOptimizationService();
                final xFile = XFile(file.path);
                final downloadUrl = await storageService.uploadFileOptimized(
                  xFile,
                  folder: 'tasks',
                  usage: 'task',
                  checkDuplicate: true,
                );

                if (downloadUrl != null) {
                  Navigator.of(context).pop();
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
                                  Responsive.space(context, size: Space.medium),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
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
                                  color: Colors.blue[700],
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
                                  Responsive.space(context, size: Space.medium),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.attach_file,
                                      color: Colors.blue[600],
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
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: Responsive.space(
                                            context,
                                            size: Space.medium,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
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
                                          () =>
                                              Navigator.pop(context, tempTitle),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[600],
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          vertical: Responsive.space(
                                            context,
                                            size: Space.medium,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
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
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                  onAddAttachment({
                    'title': linkTitle ?? fileName,
                    'url': downloadUrl,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم رفع الملف بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('فشل في رفع الملف: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.attach_file),
          label: const Text('إرفاق ملف/صورة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
      ],
    );
  }
}
