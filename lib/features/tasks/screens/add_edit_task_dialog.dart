import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/media/services/materials_service.dart';
import 'package:pivot/models/material_link.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

// Function to show the Add/Edit Task Dialog
Future<void> showAddTaskDialog({
  required BuildContext context,
  required Function(Task) onSave,
  required String subjectId,
  String? initialSectionId,
  Task? task,
}) async {
  // This will be handled inside the dialog content
  // No need to fetch user here as the dialog is now a ConsumerWidget

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _AddEditTaskDialogContent(
        onSave: onSave,
        task: task,
        subjectId: subjectId,
        initialSectionId: initialSectionId,
      );
    },
  );
}

class _AddEditTaskDialogContent extends ConsumerStatefulWidget {
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
  ConsumerState<_AddEditTaskDialogContent> createState() =>
      _AddEditTaskDialogContentState();
}

class _AddEditTaskDialogContentState
    extends ConsumerState<_AddEditTaskDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskImportance _selectedImportance;
  String? _selectedSubjectId;
  String? _selectedSectionId;
  List<Map<String, String>> selectedMaterials = [];
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
      selectedMaterials = List<Map<String, String>>.from(
        widget.task!.attachments!,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInitialData());
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;

    try {
      // Get logged-in user for sections fetch
      final user = ref.read(userProfileProvider).loggedInUserProfile;
      if (user != null) {
        await ref.read(sectionsProvider.notifier).loadSectionsForUser(user.id, [
          _selectedSubjectId!,
        ]);
      }

      if (!mounted) return;

      final sectionsState = ref.read(sectionsProvider);
      if (sectionsState.sections.isNotEmpty) {
        // Only set _selectedSectionId if it is not already set or not found in the list
        final found = sectionsState.sections.any(
          (s) => s.id == _selectedSectionId,
        );
        if (!found && mounted) {
          setState(() => _selectedSectionId = sectionsState.sections.first.id);
        }
      }
    } catch (e) {
      print('Error fetching initial data: $e');
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
      if (_selectedSubjectId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('من فضلك اختر المادة')));
        return;
      }

      // Get the section to find its assistant ID
      final sectionsState = ref.read(sectionsProvider);
      final section = sectionsState.sections.firstWhere(
        (s) => s.id == _selectedSectionId,
        orElse: () => throw Exception('Section not found'),
      );

      final newTask = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDate,
        importance: _selectedImportance,
        subjectId: _selectedSubjectId!,
        sectionId: _selectedSectionId!,
        assistantId:
            section
                .assistantId, // Set the assistant ID to the section's assistant
        attachments: selectedMaterials,
      );
      widget.onSave(newTask);
      Navigator.of(context).pop();
    }
  }

  Future<void> _showMaterialsSelectionDialog() async {
    print('🎯 [AddTaskDialog] Materials selection button pressed');
    print('   Selected Subject ID: $_selectedSubjectId');
    print('   Selected Section ID: $_selectedSectionId');

    if (_selectedSubjectId == null || _selectedSectionId == null) {
      print('   ❌ Missing subject or section ID');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المادة والسكشن أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get section to find assistant ID
    final sectionsState = ref.read(sectionsProvider);
    print('   📋 Total sections available: ${sectionsState.sections.length}');

    final section = sectionsState.sections.firstWhere(
      (s) => s.id == _selectedSectionId,
      orElse: () => throw Exception('Section not found'),
    );

    print('   ✅ Found section: ${section.name}');
    print('   👤 Assistant ID: ${section.assistantId}');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Card(
              child: Padding(
                padding: Responsive.padding(context, size: Space.large),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.black),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text('جاري تحميل المواد...'),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      print('   🔄 Starting to load materials...');

      // Use service directly to avoid AutoDispose issues
      final materialsService = MaterialsService();
      final availableMaterials = await materialsService
          .getMaterialsBySubjectAndAssistant(
            _selectedSubjectId!,
            section.assistantId,
          );

      print('   ✅ Materials loaded successfully');

      if (!mounted) {
        print('   ⚠️ Widget not mounted, aborting');
        Navigator.of(context).pop(); // Close loading
        return;
      }

      print('   📚 Available materials count: ${availableMaterials.length}');
      for (var i = 0; i < availableMaterials.length; i++) {
        print(
          '      [$i] ${availableMaterials[i].displayTitle} (${availableMaterials[i].type.name})',
        );
      }

      // Close loading indicator
      Navigator.of(context).pop();

      if (!mounted) return;

      if (availableMaterials.isEmpty) {
        print('   ⚠️ No materials available, showing warning');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد مواد متاحة لهذا السكشن'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      print('   📖 Opening material selection dialog...');

      // Show selection dialog
      final selected = await showDialog<List<MaterialLink>>(
        context: context,
        builder:
            (context) => _MaterialSelectionDialog(
              materials: availableMaterials,
              alreadySelected:
                  selectedMaterials.map((m) => m['url'] ?? '').toList(),
            ),
      );

      if (selected != null && selected.isNotEmpty && mounted) {
        print('   ✅ User selected ${selected.length} material(s):');
        for (var material in selected) {
          print('      - ${material.displayTitle}');
        }

        setState(() {
          for (var material in selected) {
            if (!selectedMaterials.any((m) => m['url'] == material.url)) {
              selectedMaterials.add({
                'title': material.displayTitle,
                'url': material.url,
              });
              print('      ➕ Added: ${material.displayTitle}');
            } else {
              print(
                '      ⏭️ Skipped (already added): ${material.displayTitle}',
              );
            }
          }
        });

        print(
          '   📊 Total materials now attached: ${selectedMaterials.length}',
        );
      } else {
        print('   ❌ No materials selected or dialog cancelled');
      }
    } catch (e) {
      print('   ❌ ERROR in material selection: $e');
      print('   Stack trace: ${StackTrace.current}');

      // Close loading indicator if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحميل المواد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    return UnifiedDialog(
      title: _isEditing ? 'تعديل التاسك' : 'اضافة تاسك جديد',
      subtitle:
          _isEditing ? 'تعديل معلومات التاسك' : 'أدخل معلومات التاسك الجديد',
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
              SizedBox(height: Responsive.space(context, size: Space.small)),
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
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'تفاصيل التاسك:',
                style: labelStyle,
                textAlign: TextAlign.right,
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              TextFormField(
                controller: _descriptionController,
                decoration: commonDecoration.copyWith(
                  hintText: 'أى تفاصيل إضافية...',
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Due Date Field
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.large),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.blue.shade700,
                          size: Responsive.space(context, size: Space.medium),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.medium),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'آخر ميعاد للتسليم',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              intl.DateFormat(
                                'dd/MM/yyyy',
                                'ar',
                              ).format(_selectedDate),
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Importance Field
              Container(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.large),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getImportanceColor(_selectedImportance).withOpacity(0.1),
                      _getImportanceColor(_selectedImportance).withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: _getImportanceColor(
                      _selectedImportance,
                    ).withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getImportanceColor(
                        _selectedImportance,
                      ).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                            Responsive.space(context, size: Space.small),
                          ),
                          decoration: BoxDecoration(
                            color: _getImportanceColor(
                              _selectedImportance,
                            ).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.flag_rounded,
                            color: _getImportanceColor(_selectedImportance),
                            size: Responsive.space(context, size: Space.medium),
                          ),
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.medium),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الأهمية',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                color: _getImportanceColor(_selectedImportance),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _importanceLabels[_selectedImportance] ?? 'N/A',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    PopupMenuButton<TaskImportance>(
                      initialValue: _selectedImportance,
                      onSelected: (TaskImportance value) {
                        setState(() {
                          _selectedImportance = value;
                        });
                      },
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: _getImportanceColor(_selectedImportance),
                        size: Responsive.space(context, size: Space.large),
                      ),
                      itemBuilder:
                          (BuildContext context) =>
                              TaskImportance.values.map((
                                TaskImportance importance,
                              ) {
                                return PopupMenuItem<TaskImportance>(
                                  value: importance,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.flag_rounded,
                                        color: _getImportanceColor(importance),
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        _importanceLabels[importance] ?? 'N/A',
                                        style: TextStyle(
                                          fontWeight:
                                              importance == _selectedImportance
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Materials Section
              if (selectedMaterials.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.library_books,
                            size: 18,
                            color: Colors.blue[700],
                          ),
                          SizedBox(width: 8),
                          Text(
                            'المواد المرفقة:',
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      ...selectedMaterials.asMap().entries.map((entry) {
                        final index = entry.key;
                        final material = entry.value;
                        return Container(
                          margin: EdgeInsets.only(
                            bottom: Responsive.space(context, size: Space.tiny),
                          ),
                          padding: EdgeInsets.all(
                            Responsive.space(context, size: Space.small),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.small),
                            ),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.link,
                                size: 16,
                                color: Colors.blue[600],
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  material['title'] ?? '',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, size: 16),
                                color: Colors.red[400],
                                onPressed: () {
                                  setState(() {
                                    selectedMaterials.removeAt(index);
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
              ],

              // Add Materials Button
              ElevatedButton.icon(
                onPressed: _showMaterialsSelectionDialog,
                icon: Icon(Icons.library_add),
                label: Text('إضافة مرفقات من الماتيريال'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.large),
                    vertical: Responsive.space(context, size: Space.medium),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      confirmText: _isEditing ? 'حفظ التعديلات' : 'إضافة التاسك',
      confirmIcon:
          _isEditing
              ? Icons.save_alt_rounded
              : Icons.add_circle_outline_rounded,
      onConfirm: _saveTask,
      onCancel: () => Navigator.of(context).pop(),
    );
  }

  Color _getImportanceColor(TaskImportance importance) {
    switch (importance) {
      case TaskImportance.high:
        return Colors.red.shade400;
      case TaskImportance.mid:
        return Colors.amber.shade600;
      case TaskImportance.low:
        return Colors.green.shade400;
    }
  }
}

// Material Selection Dialog
class _MaterialSelectionDialog extends StatefulWidget {
  final List<MaterialLink> materials;
  final List<String> alreadySelected;

  const _MaterialSelectionDialog({
    required this.materials,
    required this.alreadySelected,
  });

  @override
  State<_MaterialSelectionDialog> createState() =>
      _MaterialSelectionDialogState();
}

class _MaterialSelectionDialogState extends State<_MaterialSelectionDialog> {
  final Set<String> _selectedUrls = {};

  @override
  void initState() {
    super.initState();
    _selectedUrls.addAll(widget.alreadySelected);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: Responsive.width(context) * 0.9,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: Responsive.padding(context, size: Space.medium),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    topRight: Radius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.library_books, color: Colors.blue.shade700),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Expanded(
                      child: Text(
                        'اختار المرفقات ',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Materials List
              Expanded(
                child: ListView.builder(
                  padding: Responsive.padding(context, size: Space.medium),
                  itemCount: widget.materials.length,
                  itemBuilder: (context, index) {
                    final material = widget.materials[index];
                    final isSelected = _selectedUrls.contains(material.url);

                    return Card(
                      margin: EdgeInsets.only(
                        bottom: Responsive.space(context, size: Space.small),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedUrls.add(material.url);
                            } else {
                              _selectedUrls.remove(material.url);
                            }
                          });
                        },
                        title: Text(
                          material.displayTitle,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle:
                            material.description != null
                                ? Text(
                                  material.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                  ),
                                )
                                : null,
                        secondary: Icon(
                          material.typeIcon,
                          color: Colors.blue.shade600,
                        ),
                        activeColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ),

              // Action Buttons
              Container(
                padding: Responsive.padding(context, size: Space.medium),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('إلغاء'),
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final selected =
                              widget.materials
                                  .where((m) => _selectedUrls.contains(m.url))
                                  .toList();
                          Navigator.of(context).pop(selected);
                        },
                        icon: Icon(Icons.check),
                        label: Text('إضافة (${_selectedUrls.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
