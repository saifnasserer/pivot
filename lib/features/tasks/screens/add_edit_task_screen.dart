import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/subjects/providers/subject_provider.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/features/auth/providers/auth_provider.dart';
import 'package:pivot/features/tasks/providers/tasks_provider.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/services/file_upload_service.dart';
import 'package:pivot/features/home/screens/adminstration/animated_route.dart';

// Import feature files
import 'add_edit_task/features/file_upload_feature.dart';
import 'add_edit_task/features/material_selection_feature.dart';
import 'add_edit_task/features/form_fields_feature.dart';
import 'add_edit_task/features/attachments_display_feature.dart';

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
      child: AddEditTaskScreenRefactored(
        onSave: onSave,
        task: task,
        subjectId: subjectId,
        initialSectionId: initialSectionId,
      ),
    ),
  );
}

class AddEditTaskScreenRefactored extends ConsumerStatefulWidget {
  final Future<void> Function(Task) onSave;
  final Task? task;
  final String subjectId;
  final String? initialSectionId;

  const AddEditTaskScreenRefactored({
    super.key,
    required this.onSave,
    this.task,
    required this.subjectId,
    this.initialSectionId,
  });

  @override
  ConsumerState<AddEditTaskScreenRefactored> createState() =>
      _AddEditTaskScreenRefactoredState();
}

class _AddEditTaskScreenRefactoredState
    extends ConsumerState<AddEditTaskScreenRefactored>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskImportance _selectedImportance;
  String? _selectedSubjectId;
  String? _selectedSectionId;
  List<Map<String, String>> selectedMaterials = [];
  List<Map<String, String>> _uploadedFiles = [];
  List<Map<String, String>> _uploadedImages = [];
  List<Map<String, String>> _addedLinks = [];
  bool _isEditing = false;
  bool _isSaving = false;

  // Feature instances
  final FileUploadFeature _fileUploadFeature = FileUploadFeature();
  final MaterialSelectionFeature _materialSelectionFeature =
      MaterialSelectionFeature();
  final FormFieldsFeature _formFieldsFeature = FormFieldsFeature();
  final AttachmentsDisplayFeature _attachmentsDisplayFeature =
      AttachmentsDisplayFeature();
  final FileUploadService _fileUploadService = FileUploadService();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    print('💾 [TaskCreation] Starting task save process...');
    print('💾 [TaskCreation] Images to upload: ${_uploadedImages.length}');
    print('💾 [TaskCreation] Files to upload: ${_uploadedFiles.length}');
    print('💾 [TaskCreation] Links to add: ${_addedLinks.length}');

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

      // Upload local images and files first
      List<Map<String, String>> processedAttachments = [
        ...selectedMaterials,
        ..._addedLinks,
      ];

      print('🔄 [TaskCreation] Starting image upload process...');
      print('🔄 [TaskCreation] Processing ${_uploadedImages.length} images');

      // Upload images that are marked as local
      for (var imageData in _uploadedImages) {
        print(
          '🔄 [TaskCreation] Processing image: ${imageData['title']} - isLocal: ${imageData['isLocal']}',
        );
        if (imageData['isLocal'] == 'true') {
          // Compress image before upload
          try {
            print('🔄 Compressing image: ${imageData['url']}');
            final compressedImage = await FlutterImageCompress.compressWithFile(
              imageData['url']!,
              quality: 85,
              minWidth: 800,
              minHeight: 600,
            );

            if (compressedImage != null) {
              print('✅ Image compressed successfully');

              // Upload compressed image using Backblaze
              print('🔄 [TaskCreation] Starting Backblaze upload...');
              print('🔄 [TaskCreation] Subject ID: $_selectedSubjectId');
              print('🔄 [TaskCreation] Assistant ID: ${section.assistantId}');

              // Ensure the file has a proper extension
              final fileName = '${imageData['title'] ?? 'image'}.jpg';
              print('🔄 [TaskCreation] File name: $fileName');

              final uploadResult = await _fileUploadService.uploadFile(
                fileInfo: PickedFileInfo(
                  name: fileName,
                  size: compressedImage.length,
                  bytes: compressedImage,
                  extension: 'jpg',
                ),
                title: imageData['title'] ?? 'صورة مرفقة',
                description: 'مرفق تاسك',
                subjectId: _selectedSubjectId,
                assistantId: section.assistantId,
              );

              print(
                '🔄 [TaskCreation] Upload result: success=${uploadResult.success}',
              );
              print(
                '🔄 [TaskCreation] Download URL: ${uploadResult.downloadUrl}',
              );
              print('🔄 [TaskCreation] Error: ${uploadResult.error}');
              print(
                '🔄 [TaskCreation] File info: name=$fileName, size=${compressedImage.length}, extension=jpg',
              );

              if (uploadResult.success && uploadResult.downloadUrl != null) {
                final attachmentData = {
                  'title': imageData['title'] ?? 'صورة مرفقة',
                  'url': uploadResult.downloadUrl!,
                  'type': 'image',
                };
                processedAttachments.add(attachmentData);
                print('✅ Image uploaded successfully');
                print('🔗 Image URL: ${uploadResult.downloadUrl}');
                print('🔗 Attachment data: $attachmentData');
              } else {
                print('❌ Image upload failed - using local path as fallback');
                print('❌ Local image data: $imageData');
                processedAttachments.add(imageData);
              }
            } else {
              print('❌ Image compression failed');
              processedAttachments.add(imageData);
            }
          } catch (e) {
            print('❌ Failed to upload image: $e');
            // Keep original local data as fallback
            processedAttachments.add(imageData);
          }
        } else {
          // Already uploaded, add as is
          processedAttachments.add(imageData);
        }
      }

      // Upload files that are marked as local
      for (var fileData in _uploadedFiles) {
        if (fileData['isLocal'] == 'true') {
          // For now, skip file upload since we don't have the file info
          // This is a limitation of the current implementation
          print('⚠️ File upload skipped - file info not available');
          processedAttachments.add(fileData);
        } else {
          // Already uploaded, add as is
          processedAttachments.add(fileData);
        }
      }

      // Combine all attachments
      final allAttachments = processedAttachments;
      print(
        '📎 [TaskCreation] Final attachments count: ${allAttachments.length}',
      );
      for (var att in allAttachments) {
        print(
          '📎 [TaskCreation] Final attachment: ${att['title']} - Type: ${att['type']} - URL: ${att['url']}',
        );
      }

      final newTask = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDate,
        importance: _selectedImportance,
        subjectId: _selectedSubjectId!,
        sectionId: _selectedSectionId!,
        assistantId: section.assistantId,
        attachments: allAttachments,
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

  @override
  Widget build(BuildContext context) {
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
                                          'ضيف كل التفاصيل المطلوبة',
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

                            // Form fields using feature
                            _formFieldsFeature.buildTitleField(
                              context: context,
                              controller: _titleController,
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
                            _formFieldsFeature.buildDescriptionField(
                              context: context,
                              controller: _descriptionController,
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            _formFieldsFeature.buildDueDateField(
                              context: context,
                              selectedDate: _selectedDate,
                              onTap: () => _selectDate(context),
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            _formFieldsFeature.buildImportanceField(
                              context: context,
                              selectedImportance: _selectedImportance,
                              onChanged:
                                  (value) => setState(() {
                                    _selectedImportance = value;
                                  }),
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),

                            // Attachments sections using features
                            _attachmentsDisplayFeature.buildMaterialsSection(
                              context: context,
                              selectedMaterials: selectedMaterials,
                              onRemoveMaterial:
                                  (index) => setState(() {
                                    selectedMaterials.removeAt(index);
                                  }),
                            ),
                            if (selectedMaterials.isNotEmpty)
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),

                            _attachmentsDisplayFeature
                                .buildNewAttachmentsSection(
                                  context: context,
                                  uploadedFiles: _uploadedFiles,
                                  uploadedImages: _uploadedImages,
                                  addedLinks: _addedLinks,
                                  onRemoveFile:
                                      (index) => setState(() {
                                        _uploadedFiles.removeAt(index);
                                      }),
                                  onRemoveImage:
                                      (index) => setState(() {
                                        _uploadedImages.removeAt(index);
                                      }),
                                  onRemoveLink:
                                      (index) => setState(() {
                                        _addedLinks.removeAt(index);
                                      }),
                                ),
                            if (_uploadedFiles.isNotEmpty ||
                                _uploadedImages.isNotEmpty ||
                                _addedLinks.isNotEmpty)
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),

                            // Action buttons using feature
                            _attachmentsDisplayFeature.buildActionButtons(
                              context: context,
                              onAddMaterials:
                                  () => _materialSelectionFeature
                                      .showMaterialsSelectionDialog(
                                        context,
                                        selectedSubjectId: _selectedSubjectId,
                                        selectedSectionId: _selectedSectionId,
                                        alreadySelectedUrls:
                                            selectedMaterials
                                                .map((m) => m['url'] ?? '')
                                                .toList(),
                                        ref: ref,
                                        onMaterialsSelected: (materials) {
                                          setState(() {
                                            for (var material in materials) {
                                              if (!selectedMaterials.any(
                                                (m) => m['url'] == material.url,
                                              )) {
                                                selectedMaterials.add({
                                                  'title':
                                                      material.displayTitle,
                                                  'url': material.url,
                                                });
                                              }
                                            }
                                          });
                                        },
                                      ),
                              onAddImage:
                                  () => _fileUploadFeature
                                      .pickAndUploadImageDirect(
                                        context,
                                        onImageUploaded: (imageData) {
                                          setState(() {
                                            _uploadedImages.add(imageData);
                                          });
                                        },
                                      ),
                              onAddFile:
                                  () => _fileUploadFeature
                                      .pickAndUploadFileDirect(
                                        context,
                                        onFileUploaded: (fileData) {
                                          setState(() {
                                            _uploadedFiles.add(fileData);
                                          });
                                        },
                                        subjectId: _selectedSubjectId,
                                        assistantId:
                                            _selectedSectionId != null
                                                ? ref
                                                    .read(sectionsProvider)
                                                    .sections
                                                    .firstWhere(
                                                      (s) =>
                                                          s.id ==
                                                          _selectedSectionId,
                                                    )
                                                    .assistantId
                                                : null,
                                      ),
                              onAddLink:
                                  () => _fileUploadFeature.showAddLinkDialogDirect(
                                    context,
                                    onLinkAdded: (linkData) {
                                      print('🔗 Link added: $linkData');
                                      setState(() {
                                        _addedLinks.add(linkData);
                                        print(
                                          '🔗 Total links: ${_addedLinks.length}',
                                        );
                                      });
                                    },
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
}
