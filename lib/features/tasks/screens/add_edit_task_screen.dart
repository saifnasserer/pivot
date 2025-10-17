import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/media/services/materials_service.dart';
import 'package:pivot/features/subjects/providers/subject_provider.dart';
import 'package:pivot/models/material_link.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/features/auth/providers/auth_provider.dart';
import 'package:pivot/features/tasks/providers/tasks_provider.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/features/home/screens/adminstration/animated_route.dart';

// Function to show the Add/Edit Task Screen
Future<void> showAddTaskScreen({
  required BuildContext context,
  required Future<void> Function(Task) onSave,
  required String subjectId,
  String? initialSectionId,
  Task? task,
}) async {
  await Navigator.of(context).push(
    AnimatedAddRoute(
      startPosition: Offset.zero,
      child: AddEditTaskScreen(
        onSave: onSave,
        task: task,
        subjectId: subjectId,
        initialSectionId: initialSectionId,
      ),
    ),
  );
}

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final Future<void> Function(Task) onSave;
  final Task? task;
  final String subjectId;
  final String? initialSectionId;

  const AddEditTaskScreen({
    super.key,
    required this.onSave,
    this.task,
    required this.subjectId,
    this.initialSectionId,
  });

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskImportance _selectedImportance;
  String? _selectedSubjectId;
  String? _selectedSectionId;
  List<Map<String, String>> selectedMaterials = [];
  bool _isEditing = false;
  bool _isSaving = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    // Initialize animations
    _initializeAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInitialData());
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;

    try {
      // Get logged-in user for sections fetch
      final user = ref.read(userProfileProvider).loggedInUserProfile;
      if (user != null) {
        // Check if sections are already loaded to prevent unnecessary operations
        final sectionsState = ref.read(sectionsProvider);
        if (sectionsState.sections.isEmpty) {
          await ref.read(sectionsProvider.notifier).loadSectionsForUser(
            user.id,
            [_selectedSubjectId!],
          );
        }
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
      if (kDebugMode) {
        print('Error fetching initial data: $e');
      }
      // Don't re-throw to prevent widget disposal issues
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

  Future<void> _saveTask() async {
    if (_isSaving) return; // Prevent multiple saves

    if (_formKey.currentState!.validate()) {
      if (_selectedSubjectId == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('من فضلك اختر المادة')));
        }
        return;
      }

      // Validate required fields
      if (_titleController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('من فضلك أدخل عنوان التاسك')),
          );
        }
        return;
      }

      if (_selectedSectionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('من فضلك اختر السكشن')));
        }
        return;
      }

      // Set loading state only if widget is still mounted
      if (mounted) {
        print('🔄 [AddTaskScreen] Setting loading state to true');
        setState(() {
          _isSaving = true;
        });
      }

      // Check if widget is still mounted before ref calls
      if (!mounted) return;

      // Get the section to find its assistant ID
      final sectionsState = ref.read(sectionsProvider);
      if (sectionsState.sections.isEmpty) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('لا توجد سكشنز متاحة')));
        }
        return;
      }

      // Safe section lookup without throwing exception
      Section? section;
      try {
        section = sectionsState.sections.firstWhere(
          (s) => s.id == _selectedSectionId,
        );
      } catch (e) {
        section = null;
      }

      if (section == null) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('السكشن المحدد غير موجود')),
          );
        }
        return;
      }

      // Get assistant name and section number for source info
      String assistantName = 'غير محدد';
      try {
        // Check if widget is still mounted before ref call
        if (!mounted) return;

        // Get assistant profile from the section's assistantId
        final authService = ref.read(authServiceProvider);
        final assistantProfile = await authService.getUserProfile(
          section.assistantId,
        );

        // Check if widget is still mounted after async operation
        if (!mounted) return;

        if (assistantProfile != null) {
          // Apply title logic based on gender and role
          String title = '';
          if (assistantProfile.role.toLowerCase() == 'miniprofessor') {
            title =
                assistantProfile.gender == 'ذكر' ? 'البشمهندس ' : 'البشمهندسة ';
          }
          assistantName = '$title${assistantProfile.name}';
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting assistant profile: $e');
        }
        // Fallback to just the assistant ID or a default
        assistantName = 'المعيد غير محدد';
      }

      final sectionNumber = Task.extractSectionNumber(section.name);

      // Get subject name from subject provider
      String? subjectName;
      try {
        final subjectState = ref.read(SubjectProviderProvider);
        final subject = subjectState.allSubjects.firstWhere(
          (s) => s.id == _selectedSubjectId!,
          orElse: () => throw Exception('Subject not found'),
        );
        subjectName = subject.name;
      } catch (e) {
        if (kDebugMode) {
          print('Error getting subject name: $e');
        }
        subjectName = 'مادة غير محددة';
      }

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
        assistantName: assistantName,
        sectionNumber: sectionNumber,
        subjectName: subjectName,
      );

      try {
        // Handle save operation directly in the screen to avoid ref disposal issues
        await _handleTaskSave(newTask);

        // Close the screen only after successful save
        if (mounted) {
          print('✅ [AddTaskScreen] Save completed, closing screen');
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Reset loading state on error
        if (mounted) {
          print('❌ [AddTaskScreen] Save failed, resetting loading state');
          setState(() {
            _isSaving = false;
          });
        }

        // Show error with more details
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل الحفظ: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }

        // Don't re-throw the error here to prevent the screen from closing
        // The error is already handled and shown to the user
        return;
      }
    }
  }

  Future<void> _handleTaskSave(Task task) async {
    print('🔄 [AddTaskScreen] Starting save operation...');

    // Handle save operation directly in the screen using ref
    // This avoids the callback pattern that causes ref disposal issues
    final viewTasksNotifier = ref.read(viewTasksProvider.notifier);

    final offlineService = ref.read(offlineServiceProvider);
    final isOffline = offlineService.isOffline;

    final isEditing = widget.task != null;

    print('   Is Editing: $isEditing');
    print('   Is Offline: $isOffline');

    if (isEditing) {
      print('   📝 Updating existing task...');
      // Only update the view provider to minimize operations
      final success = await viewTasksNotifier.updateTask(task);

      print('   viewTasksProvider.updateTask: $success');

      if (!success) {
        throw Exception('Failed to update task');
      }
    } else {
      print('   ➕ Adding new task...');
      // Only add to the view provider to minimize operations
      final success = await viewTasksNotifier.addTask(task);

      print('   viewTasksProvider.addTask: $success');

      if (!success) {
        throw Exception('Failed to add task');
      }
    }

    print('✅ [AddTaskScreen] Save operation completed successfully');

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              isOffline
                  ? 'تم حفظ التاسك في قائمة الانتظار. سيتم إرسالها عند الاتصال.'
                  : isEditing
                  ? 'تم تحديث التاسك بنجاح!'
                  : 'تم اضافة التاسك بنجاح!',
            ),
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
          duration: Duration(seconds: isOffline ? 4 : 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showMaterialsSelectionDialog() async {
    if (kDebugMode) {
      print('🎯 [AddTaskScreen] Materials selection button pressed');
      print('   Selected Subject ID: $_selectedSubjectId');
      print('   Selected Section ID: $_selectedSectionId');
    }

    if (_selectedSubjectId == null || _selectedSectionId == null) {
      if (kDebugMode) {
        print('   ❌ Missing subject or section ID');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار المادة والسكشن أولاً'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check if widget is still mounted before ref call
    if (!mounted) return;

    // Get section to find assistant ID
    final sectionsState = ref.read(sectionsProvider);
    if (kDebugMode) {
      print('   📋 Total sections available: ${sectionsState.sections.length}');
    }

    // Safe section lookup without throwing exception
    Section? section;
    try {
      section = sectionsState.sections.firstWhere(
        (s) => s.id == _selectedSectionId,
      );
    } catch (e) {
      section = null;
    }

    if (section == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('السكشن المحدد غير موجود'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (kDebugMode) {
      print('   ✅ Found section: ${section.name}');
      print('   👤 Assistant ID: ${section.assistantId}');
    }

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
      if (kDebugMode) {
        print('   🔄 Starting to load materials...');
      }

      // Use service directly to avoid AutoDispose issues
      final materialsService = MaterialsService();
      final availableMaterials = await materialsService
          .getMaterialsBySubjectAndAssistant(
            _selectedSubjectId!,
            section.assistantId,
          );

      if (kDebugMode) {
        print('   ✅ Materials loaded successfully');
      }

      if (!mounted) {
        if (kDebugMode) {
          print('   ⚠️ Widget not mounted, aborting');
        }
        Navigator.of(context).pop(); // Close loading
        return;
      }

      if (kDebugMode) {
        print('   📚 Available materials count: ${availableMaterials.length}');
        for (var i = 0; i < availableMaterials.length; i++) {
          print(
            '      [$i] ${availableMaterials[i].displayTitle} (${availableMaterials[i].type.name})',
          );
        }
      }

      // Close loading indicator
      Navigator.of(context).pop();

      if (!mounted) return;

      if (availableMaterials.isEmpty) {
        if (kDebugMode) {
          print('   ⚠️ No materials available, showing warning');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد مواد متاحة لهذا السكشن'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (kDebugMode) {
        print('   📖 Opening material selection dialog...');
      }

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
        if (kDebugMode) {
          print('   ✅ User selected ${selected.length} material(s):');
          for (var material in selected) {
            print('      - ${material.displayTitle}');
          }
        }

        if (mounted) {
          setState(() {
            for (var material in selected) {
              if (!selectedMaterials.any((m) => m['url'] == material.url)) {
                selectedMaterials.add({
                  'title': material.displayTitle,
                  'url': material.url,
                });
                if (kDebugMode) {
                  print('      ➕ Added: ${material.displayTitle}');
                }
              } else {
                if (kDebugMode) {
                  print(
                    '      ⏭️ Skipped (already added): ${material.displayTitle}',
                  );
                }
              }
            }
          });
        }

        if (kDebugMode) {
          print(
            '   📊 Total materials now attached: ${selectedMaterials.length}',
          );
        }
      } else {
        if (kDebugMode) {
          print('   ❌ No materials selected or dialog cancelled');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('   ❌ ERROR in material selection: $e');
        print('   Stack trace: ${StackTrace.current}');
      }

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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          title: Text(
            _isEditing ? 'تعديل التاسك' : 'اضافة تاسك جديد',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            // Save button in app bar
            if (_isSaving)
              Container(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.small),
                ),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
              )
            else
              IconButton(
                onPressed: _saveTask,
                icon: Icon(
                  _isEditing
                      ? Icons.check_circle_outline_rounded
                      : Icons.add_circle_outline_rounded,
                  color: Colors.black,
                ),
                tooltip: _isEditing ? 'حفظ التعديلات' : 'إضافة التاسك',
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Animated content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: Responsive.padding(context, size: Space.large),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Header section
                            Container(
                              padding: Responsive.padding(
                                context,
                                size: Space.medium,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Colors.blue.withOpacity(0.1),
                                    Colors.blue.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  Responsive.space(context, size: Space.medium),
                                ),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.task_alt,
                                    color: Colors.blue[700],
                                    size: Responsive.space(
                                      context,
                                      size: Space.large,
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
                                          _isEditing
                                              ? 'تعديل تفاصيل التاسك'
                                              : 'اكتب تفاصيل التاسك',
                                          style: TextStyle(
                                            fontSize: Responsive.text(
                                              context,
                                              size: TextSize.heading,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                        Text(
                                          'املأ جميع الحقول المطلوبة',
                                          style: TextStyle(
                                            fontSize: Responsive.text(
                                              context,
                                              size: TextSize.small,
                                            ),
                                            color: Colors.blue[600],
                                          ),
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
                                size: Space.medium,
                              ),
                            ),

                            Text(
                              'عنوان التاسك:',
                              style: labelStyle,
                              textAlign: TextAlign.right,
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
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
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Text(
                              'تفاصيل التاسك:',
                              style: labelStyle,
                              textAlign: TextAlign.right,
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
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
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),

                            // Due Date Field
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: EdgeInsets.all(
                                  Responsive.space(context, size: Space.large),
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade50,
                                      Colors.blue.shade100,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
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
                                        Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.blue.shade700,
                                        size: Responsive.space(
                                          context,
                                          size: Space.medium,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: Responsive.space(
                                        context,
                                        size: Space.medium,
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),

                            // Importance Field
                            Container(
                              padding: EdgeInsets.all(
                                Responsive.space(context, size: Space.large),
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getImportanceColor(
                                      _selectedImportance,
                                    ).withOpacity(0.1),
                                    _getImportanceColor(
                                      _selectedImportance,
                                    ).withOpacity(0.2),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          Responsive.space(
                                            context,
                                            size: Space.small,
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getImportanceColor(
                                            _selectedImportance,
                                          ).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.flag_rounded,
                                          color: _getImportanceColor(
                                            _selectedImportance,
                                          ),
                                          size: Responsive.space(
                                            context,
                                            size: Space.medium,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: Responsive.space(
                                          context,
                                          size: Space.medium,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'الأهمية',
                                            style: TextStyle(
                                              fontSize: Responsive.text(
                                                context,
                                                size: TextSize.small,
                                              ),
                                              color: _getImportanceColor(
                                                _selectedImportance,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            _importanceLabels[_selectedImportance] ??
                                                'N/A',
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
                                      color: _getImportanceColor(
                                        _selectedImportance,
                                      ),
                                      size: Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                    itemBuilder:
                                        (BuildContext context) =>
                                            TaskImportance.values.map((
                                              TaskImportance importance,
                                            ) {
                                              return PopupMenuItem<
                                                TaskImportance
                                              >(
                                                value: importance,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.flag_rounded,
                                                      color:
                                                          _getImportanceColor(
                                                            importance,
                                                          ),
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      _importanceLabels[importance] ??
                                                          'N/A',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            importance ==
                                                                    _selectedImportance
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .normal,
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
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),

                            // Materials Section
                            if (selectedMaterials.isNotEmpty) ...[
                              Container(
                                padding: EdgeInsets.all(
                                  Responsive.space(context, size: Space.medium),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
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
                                      height: Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                    ...selectedMaterials.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final material = entry.value;
                                      return Container(
                                        margin: EdgeInsets.only(
                                          bottom: Responsive.space(
                                            context,
                                            size: Space.tiny,
                                          ),
                                        ),
                                        padding: EdgeInsets.all(
                                          Responsive.space(
                                            context,
                                            size: Space.small,
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            Responsive.space(
                                              context,
                                              size: Space.small,
                                            ),
                                          ),
                                          border: Border.all(
                                            color: Colors.blue[100]!,
                                          ),
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
                                                  selectedMaterials.removeAt(
                                                    index,
                                                  );
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
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
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
                                  horizontal: Responsive.space(
                                    context,
                                    size: Space.large,
                                  ),
                                  vertical: Responsive.space(
                                    context,
                                    size: Space.medium,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
