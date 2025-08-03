import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:provider/provider.dart';
import '../../models/custom_text_field.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Enum to map display names to full tag formats
enum DepartmentTag {
  general('عام', 'عام'),
  sc('SC', 'اخبار قسم SC'),
  ai('AI', 'اخبار قسم AI'),
  cs('CS', 'اخبار قسم CS'),
  informationSystems('IS', 'اخبار قسم IS'),
  generalDept('General', 'اخبار قسم General');

  const DepartmentTag(this.displayName, this.fullTag);
  final String displayName;
  final String fullTag;
}

// Available colors for selection
final List<Color> availableColors = [
  const Color(0xffff5252), // Red
  const Color(0xFFFFEF86), // Yellow
  const Color(0xFF99F16C), // Green
];

// Available tags (categories) for selection
final List<String> availableTags =
    DepartmentTag.values.map((tag) => tag.displayName).toList();

class AddAnnouncementScreen extends StatefulWidget {
  final bool isEditing;
  final AnnouncementData? announcement;

  const AddAnnouncementScreen({
    super.key,
    this.isEditing = false,
    this.announcement,
  });

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Animation controllers
  late AnimationController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form data
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _title = '';
  String _description = '';
  Color _selectedColor = availableColors[0];
  List<String> _selectedTags = [];
  final List<XFile> _pickedImages = [];
  List<Map<String, String>> _links = [];
  DateTime? _publishAt;
  DateTime? _expireAt;
  bool _isDraft = false;
  bool _isPinned = false;

  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeInOut),
    );

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
      _publishAt = widget.announcement!.publishAt;
      _expireAt = widget.announcement!.expireAt;
      _isDraft = widget.announcement!.draft;
      _isPinned = widget.announcement!.pinned;

      // Convert full tags to display names
      _selectedTags =
          widget.announcement!.tags
              .map((fullTag) {
                final match =
                    DepartmentTag.values
                        .where((tag) => tag.fullTag == fullTag)
                        .toList();
                return match.isNotEmpty ? match.first.displayName : null;
              })
              .whereType<String>()
              .toList();

      _links = List<Map<String, String>>.from(widget.announcement!.links ?? []);
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
        return true; // Optional step
      case 2: // Styling
        return _selectedTags.isNotEmpty;
      case 3: // Scheduling
        return true; // Optional step
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceedToNextStep() && _currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.reset();
      _pageController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.reset();
      _pageController.forward();
    }
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
      final announcementProvider = Provider.of<AnnouncementProvider>(
        context,
        listen: false,
      );
      List<String> imageUrls = [];

      // Start with existing images if editing
      if (widget.isEditing && widget.announcement?.imageUrls != null) {
        imageUrls.addAll(widget.announcement!.imageUrls);
      }

      // Upload new images
      for (XFile image in _pickedImages) {
        final String? imageUrl = await announcementProvider.uploadImage(image);
        if (imageUrl != null) {
          imageUrls.add(imageUrl);
        }
      }

      // Convert tags to full format
      final convertedTags =
          _selectedTags.map((displayName) {
            final departmentTag = DepartmentTag.values.firstWhere(
              (tag) => tag.displayName == displayName,
              orElse: () => DepartmentTag.general,
            );
            return departmentTag.fullTag;
          }).toList();

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
        draft: _isDraft,
        pinned: _isPinned,
        publishAt: _publishAt,
        expireAt: _expireAt,
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      // Save the announcement
      if (widget.isEditing) {
        announcementProvider.updateAnnouncement(newAnnouncement);
      } else {
        announcementProvider.addAnnouncement(newAnnouncement);
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
        return _buildBasicInfoStep();
      case 1:
        return _buildAttachmentsStep();
      case 2:
        return _buildStylingStep();
      case 3:
        return _buildSchedulingStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: Responsive.padding(context, size: Space.large),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: Colors.blue[700],
                    size: Responsive.space(context, size: Space.large) * 1.5,
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المعلومات الأساسية',
                          style: TextStyle(
                            fontSize:
                                Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ) *
                                1.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        Text(
                          'أدخل العنوان والوصف للإعلان',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
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
            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Title field
            CustomTextField(
              hint: 'العنوان',
              controller: _titleController,
              onChanged: (value) => setState(() => _title = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال العنوان';
                }
                if (value.length > 50) {
                  return 'العنوان طويل جداً (الحد الأقصى 50 حرف)';
                }
                return null;
              },
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),

            // Character count indicator
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_titleController.text.length}/50',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color:
                      _titleController.text.length > 45
                          ? Colors.orange
                          : _titleController.text.length > 50
                          ? Colors.red
                          : Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),

            // Description field
            CustomTextField(
              hint: 'الوصف',
              controller: _descriptionController,
              onChanged: (value) => setState(() => _description = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال الوصف';
                }
                return null;
              },
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 4,
              maxLines: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: Responsive.padding(context, size: Space.large),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    color: Colors.green[700],
                    size: Responsive.space(context, size: Space.large) * 1.5,
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المرفقات',
                          style: TextStyle(
                            fontSize:
                                Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ) *
                                1.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          'أضف الصور والملفات والروابط (اختياري)',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Attachment buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentButton(
                  icon: Icons.image,
                  label: 'صورة',
                  color: Colors.green,
                  onTap: () => _pickImages(),
                ),
                _buildAttachmentButton(
                  icon: Icons.picture_as_pdf,
                  label: 'ملف PDF',
                  color: Colors.orange,
                  onTap: () => _pickPdfFile(),
                ),
                _buildAttachmentButton(
                  icon: Icons.add_link,
                  label: 'رابط',
                  color: Colors.blue,
                  onTap: () => _showAddLinkDialog(),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Display selected attachments
            if (_pickedImages.isNotEmpty || _links.isNotEmpty)
              Container(
                padding: Responsive.padding(context, size: Space.medium),
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
                    Text(
                      'المرفقات المحددة:',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    // Images
                    if (_pickedImages.isNotEmpty) ...[
                      Text(
                        'الصور (${_pickedImages.length})',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                    ],

                    // Links
                    if (_links.isNotEmpty) ...[
                      Text(
                        'الروابط (${_links.length})',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStylingStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: Responsive.padding(context, size: Space.large),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.palette,
                    color: Colors.purple[700],
                    size: Responsive.space(context, size: Space.large) * 1.5,
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التصميم والأقسام',
                          style: TextStyle(
                            fontSize:
                                Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ) *
                                1.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                        Text(
                          'اختر اللون والأقسام المستهدفة',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            color: Colors.purple[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Color selection
            Text(
              'اختر مستوى الأهمية:',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorOption(
                  color: const Color(0xFFFF5252),
                  label: 'مهم',
                  isSelected: _selectedColor == const Color(0xFFFF5252),
                ),
                _buildColorOption(
                  color: const Color(0xFFFFEF86),
                  label: 'متوسط',
                  isSelected: _selectedColor == const Color(0xFFFFEF86),
                ),
                _buildColorOption(
                  color: const Color(0xFF99F16C),
                  label: 'عادي',
                  isSelected: _selectedColor == const Color(0xFF99F16C),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Tags selection
            Text(
              'اختر الأقسام المستهدفة:',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            Wrap(
              spacing: Responsive.space(context, size: Space.medium),
              runSpacing: Responsive.space(context, size: Space.small),
              alignment: WrapAlignment.center,
              children:
                  availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (!_selectedTags.contains(tag)) {
                              _selectedTags.add(tag);
                            }
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                      selectedColor: _selectedColor,
                      backgroundColor: Colors.grey[200],
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
                        vertical: Responsive.space(context, size: Space.small),
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Draft and Pinned options
            Text(
              'خيارات الإعلان:',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Draft option
                GestureDetector(
                  onTap: () => setState(() => _isDraft = !_isDraft),
                  child: Container(
                    padding: Responsive.padding(context, size: Space.medium),
                    decoration: BoxDecoration(
                      color:
                          _isDraft
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      border: Border.all(
                        color: _isDraft ? Colors.orange : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isDraft ? Icons.save : Icons.save_outlined,
                          color:
                              _isDraft ? Colors.orange[700] : Colors.grey[600],
                          size: Responsive.space(context, size: Space.large),
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        Text(
                          'مسودة',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight:
                                _isDraft ? FontWeight.bold : FontWeight.normal,
                            color:
                                _isDraft
                                    ? Colors.orange[700]
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pinned option
                GestureDetector(
                  onTap: () => setState(() => _isPinned = !_isPinned),
                  child: Container(
                    padding: Responsive.padding(context, size: Space.medium),
                    decoration: BoxDecoration(
                      color:
                          _isPinned
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      border: Border.all(
                        color: _isPinned ? Colors.red : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          color: _isPinned ? Colors.red[700] : Colors.grey[600],
                          size: Responsive.space(context, size: Space.large),
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        Text(
                          'مثبت',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight:
                                _isPinned ? FontWeight.bold : FontWeight.normal,
                            color:
                                _isPinned ? Colors.red[700] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: Responsive.padding(context, size: Space.large),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Colors.orange[700],
                    size: Responsive.space(context, size: Space.large) * 1.5,
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جدولة النشر',
                          style: TextStyle(
                            fontSize:
                                Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ) *
                                1.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                        Text(
                          'حدد مواعيد النشر والانتهاء (اختياري)',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Publish date
            _buildDateTimeSelector(
              title: 'تاريخ النشر',
              value: _publishAt,
              icon: Icons.publish,
              color: Colors.blue,
              onTap: () => _selectDateTime(true),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),

            // Expiry date
            _buildDateTimeSelector(
              title: 'تاريخ الانتهاء',
              value: _expireAt,
              icon: Icons.event_busy,
              color: Colors.red,
              onTap: () => _selectDateTime(false),
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Info card
            Container(
              padding: Responsive.padding(context, size: Space.large),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: Responsive.space(context, size: Space.large),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child: Text(
                      'إذا لم تحدد مواعيد، سيتم نشر الإعلان فوراً',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.blue[700],
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

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: Responsive.padding(context, size: Space.large),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: Responsive.space(context, size: Space.large) * 1.5,
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption({
    required Color color,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 3,
              ),
            ),
            child:
                isSelected
                    ? Center(
                      child: Icon(Icons.check, color: Colors.black87, size: 40),
                    )
                    : null,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector({
    required String title,
    required DateTime? value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: Responsive.padding(context, size: Space.large),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: Responsive.space(context, size: Space.large),
            ),
            SizedBox(width: Responsive.space(context, size: Space.medium)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    value != null
                        ? DateFormat('yyyy/MM/dd HH:mm').format(value)
                        : 'غير محدد',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: value != null ? color : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              IconButton(
                icon: Icon(Icons.clear, size: 24, color: Colors.red[400]),
                onPressed: () {
                  setState(() {
                    if (title.contains('النشر')) {
                      _publishAt = null;
                    } else {
                      _expireAt = null;
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final hasPermission =
        await PermissionService.requestPhotosPermissionWithRationale(context);
    if (!hasPermission) return;

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        for (var img in images) {
          if (!_pickedImages.any((i) => i.path == img.path)) {
            _pickedImages.add(img);
          }
        }
      });
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(
                      width: Responsive.space(context, size: Space.medium),
                    ),
                    const Text('جاري رفع الملف...'),
                  ],
                ),
              ),
        );

        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = await file.length();

        if (fileSize > 10 * 1024 * 1024) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حجم الملف أكبر من 10 ميجابايت'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final storageRef = FirebaseStorage.instance.ref().child(
          'announcements/attachments/${DateTime.now().millisecondsSinceEpoch}_$fileName',
        );

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        Navigator.of(context).pop(); // Close loading dialog

        // Get custom title for the file
        String? linkTitle = await _showFileTitleDialog(fileName);

        setState(() {
          if (!_links.any((l) => l['url'] == downloadUrl)) {
            _links.add({'title': linkTitle ?? fileName, 'url': downloadUrl});
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الملف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في رفع الملف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showFileTitleDialog(String fileName) async {
    String tempTitle = fileName;
    final TextEditingController controller = TextEditingController(
      text: fileName,
    );

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل اسم الملف'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'اسم الملف',
              hintText: 'أدخل اسم الملف كما تريد أن يظهر',
            ),
            onChanged: (value) => tempTitle = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempTitle),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _showAddLinkDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة رابط جديد'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'الرجاء إدخال العنوان'
                              : null,
                ),
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'الرابط'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'الرجاء إدخال الرابط'
                              : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    if (!_links.any((l) => l['url'] == urlController.text)) {
                      _links.add({
                        'title': titleController.text,
                        'url': urlController.text,
                      });
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDateTime(bool isPublishDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isPublishDate
              ? (_publishAt ?? DateTime.now())
              : (_expireAt ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isPublishDate
              ? (_publishAt ?? DateTime.now())
              : (_expireAt ?? DateTime.now()),
        ),
      );

      if (time != null) {
        setState(() {
          final selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );

          if (isPublishDate) {
            _publishAt = selectedDateTime;
          } else {
            _expireAt = selectedDateTime;
          }
        });
      }
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
                  final isActive = index <= _currentStep;
                  final isCompleted = index < _currentStep;

                  return Expanded(
                    child: Container(
                      height: 6,
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
                        child: Text(
                          'السابق',
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
                  if (_currentStep == 0) const Spacer(),

                  if (_currentStep < _totalSteps - 1)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canProceedToNextStep() ? _nextStep : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
                          'التالي',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
