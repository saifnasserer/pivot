import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:provider/provider.dart';

// Function to show the Add/Edit Task Dialog
Future<void> showAddTaskDialog({
  required BuildContext context,
  required Function(Task) onSave, // Callback when task is saved
  Task? task, // Optional: Task object for editing
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap button!
    builder: (BuildContext dialogContext) {
      // Provide necessary providers to the dialog
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

// StatefulWidget for the dialog content to manage form state
class _AddEditTaskDialogContent extends StatefulWidget {
  final Function(Task) onSave;
  final Task? task; // Existing task for editing

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
  bool _isEditing = false;

  // State for subject/section dropdowns
  String? _selectedSubjectId;
  String? _selectedSectionId;
  bool _isLoadingSubjects = true;
  bool _isLoadingSections = false;

  // Map TaskImportance enum values to display names
  final Map<TaskImportance, String> _importanceLabels = {
    TaskImportance.high: 'مهمه',
    TaskImportance.mid: 'نص نص',
    TaskImportance.low: 'عادي',
  };

  @override
  void initState() {
    super.initState();
    _isEditing = widget.task != null;

    // Initialize form fields
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedDate =
        widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedImportance = widget.task?.importance ?? TaskImportance.mid;

    // Set initial subject and section if editing
    if (_isEditing && widget.task != null) {
      _selectedSubjectId = widget.task!.subjectId;
      _selectedSectionId = widget.task!.sectionId;
    }

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
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

    // Determine which subjects to fetch based on user role
    final userProfile = userProfileProvider.userProfile;
    if (userProfile == null) {
      setState(() => _isLoadingSubjects = false);
      return;
    }

    // Fetch subjects
    await subjectProvider.fetchAndFilterSubjects(userProfile);
    setState(() => _isLoadingSubjects = false);

    // If editing, also fetch the sections for the pre-selected subject
    if (_isEditing && _selectedSubjectId != null) {
      _fetchSectionsForSubject(_selectedSubjectId!);
    }
  }

  Future<void> _fetchSectionsForSubject(String subjectId) async {
    setState(() {
      _isLoadingSections = true;
    });
    final sectionProvider = Provider.of<SectionProvider>(
      context,
      listen: false,
    );
    await sectionProvider.fetchSectionsForUserSubjects([subjectId]);
    setState(() {
      _isLoadingSections = false;
    });
  }

  void _onSubjectChanged(String? newSubjectId) {
    if (newSubjectId != null && newSubjectId != _selectedSubjectId) {
      setState(() {
        _selectedSubjectId = newSubjectId;
        _selectedSectionId = null; // Reset section selection
      });
      _fetchSectionsForSubject(newSubjectId);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        // Show an error if subject or section is not selected
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
      );
      widget.onSave(newTask);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Styling constants
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

    // Consumer for providers
    return Consumer3<SubjectProvider, SectionProvider, UserProfileProvider>(
      builder: (
        context,
        subjectProvider,
        sectionProvider,
        userProfileProvider,
        child,
      ) {
        return AlertDialog(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Subject Dropdown
                    Text(
                      'المادة:',
                      style: labelStyle,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingSubjects)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedSubjectId,
                        decoration: commonDecoration.copyWith(
                          hintText: 'اختر المادة',
                        ),
                        isExpanded: true,
                        items:
                            subjectProvider.filteredSubjects.map<DropdownMenuItem<String>>((
                              Subject subject,
                            ) {
                              return DropdownMenuItem<String>(
                                value: subject.id,
                                child: Text(
                                  subject.name,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              );
                            }).toList(),
                        onChanged: _onSubjectChanged,
                        validator:
                            (value) => value == null ? 'اختر المادة' : null,
                      ),
                    const SizedBox(height: 16),

                    // Section Dropdown
                    Text(
                      'السكشن:',
                      style: labelStyle,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingSections)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedSectionId,
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
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSectionId = newValue;
                          });
                        },
                        validator:
                            (value) => value == null ? 'اختر السكشن' : null,
                        disabledHint:
                            _selectedSubjectId == null
                                ? const Text('اختر المادة أولاً')
                                : null,
                      ),
                    const SizedBox(height: 16),

                    // Task Title
                    Text(
                      'عنوان التاسك:',
                      style: labelStyle,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 16),

                    // Task Description
                    Text(
                      'تفاصيل التاسك:',
                      style: labelStyle,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: commonDecoration.copyWith(
                        hintText: 'أى تفاصيل إضافية...',
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    Text(
                      'آخر ميعاد للتسليم:',
                      style: labelStyle,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: borderRadius,
                      child: InputDecorator(
                        decoration: commonDecoration,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE, dd MMMM yyyy',
                                'ar',
                              ).format(_selectedDate),
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
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
                    const SizedBox(height: 16),

                    // Importance
                    Text(
                      'الأهمية:',
                      style: labelStyle,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
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
                                _importanceLabels[importance] ?? 'N/A',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            );
                          }).toList(),
                      onChanged: (TaskImportance? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedImportance = newValue);
                        }
                      },
                      isExpanded: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
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
        );
      },
    );
  }
}
