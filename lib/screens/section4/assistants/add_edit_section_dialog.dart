import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For time formatting
// For TextDirection
import 'package:flutter/services.dart'; // For input formatters

import '../../models/section_info.dart';
import '../../../providers/section_provider.dart';

class AddEditSectionDialog extends StatefulWidget {
  final List<String> subjectNames; // Pass the list of subjects
  final String?
  initialSubjectName; // The subject this section belongs to (if adding/editing)
  final SectionInfo? sectionToEdit; // Optional section for editing

  const AddEditSectionDialog({
    super.key,
    required this.subjectNames,
    this.initialSubjectName,
    this.sectionToEdit,
  });

  @override
  State<AddEditSectionDialog> createState() => _AddEditSectionDialogState();
}

class _AddEditSectionDialogState extends State<AddEditSectionDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedSubjectName;
  String _selectedType = 'سكشن'; // Default type
  late TextEditingController _sectionNumberController;
  List<bool> _selectedDays = List.filled(6, false); // Sat -> Fri
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
    if (widget.initialSubjectName != null &&
        widget.subjectNames.contains(widget.initialSubjectName)) {
      _selectedSubjectName = widget.initialSubjectName;
    } else if (widget.subjectNames.isNotEmpty) {
      _selectedSubjectName =
          widget
              .subjectNames
              .first; // Default to first subject if initial is invalid or not provided (and list isn't empty)
    }

    if (_isEditing && widget.sectionToEdit != null) {
      final section = widget.sectionToEdit!;
      _parseAndSetTypeAndNumber(section.title);
      _parseAndSetDays(section.days);
      _selectedTime = _parseTimeString(section.time);
      _locationController.text = section.location;
    } else {
      _selectedTime = TimeOfDay.now(); // Default time for new sections
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
      _selectedType = 'سكشن'; // Keep default
      print(
        "Warning: Could not parse section title format: $title. Using default type and full title as number.",
      );
    }
  }

  void _parseAndSetDays(String daysString) {
    final normalizedDays = daysString
        .replaceAll(' و ', ',')
        .replaceAll('،', ',');
    final dayParts = normalizedDays
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty);

    for (String part in dayParts) {
      final index = _dayNames.indexOf(part);
      if (index != -1) {
        _selectedDays[index] = true;
      } else {
        print("Warning: Could not parse day part: $part");
      }
    }
    if (!_selectedDays.any((d) => d)) {
      print("Warning: Failed to parse any days from string: $daysString");
    }
  }

  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final timeMatchHHMM = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeString);
      if (timeMatchHHMM != null) {
        int hour = int.parse(timeMatchHHMM.group(1)!);
        int minute = int.parse(timeMatchHHMM.group(2)!);
        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          bool isPM = timeString.contains('مساءً');
          if (isPM && hour >= 1 && hour <= 12) {
            hour += 12; // Convert 12-hour PM to 24-hour
          }
          if (!isPM && hour == 12) hour = 0; // Handle 12 AM

          return TimeOfDay(hour: hour % 24, minute: minute);
        }
      }

      final timeMatchHourOnly = RegExp(r'\b(\d{1,2})\b').firstMatch(timeString);
      if (timeMatchHourOnly != null) {
        int hour = int.parse(timeMatchHourOnly.group(1)!);
        if (hour >= 0 && hour < 24) {
          bool isPM = timeString.contains('مساءً');
          if (isPM && hour >= 1 && hour <= 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;

          return TimeOfDay(hour: hour % 24, minute: 0); // Assume 0 minutes
        }
      }
    } catch (e) {
      print("Error parsing time string '$timeString': $e");
    }
    print("Warning: Could not parse time string: $timeString");
    return null; // Return null if parsing fails
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
    return selectedDayNames.isEmpty
        ? 'لم تحدد أيام'
        : selectedDayNames.join(' و ');
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    try {
      return DateFormat.jm('ar').format(dt); // Example: '٥:٣٠ م'
    } catch (_) {
      final String period =
          time.period == DayPeriod.am ? 'ص' : 'م'; // Abbreviated AM/PM
      final int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final String minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period'; // Example: 5:30 م
    }
  }

  void _submitForm() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      if (_selectedSubjectName == null) {
        _showValidationError('يرجى اختيار المادة ');
        return;
      }
      if (!_selectedDays.any((isSelected) => isSelected)) {
        _showValidationError(' اختار يوم واحد على الأقل');
        return;
      }
      if (_selectedTime == null) {
        _showValidationError(' اختار الوقت');
        return;
      }

      final sectionProvider = Provider.of<SectionProvider>(
        context,
        listen: false,
      );

      final String constructedTitle =
          '$_selectedType ${_sectionNumberController.text.trim()}';

      final String formattedDays = _formatSelectedDays();
      final String formattedTime = _formatTimeOfDay(_selectedTime!);

      final sectionsInSubject = sectionProvider.getSectionsForSubject(
        _selectedSubjectName!,
      );
      final potentialDuplicate = sectionsInSubject.any(
        (s) =>
            s.id ==
                constructedTitle && // Compare generated ID (which is the title)
            (!_isEditing ||
                s.id !=
                    widget
                        .sectionToEdit!
                        .id), // Allow saving if it's the same section being edited
      );

      if (potentialDuplicate) {
        _showValidationError(
          'سكشن بنفس الاسم "$constructedTitle" موجود بالفعل في هذه المادة.',
        );
        return;
      }

      final newSectionData = SectionInfo(
        title: constructedTitle,
        days: formattedDays,
        location: _locationController.text.trim(),
        time: formattedTime,
      );

      try {
        if (_isEditing) {
          String subjectToUpdateIn =
              widget.initialSubjectName ??
              _selectedSubjectName!; // Default to current selection if initial was null

          if (widget.initialSubjectName != null &&
              widget.initialSubjectName != _selectedSubjectName) {
            print(
              "Warning: Changing subject during edit might require different provider logic.",
            );
            subjectToUpdateIn = _selectedSubjectName!;
          }

          sectionProvider.updateSection(
            subjectToUpdateIn,
            widget.sectionToEdit!.id, // The original ID to find the section
            newSectionData, // The updated data
          );
        } else {
          sectionProvider.addSection(_selectedSubjectName!, newSectionData);
        }
        Navigator.of(context).pop(); // Close dialog on success
      } catch (error) {
        print('Error saving section: $error');
        _showValidationError('حدث خطأ أثناء حفظ السكشن: $error');
      }
    } else {
      _showValidationError('يرجى مراجعة البيانات المدخلة.');
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent, // Error color
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'اختر وقت السكشن', // Customize help text
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.teal, // Example color
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20); // Consistent border radius
    final inputPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 12.0,
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
      contentPadding: inputPadding,
      fillColor: Colors.grey.shade100, // Light background for fields
      filled: true,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    );
    final labelStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      title: Text(
        _isEditing ? 'تعديل بيانات السكشن' : 'إضافة سكشن جديد',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Stretch children
              children: <Widget>[
                // Text(
                //   'المادة الدراسية',
                //   style: labelStyle,
                //   textAlign: TextAlign.right,
                // ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedSubjectName,
                  items:
                      widget.subjectNames.isEmpty
                          ? [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                'مفيش مواد',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ]
                          : widget.subjectNames
                              .map(
                                (name) => DropdownMenuItem(
                                  value: name,
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                  onChanged:
                      widget.subjectNames.isEmpty
                          ? null
                          : (value) {
                            setState(() {
                              _selectedSubjectName = value;
                            });
                          },
                  decoration: commonDecoration.copyWith(
                    hintText: 'اختر المادة',
                  ),
                  validator: (value) => value == null ? 'اختار المادة' : null,
                  isExpanded: true,
                  style:
                      Theme.of(
                        context,
                      ).textTheme.bodyLarge, // Ensure text style is appropriate
                ),
                const SizedBox(height: 16),

                // Text(
                //   'نوع ورقم السكشن',
                //   style: labelStyle,
                //   textAlign: TextAlign.right,
                // ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3, // More space for number
                      child: TextFormField(
                        controller: _sectionNumberController,
                        decoration: commonDecoration.copyWith(
                          hintText: 'الرقم',
                          labelText: 'الرقم',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'أدخل الرقم';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      flex: 2, // Give less space to type selector
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        items:
                            ['سكشن', 'عملي']
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                        decoration: commonDecoration.copyWith(
                          labelText: 'النوع',
                        ), // Use labelText instead of hint for dropdowns?
                        isExpanded: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Text('الأيام:', style: labelStyle),
                const SizedBox(height: 8),
                Center(
                  // Center the toggle buttons row
                  child: ToggleButtons(
                    isSelected: _selectedDays,
                    onPressed: (int index) {
                      setState(() {
                        _selectedDays[index] = !_selectedDays[index];
                      });
                    },
                    borderRadius: BorderRadius.circular(
                      10,
                    ), // Slightly smaller radius for buttons?
                    borderWidth: 1.5,
                    borderColor: Colors.grey.shade400,
                    selectedBorderColor: Theme.of(context).primaryColor,
                    selectedColor: Colors.white, // Text color when selected
                    color: Colors.grey.shade700, // Text color when not selected
                    fillColor:
                        Theme.of(
                          context,
                        ).primaryColor, // Background when selected
                    constraints: BoxConstraints(
                      minWidth:
                          (MediaQuery.of(context).size.width * 0.8 - 16 * 6) /
                          6, // Approximate width calculation
                      minHeight: 40.0,
                    ),
                    children:
                        _dayNames
                            .map(
                              (day) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ), // Slightly smaller font
                              ),
                            )
                            .toList(),
                  ),
                ),
                if (!_selectedDays.any((d) => d)) // And no days are selected
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      left: 12.0,
                    ), // Position error message
                    child: Text(
                      ' اختار يوم واحد على الأقل',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Text('الوقت:', style: labelStyle),
                const SizedBox(height: 8),
                InkWell(
                  // Make the row clickable
                  onTap: _selectTime,
                  borderRadius: borderRadius,
                  child: InputDecorator(
                    // Wrap in InputDecorator for border/padding
                    decoration: commonDecoration.copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ), // Adjust padding
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTime != null
                              ? _formatTimeOfDay(_selectedTime!)
                              : 'اضغط لاختيار الوقت',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                _selectedTime != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                _selectedTime != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                          ),
                        ),
                        Icon(
                          Icons.access_time_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedTime == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                    child: Text(
                      'يرجى اختيار الوقت',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Text('المكان:', style: labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: commonDecoration.copyWith(
                    hintText: 'e.g., قاعة 3',
                    labelText: 'المكان',
                  ),
                  keyboardType: TextInputType.text,
                  textAlign: TextAlign.right,
                  // textDirection: TextDirection.rtl,
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
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actionsAlignment: MainAxisAlignment.spaceBetween, // Space out buttons
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Theme.of(context).primaryColor, // Use theme color
            foregroundColor:
                Theme.of(context).colorScheme.onPrimary, // Ensure contrast
            elevation: 2,
          ),
          onPressed: _submitForm,
        ),
      ],
    );
  }
}
