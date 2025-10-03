import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/subject_model.dart';

class AddEditSectionDialog extends ConsumerStatefulWidget {
  final List<Subject> subjects;
  final String? initialSubjectId;
  final Section? sectionToEdit;
  final String? targetAssistantId; // The assistant whose profile we're viewing
  final String? autoSelectedSubjectId; // Auto-select subject from current tab

  const AddEditSectionDialog({
    super.key,
    required this.subjects,
    this.initialSubjectId,
    this.sectionToEdit,
    this.targetAssistantId,
    this.autoSelectedSubjectId,
  });

  @override
  ConsumerState<AddEditSectionDialog> createState() =>
      _AddEditSectionDialogState();
}

class _AddEditSectionDialogState extends ConsumerState<AddEditSectionDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedSubjectId;
  String? _targetAssistantId; // The assistant whose profile we're viewing
  String _selectedType = 'سكشن';
  late TextEditingController _sectionNumberController;
  List<bool> _selectedDays = List.filled(6, false);
  TimeOfDay? _selectedTime;
  late TextEditingController _locationController;

  bool get _isEditing => widget.sectionToEdit != null;

  final List<String> _dayNames = const [
    'السبت',
    'الاحد',
    'الاثنين',
    'الثلاثاء',
    'الاربعاء',
    'الخميس',
  ];

  @override
  void initState() {
    super.initState();

    _sectionNumberController = TextEditingController();
    _locationController = TextEditingController();
    _selectedDays = List.filled(_dayNames.length, false);

    // Set target assistant ID from widget parameter or from editing section
    if (widget.targetAssistantId != null) {
      _targetAssistantId = widget.targetAssistantId;
    }

    // Handle editing mode first
    if (_isEditing && widget.sectionToEdit != null) {
      final section = widget.sectionToEdit!;
      _selectedSubjectId = section.subjectId;
      _targetAssistantId = section.assistantId; // Set assistant ID for editing
      _parseAndSetTypeAndNumber(section.name);
      _parseAndSetDays(section.days);
      _selectedTime = _parseTimeString(section.time);
      _locationController.text = section.location;
    } else {
      // Set subject ID for new sections - prioritize auto-selected subject, then initial subject, then first subject
      if (widget.autoSelectedSubjectId != null) {
        _selectedSubjectId = widget.autoSelectedSubjectId;
      } else if (widget.initialSubjectId != null) {
        _selectedSubjectId = widget.initialSubjectId;
      } else if (widget.subjects.isNotEmpty) {
        _selectedSubjectId = widget.subjects.first.id;
      }
    }
  }

  void _parseAndSetTypeAndNumber(String title) {
    final titleParts = title.split(' ');
    if (titleParts.length == 2 &&
        (titleParts[0] == 'سكشن' || titleParts[0] == 'عملي') &&
        int.tryParse(titleParts[1]) != null) {
      _selectedType = titleParts[0];
      _sectionNumberController.text = titleParts[1];
    } else {
      _sectionNumberController.text = title;
      _selectedType = 'سكشن';
    }
  }

  void _parseAndSetDays(String daysString) {
    final dayParts = daysString.split(' و ');
    for (String part in dayParts) {
      final index = _dayNames.indexOf(part);
      if (index != -1) {
        _selectedDays[index] = true;
      }
    }
  }

  TimeOfDay? _parseTimeString(String timeString) {
    if (timeString.isEmpty) return null;
    try {
      final format = DateFormat.jm('ar');
      final dateTime = format.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _sectionNumberController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _formatSelectedDays() {
    List<String> selectedDayNames = [];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        selectedDayNames.add(_dayNames[i]);
      }
    }
    return selectedDayNames.join(' و ');
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm('ar').format(dt);
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Validate subject selection
    if (_selectedSubjectId == null) {
      _showValidationError('يرجى اختيار المادة');
      return;
    }

    // Validate days selection
    if (!_selectedDays.any((d) => d)) {
      _showValidationError('يرجى اختيار يوم واحد على الأقل');
      return;
    }

    // Validate time selection
    if (_selectedTime == null) {
      _showValidationError('يرجى اختيار الوقت');
      return;
    }

    // Get the current user and determine the assistant ID
    final userProfileState = ref.read(userProfileProvider);
    final currentUser = userProfileState.loggedInUserProfile;

    if (currentUser == null) {
      _showValidationError('لا يمكن تحديد المستخدم الحالي');
      return;
    }

    // Determine the assistant ID based on user role
    String assistantId;
    if (currentUser.role == 'Admin' || currentUser.role == 'Super Admin') {
      // Admin creates sections for the assistant whose profile they're viewing
      if (_targetAssistantId == null) {
        _showValidationError('لا يمكن تحديد المعيد المستهدف');
        return;
      }
      assistantId = _targetAssistantId!;
    } else {
      // Mini professor creates sections for themselves
      assistantId = currentUser.id;
    }

    final newSection = Section(
      id: _isEditing ? widget.sectionToEdit!.id : '',
      name: '$_selectedType ${_sectionNumberController.text.trim()}',
      assistantId: assistantId, // Sections belong to the selected assistant
      subjectId:
          _selectedSubjectId!, // Reference to which subject this section is for
      days: _formatSelectedDays(),
      time: _selectedTime != null ? _formatTimeOfDay(_selectedTime!) : '',
      location: _locationController.text.trim(),
    );

    try {
      if (_isEditing) {
        await ref.read(sectionsProvider.notifier).updateSection(newSection);
      } else {
        await ref.read(sectionsProvider.notifier).addSection(newSection);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showValidationError('حدث خطأ أثناء حفظ السكشن: ${e.toString()}');
    }
  }

  void _showValidationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'اختر وقت السكشن',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Colors.black,
              hourMinuteColor: Colors.grey[100],
              hourMinuteTextStyle: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
                fontWeight: FontWeight.bold,
              ),
              dialBackgroundColor: Colors.grey[100],
              dialHandColor: Colors.black,
              dialTextColor: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDialog(
      title: _isEditing ? 'تعديل السكشن' : 'إضافة سكشن جديد',
      subtitle:
          _isEditing ? 'قم بتعديل بيانات السكشن' : 'أدخل بيانات السكشن الجديد',
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Subject Display (auto-selected from current tab)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[50],
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.book, color: Colors.grey[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.subjects
                            .firstWhere(
                              (subject) => subject.id == _selectedSubjectId,
                              orElse: () => widget.subjects.first,
                            )
                            .name,
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Section Number and Type Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        items:
                            ['سكشن', 'عملي'].map((String value) {
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
                            }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedType = newValue;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'النوع',
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
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.space(context, size: Space.small)),
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextFormField(
                        controller: _sectionNumberController,
                        decoration: InputDecoration(
                          hintText: 'الرقم',
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
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'مطلوب';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Days Selection
              Text(
                'أيام الحضور',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      List<Widget>.generate(_dayNames.length, (int index) {
                        final isSelected = _selectedDays[index];
                        return Container(
                          margin: EdgeInsets.only(
                            left: Responsive.space(context, size: Space.small),
                          ),
                          child: FilterChip(
                            label: Text(
                              _dayNames[index],
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedDays[index] = selected;
                              });
                            },
                            selectedColor: Colors.black,
                            backgroundColor: Colors.grey[200],
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.large),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Time Selection
              Text(
                'وقت السكشن',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              InkWell(
                onTap: _selectTime,
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
                        Icons.access_time_rounded,
                        color: Colors.black,
                        size: Responsive.space(context, size: Space.medium),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        child: Text(
                          _selectedTime != null
                              ? _formatTimeOfDay(_selectedTime!)
                              : 'اضغط لاختيار الوقت',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight:
                                _selectedTime != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                _selectedTime != null
                                    ? Colors.black87
                                    : Colors.grey[600],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Location Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'مثال: قاعة 3',
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
                  keyboardType: TextInputType.text,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'يرجى إدخال المكان'
                              : null,
                ),
              ),
            ],
          ),
        ),
      ),
      confirmText: _isEditing ? 'حفظ التعديلات' : 'إضافة السكشن',
      confirmIcon:
          _isEditing
              ? Icons.save_alt_rounded
              : Icons.add_circle_outline_rounded,
      onConfirm: _submitForm,
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
