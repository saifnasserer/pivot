import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pivot/features/announcements/providers/announcements_provider.dart';
import 'package:pivot/features/home/screens/adminstration/models/announcement_data.dart';
import 'package:pivot/features/home/screens/adminstration/announcement/add_announcement_controller.dart';
import 'package:pivot/features/home/screens/adminstration/announcement/steps/basic_info_step.dart';
import 'package:pivot/features/home/screens/adminstration/announcement/steps/attachments_step.dart';
import 'package:pivot/features/home/screens/adminstration/announcement/steps/styling_step.dart';
import 'package:pivot/features/home/screens/adminstration/announcement/steps/advanced_options_step.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pivot/responsive.dart';

class AddAnnouncementMain extends ConsumerStatefulWidget {
  final bool isEditing;
  final AnnouncementData? announcement;

  const AddAnnouncementMain({
    super.key,
    this.isEditing = false,
    this.announcement,
  });

  @override
  ConsumerState<AddAnnouncementMain> createState() =>
      _AddAnnouncementMainState();
}

class _AddAnnouncementMainState extends ConsumerState<AddAnnouncementMain>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps =
      4; // Basic Info, Attachments (Images & Links), Styling, Advanced Options

  // Animation controllers
  late AnimationController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isForwardDirection = true;

  // Form data
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _title = '';
  String _description = '';
  Color _selectedColor = AddAnnouncementController.availableColors[0];
  List<String> _selectedTags = [];
  List<String> _selectedLevels = [];
  final List<XFile> _pickedImages = [];
  List<Map<String, String>> _links = [];

  // Advanced options
  bool _isPinned = false;
  DateTime? _publishAt;
  DateTime? _expireAt;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _updateSlideAnimation();

    // Start animations
    _fadeController.forward();
    _pageController.forward();
  }

  void _initializeData() {
    if (widget.announcement != null) {
      _titleController.text = widget.announcement!.title;
      _descriptionController.text = widget.announcement!.description;
      _title = widget.announcement!.title;
      _description = widget.announcement!.description;
      _selectedColor = widget.announcement!.color;
      // Convert single level to list for backward compatibility
      if (widget.announcement!.level != null) {
        _selectedLevels = widget.announcement!.level!.split(',');
      }

      // Convert full tags to display names
      _selectedTags =
          widget.announcement!.tags
              .map((fullTag) {
                final match =
                    AddAnnouncementController.departmentTags
                        .where((tag) => tag.fullTag == fullTag)
                        .toList();
                return match.isNotEmpty ? match.first.displayName : null;
              })
              .whereType<String>()
              .toList();

      _links = List<Map<String, String>>.from(widget.announcement!.links);

      // Initialize advanced options
      _isPinned = widget.announcement!.pinned;
      _publishAt = widget.announcement!.publishAt;
      _expireAt = widget.announcement!.expireAt;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: // Basic Info
        return _title.trim().isNotEmpty &&
            _description.trim().isNotEmpty &&
            _title.length <= 50;
      case 1: // Attachments
        return true; // Optional step - images and links only
      case 2: // Styling
        return _selectedTags.isNotEmpty && _selectedLevels.isNotEmpty;
      case 3: // Advanced Options
        return true; // Optional step - scheduling and status
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceedToNextStep() && _currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        _isForwardDirection = true;
      });
      _updateSlideAnimation();
      _pageController.reset();
      _pageController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _isForwardDirection = false;
      });
      _updateSlideAnimation();
      _pageController.reset();
      _pageController.forward();
    }
  }

  void _updateSlideAnimation() {
    _slideAnimation = Tween<Offset>(
      begin:
          _isForwardDirection
              ? const Offset(-1.0, 0.0)
              : const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeInOut),
    );
  }

  void _saveAnnouncement() async {
    if (!_canProceedToNextStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: Responsive.padding(context, size: Space.large),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                const Text("جاري حفظ الإعلان..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      List<String> imageUrls = [];

      // Start with existing images if editing
      if (widget.isEditing && widget.announcement?.imageUrls != null) {
        imageUrls.addAll(widget.announcement!.imageUrls);
      }

      // Upload new images
      if (_pickedImages.isNotEmpty) {
        print('📤 Uploading ${_pickedImages.length} images...');
        final imagePaths = _pickedImages.map((img) => img.path).toList();
        final uploadedUrls = await ref
            .read(announcementsProvider.notifier)
            .uploadAnnouncementImages(imagePaths);
        imageUrls.addAll(uploadedUrls);
        print('✅ Uploaded ${uploadedUrls.length} images');
      }

      // Convert tags to full format
      final convertedTags =
          _selectedTags.map((displayName) {
            final departmentTag = AddAnnouncementController.departmentTags
                .firstWhere(
                  (tag) => tag.displayName == displayName,
                  orElse: () => AddAnnouncementController.departmentTags.first,
                );
            return departmentTag.fullTag;
          }).toList();

      // Extract department from the first tag (since tags contain department info)
      final department = convertedTags.isNotEmpty ? convertedTags.first : null;

      final newAnnouncement = AnnouncementData(
        id: widget.announcement?.id,
        title: _title,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        color: _selectedColor,
        description: _description,
        tags: convertedTags,
        imageUrls: imageUrls,
        links: _links,
        timestamp: DateTime.now(),
        draft: false, // Always published (draft option removed)
        pinned: _isPinned,
        publishAt: _publishAt ?? DateTime.now(), // Use selected date or now
        expireAt: _expireAt,
        level: _selectedLevels.join(','), // Store as comma-separated string
        department: department, // Store department for filtering
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      // Save the announcement
      if (widget.isEditing) {
        await ref
            .read(announcementsProvider.notifier)
            .updateAnnouncement(widget.announcement!.id!, newAnnouncement);
      } else {
        await ref
            .read(announcementsProvider.notifier)
            .addAnnouncement(newAnnouncement);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'تم تحديث الإعلان بنجاح'
                : 'تم إضافة الإعلان بنجاح',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.of(context).pop();
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في حفظ الإعلان: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return BasicInfoStep(
          titleController: _titleController,
          descriptionController: _descriptionController,
          title: _title,
          description: _description,
          onTitleChanged: (value) => setState(() => _title = value),
          onDescriptionChanged: (value) => setState(() => _description = value),
          fadeAnimation: _fadeAnimation,
          slideAnimation: _slideAnimation,
        );
      case 1:
        return AttachmentsStep(
          pickedImages: _pickedImages,
          links: _links,
          onImagesChanged:
              (images) => setState(() {
                _pickedImages.clear();
                _pickedImages.addAll(images);
              }),
          onLinksChanged: (links) => setState(() => _links = links),
          fadeAnimation: _fadeAnimation,
          slideAnimation: _slideAnimation,
        );
      case 2:
        return StylingStep(
          selectedColor: _selectedColor,
          selectedTags: _selectedTags,
          selectedLevels: _selectedLevels,
          onColorChanged: (color) => setState(() => _selectedColor = color),
          onTagsChanged: (tags) => setState(() => _selectedTags = tags),
          onLevelsChanged: (levels) => setState(() => _selectedLevels = levels),
          fadeAnimation: _fadeAnimation,
          slideAnimation: _slideAnimation,
        );
      case 3:
        return AdvancedOptionsStep(
          isPinned: _isPinned,
          publishAt: _publishAt,
          expireAt: _expireAt,
          onPinnedChanged: (value) => setState(() => _isPinned = value),
          onPublishAtChanged: (value) => setState(() => _publishAt = value),
          onExpireAtChanged: (value) => setState(() => _expireAt = value),
          fadeAnimation: _fadeAnimation,
          slideAnimation: _slideAnimation,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          widget.isEditing ? 'تعديل الإعلان' : 'إعلان جديد',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.heading),
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          // Progress indicator
          Container(
            margin: EdgeInsets.only(
              right: Responsive.space(context, size: Space.medium),
            ),
            child: Row(
              children: [
                Text(
                  '${_currentStep + 1}',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '/$_totalSteps',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Container(
              padding: Responsive.padding(context, size: Space.small),
              child: Row(
                children: List.generate(_totalSteps, (index) {
                  // reverse the list
                  final reversedIndex = _totalSteps - index - 1;
                  final isActive = reversedIndex <= _currentStep;
                  final isCompleted = reversedIndex < _currentStep;

                  return Expanded(
                    child: Container(
                      height: Responsive.space(context, size: Space.tiny),
                      margin: EdgeInsets.symmetric(
                        horizontal: Responsive.space(context, size: Space.tiny),
                      ),
                      decoration: BoxDecoration(
                        color:
                            isCompleted
                                ? Colors.green
                                : isActive
                                ? Colors.blue
                                : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: Responsive.padding(context, size: Space.large),
                child: _buildStepContent(),
              ),
            ),

            // Navigation buttons
            Container(
              padding: Responsive.padding(context, size: Space.large),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  if (_currentStep < _totalSteps - 1)
                    ElevatedButton(
                      onPressed: _canProceedToNextStep() ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: Responsive.space(context, size: Space.medium),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _canProceedToNextStep() ? _saveAnnouncement : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          widget.isEditing ? 'تحديث' : 'إضافة',
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
                  if (_currentStep == _totalSteps - 1) const Spacer(),

                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.blue,
                          size: Responsive.space(context, size: Space.medium),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
