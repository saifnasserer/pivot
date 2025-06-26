import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pivot/models/section_model.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:pivot/services/permission_service.dart';
import 'package:pivot/responsive.dart';

// Function to show the Add/Edit Task Dialog
Future<void> showAddTaskDialog({
  required BuildContext context,
  required Function(Task) onSave,
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
        child: _AddEditTaskDialogContent(onSave: onSave, task: task),
      );
    },
  );
}

class _AddEditTaskDialogContent extends StatefulWidget {
  final Function(Task) onSave;
  final Task? task;
  const _AddEditTaskDialogContent({required this.onSave, this.task});
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
  bool _isLoadingSubjects = true;
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
    if (_isEditing && widget.task != null) {
      _selectedSubjectId = widget.task!.subjectId;
      _selectedSectionId = widget.task!.sectionId;
    }
    if (_isEditing && widget.task?.attachments != null) {
      attachments = List<Map<String, String>>.from(widget.task!.attachments!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInitialData());
  }

  Future<void> _fetchInitialData() async {
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final userProfile = userProfileProvider.userProfile;
    if (userProfile == null) {
      setState(() => _isLoadingSubjects = false);
      return;
    }
    await subjectProvider.fetchAndFilterSubjects(userProfile);
    setState(() => _isLoadingSubjects = false);
    if (!_isEditing) {
      final subjects = subjectProvider.filteredSubjects;
      if (subjects.isNotEmpty) {
        setState(() => _selectedSubjectId = subjects.first.id);
        _fetchSectionsForSubject(subjects.first.id);
      }
    } else if (_selectedSubjectId != null) {
      _fetchSectionsForSubject(_selectedSubjectId!);
    }
  }

  Future<void> _fetchSectionsForSubject(String subjectId) async {
    setState(() => _isLoadingSections = true);
    final sectionProvider = Provider.of<SectionProvider>(
      context,
      listen: false,
    );
    await sectionProvider.fetchSectionsForUserSubjects([subjectId]);
    if (!_isEditing && sectionProvider.sections.isNotEmpty) {
      setState(() => _selectedSectionId = sectionProvider.sections.first.id);
    }
    setState(() => _isLoadingSections = false);
  }

  void _onSubjectChanged(String? newSubjectId) {
    if (newSubjectId != null && newSubjectId != _selectedSubjectId) {
      setState(() {
        _selectedSubjectId = newSubjectId;
        _selectedSectionId = null;
      });
      _fetchSectionsForSubject(newSubjectId);
    }
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
      if (_selectedSubjectId == null || _selectedSectionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('من فضلك اختر المادة والسكشن')),
        );
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
    final borderRadius = BorderRadius.circular(20);
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

    return Consumer3<SubjectProvider, SectionProvider, UserProfileProvider>(
      builder: (
        context,
        subjectProvider,
        sectionProvider,
        userProfileProvider,
        child,
      ) {
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
                    _SubjectSectionDropdowns(
                      subjectProvider: subjectProvider,
                      sectionProvider: sectionProvider,
                      selectedSubjectId: _selectedSubjectId,
                      selectedSectionId: _selectedSectionId,
                      isLoadingSubjects: _isLoadingSubjects,
                      isLoadingSections: _isLoadingSections,
                      onSubjectChanged: _onSubjectChanged,
                      onSectionChanged:
                          (id) => setState(() => _selectedSectionId = id),
                      commonDecoration: commonDecoration,
                      labelStyle: labelStyle,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
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

class _SubjectSectionDropdowns extends StatelessWidget {
  final SubjectProvider subjectProvider;
  final SectionProvider sectionProvider;
  final String? selectedSubjectId;
  final String? selectedSectionId;
  final bool isLoadingSubjects;
  final bool isLoadingSections;
  final void Function(String?) onSubjectChanged;
  final void Function(String?) onSectionChanged;
  final InputDecoration commonDecoration;
  final TextStyle? labelStyle;
  const _SubjectSectionDropdowns({
    required this.subjectProvider,
    required this.sectionProvider,
    required this.selectedSubjectId,
    required this.selectedSectionId,
    required this.isLoadingSubjects,
    required this.isLoadingSections,
    required this.onSubjectChanged,
    required this.onSectionChanged,
    required this.commonDecoration,
    required this.labelStyle,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('المادة:', style: labelStyle, textAlign: TextAlign.right),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              if (isLoadingSubjects)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  decoration: commonDecoration.copyWith(
                    hintText: 'اختر المادة',
                  ),
                  isExpanded: true,
                  items:
                      subjectProvider.filteredSubjects.map((Subject subject) {
                        return DropdownMenuItem<String>(
                          value: subject.id,
                          child: Text(
                            subject.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.right,
                          ),
                        );
                      }).toList(),
                  onChanged: onSubjectChanged,
                  validator: (value) => value == null ? 'اختر المادة' : null,
                ),
            ],
          ),
        ),
        SizedBox(width: Responsive.space(context, size: Space.medium)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('السكشن:', style: labelStyle, textAlign: TextAlign.right),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              if (isLoadingSections)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  value: selectedSectionId,
                  decoration: commonDecoration.copyWith(
                    hintText: 'اختر السكشن',
                  ),
                  isExpanded: true,
                  items:
                      sectionProvider.sections.map((Section section) {
                        return DropdownMenuItem<String>(
                          value: section.id,
                          child: Text(
                            section.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.right,
                          ),
                        );
                      }).toList(),
                  onChanged: onSectionChanged,
                  validator: (value) => value == null ? 'اختر السكشن' : null,
                  disabledHint:
                      selectedSubjectId == null
                          ? const Text(
                            'اختر المادة أولاً',
                            textAlign: TextAlign.right,
                          )
                          : null,
                ),
            ],
          ),
        ),
      ],
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
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                final att = attachments[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.attach_file, size: 20),
                  title: Text(
                    att['title'] ?? '',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onRemoveAttachment(index),
                  ),
                  onTap: () async {
                    final url = att['url'];
                    if (url != null) {
                      // TODO: Open the URL (e.g., with url_launcher)
                    }
                  },
                );
              },
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
        ],
        ElevatedButton.icon(
          onPressed: () async {
            final hasPermission =
                await PermissionService.requestStoragePermissionWithRationale(
                  context,
                );
            if (!hasPermission) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('يجب السماح بالوصول للملفات')),
              );
              return;
            }
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
                final storageRef = firebase_storage.FirebaseStorage.instance
                    .ref()
                    .child(
                      'tasks/attachments/${DateTime.now().millisecondsSinceEpoch}_$fileName',
                    );
                final uploadTask = storageRef.putFile(file);
                final snapshot = await uploadTask.whenComplete(() {});
                final downloadUrl = await snapshot.ref.getDownloadURL();
                Navigator.of(context).pop();
                String? linkTitle = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    String tempTitle = fileName;
                    return Directionality(
                      textDirection: TextDirection.rtl,
                      child: AlertDialog(
                        title: const Text('عنوان الملف'),
                        content: TextField(
                          decoration: const InputDecoration(
                            hintText: 'أدخل عنوان الرابط',
                          ),
                          controller: TextEditingController(text: fileName),
                          textAlign: TextAlign.right,
                          onChanged: (v) => tempTitle = v,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, tempTitle),
                            child: const Text('موافق'),
                          ),
                        ],
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
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
      ],
    );
  }
}
