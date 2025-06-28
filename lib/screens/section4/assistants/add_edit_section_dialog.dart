import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/section_provider.dart';
import 'dart:ui' as ui;

class AddEditSectionDialog extends StatefulWidget {
  final List<Subject> subjects;
  final String? initialSubjectId;
  final Section? sectionToEdit;

  const AddEditSectionDialog({
    super.key,
    required this.subjects,
    this.initialSubjectId,
    this.sectionToEdit,
  });

  @override
  State<AddEditSectionDialog> createState() => _AddEditSectionDialogState();
}

class _AddEditSectionDialogState extends State<AddEditSectionDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedSubjectId;
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

    if (widget.initialSubjectId != null) {
      _selectedSubjectId = widget.initialSubjectId;
    } else if (widget.subjects.isNotEmpty) {
      _selectedSubjectId = widget.subjects.first.id;
    }

    if (_isEditing && widget.sectionToEdit != null) {
      final section = widget.sectionToEdit!;
      _selectedSubjectId = section.subjectId;
      _parseAndSetTypeAndNumber(section.name);
      _parseAndSetDays(section.days);
      _selectedTime = _parseTimeString(section.time);
      _locationController.text = section.location;
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

    final sectionProvider = Provider.of<SectionProvider>(
      context,
      listen: false,
    );

    final newSection = Section(
      id: _isEditing ? widget.sectionToEdit!.id : '',
      name: '$_selectedType ${_sectionNumberController.text.trim()}',
      subjectId: _selectedSubjectId!,
      days: _formatSelectedDays(),
      time: _selectedTime != null ? _formatTimeOfDay(_selectedTime!) : '',
      location: _locationController.text.trim(),
    );

    try {
      if (_isEditing) {
        await sectionProvider.updateSection(newSection);
      } else {
        await sectionProvider.addSection(newSection);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showValidationError('حدث خطأ أثناء حفظ السكشن: ${e.toString()}');
    }
  }

  void _showValidationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'اختر وقت السكشن',
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);
    final inputPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 12.0,
    );

    final commonDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: inputPadding,
      fillColor: Colors.grey.shade100,
      filled: true,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    );

    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade800,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      title: Text(
        _isEditing ? 'تعديل السكشن' : 'إضافة سكشن جديد',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: Responsive.paddingVertical(context, size: Space.small),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    items:
                        widget.subjects.map((Subject subject) {
                          return DropdownMenuItem<String>(
                            value: subject.id,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                subject.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubjectId = value;
                      });
                    },
                    decoration: commonDecoration.copyWith(labelText: 'المادة'),
                    validator: (value) => value == null ? 'اختار المادة' : null,
                    isExpanded: true,
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _sectionNumberController,
                          decoration: commonDecoration.copyWith(
                            labelText: 'الرقم',
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
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          items:
                              ['سكشن', 'عملي'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedType = newValue;
                              });
                            }
                          },
                          decoration: commonDecoration.copyWith(
                            labelText: 'النوع',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    'أيام الحضور',
                    style: TextStyle(
                      fontSize:
                          Responsive.text(context, size: TextSize.small) * 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,

                    child: Row(
                      children:
                          List<Widget>.generate(_dayNames.length, (int index) {
                            final isSelected = _selectedDays[index];
                            return Container(
                              margin: EdgeInsets.only(
                                left: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              child: FilterChip(
                                label: Text(
                                  _dayNames[index],
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedDays[index] = selected;
                                  });
                                },
                                selectedColor: Colors.teal.withAlpha(204),
                                backgroundColor: Colors.grey[200],
                                checkmarkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
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
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    'وقت السكشن',
                    style: TextStyle(
                      fontSize:
                          Responsive.text(context, size: TextSize.small) * 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),
                  InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: EdgeInsets.all(
                        Responsive.space(context, size: Space.small),
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Text(
                            _selectedTime != null
                                ? _formatTimeOfDay(_selectedTime!)
                                : 'اضغط لاختيار الوقت',
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                              fontWeight:
                                  _selectedTime != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  _selectedTime != null
                                      ? Colors.black87
                                      : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  TextFormField(
                    controller: _locationController,
                    decoration: commonDecoration.copyWith(
                      hintText: 'مثال: قاعة 3',
                      labelText: 'المكان',
                      alignLabelWithHint: true,
                    ),
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.right,

                    style: Theme.of(context).textTheme.bodyLarge,
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'يرجى إدخال المكان'
                                : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.medium),
              vertical: Responsive.space(context, size: Space.small),
            ),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          child: const Text('إلغاء'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton.icon(
          icon: Icon(
            _isEditing
                ? Icons.save_alt_rounded
                : Icons.add_circle_outline_rounded,
          ),
          label: Text(_isEditing ? 'حفظ التعديلات' : 'إضافة السكشن'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.large),
              vertical: Responsive.space(context, size: Space.small),
            ),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 2,
          ),
          onPressed: _submitForm,
        ),
      ],
    );
  }
}
