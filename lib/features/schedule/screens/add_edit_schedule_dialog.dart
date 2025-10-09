import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/schedule/providers/schedule_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class AddEditScheduleDialog extends ConsumerStatefulWidget {
  final String day;
  final ScheduleItem? itemToEdit; // Optional: for editing existing items

  const AddEditScheduleDialog({super.key, required this.day, this.itemToEdit});

  @override
  ConsumerState<AddEditScheduleDialog> createState() =>
      _AddEditScheduleDialogState();
}

class _AddEditScheduleDialogState extends ConsumerState<AddEditScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _location = '';
  String _time = '';
  String _instructor = '';
  final _timeController = TextEditingController();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _instructorController = TextEditingController();
  ScheduleItemType _selectedType = ScheduleItemType.lecture; // Default type
  bool _notificationEnabled = true; // Default to enabled

  bool get _isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _title = item.title;
      _location = item.location;
      _time = item.time;
      _instructor = item.instructor;
      _titleController.text = item.title;
      _locationController.text = item.location;
      _instructorController.text = item.instructor;

      // Convert stored time to display format
      final timeDisplay = _convertToDisplayTime(item.time);
      _timeController.text = timeDisplay;

      _selectedType = item.type;
      _notificationEnabled = item.notificationEnabled;
    }
  }

  // Helper method to convert stored time to display format
  String _convertToDisplayTime(String storedTime) {
    try {
      // If already in display format, return as is
      if (storedTime.contains('AM') || storedTime.contains('PM')) {
        return storedTime;
      }

      // Convert from HH:MM to display format
      if (storedTime.contains(':')) {
        final parts = storedTime.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          final timeOfDay = TimeOfDay(hour: hour, minute: minute);
          return timeOfDay.format(context);
        }
      }

      return storedTime; // Return as is if can't parse
    } catch (e) {
      return storedTime; // Return as is if error
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  Widget _buildTypeOption(
    BuildContext context,
    ScheduleItemType type,
    String title,
    IconData icon,
    Color backgroundColor,
  ) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
        decoration: BoxDecoration(
          color: isSelected ? backgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.small),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.small),
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: Responsive.text(context, size: TextSize.medium),
                color:
                    isSelected
                        ? (type == ScheduleItemType.lecture
                            ? Colors.blue.shade700
                            : Colors.orange.shade700)
                        : Colors.grey.shade600,
              ),
            ),
            SizedBox(width: Responsive.space(context, size: Space.medium)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color:
                    type == ScheduleItemType.lecture
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                size: Responsive.text(context, size: TextSize.medium),
              ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    // Validate time field
    if (_time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء اختيار الوقت'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_isEditing) {
        final updatedItem = widget.itemToEdit!.copyWith(
          title: _title,
          location: _location,
          time: _time,
          type: _selectedType,
          notificationEnabled: _notificationEnabled,
          instructor: _instructor,
        );
        ref
            .read(scheduleProvider.notifier)
            .updateScheduleItem(widget.itemToEdit!.id, updatedItem);
      } else {
        final newItem = ScheduleItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          day: widget.day,
          title: _title,
          location: _location,
          time: _time,
          type: _selectedType,
          notificationEnabled: _notificationEnabled,
          instructor: _instructor,
        );
        ref.read(scheduleProvider.notifier).addScheduleItem(newItem);
      }
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // Store time in HH:MM format for consistency
        _time =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _timeController.text = picked.format(
          context,
        ); // Display formatted time to user
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDialog(
      title: widget.itemToEdit == null ? 'اضافة للجدول' : 'تعديل الجدول',
      subtitle:
          widget.itemToEdit == null
              ? 'أدخل بيانات الجدول الجديد'
              : 'قم بتعديل بيانات الجدول',
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Type Selection
              UnifiedSectionHeader(title: 'نوع المادة', icon: Icons.category),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    _buildTypeOption(
                      context,
                      ScheduleItemType.lecture,
                      'محاضرة',
                      Icons.menu_book_rounded,
                      Colors.blue.shade100,
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                    ),
                    _buildTypeOption(
                      context,
                      ScheduleItemType.section,
                      'سكشن',
                      Icons.groups_rounded,
                      Colors.orange.shade100,
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Subject Name
              UnifiedFormField(
                hint: 'اسم المادة',
                controller: _titleController,
                onChanged: (value) {
                  setState(() {
                    _title = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'اكتب اسم المادة';
                  }
                  return null;
                },
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Instructor
              UnifiedFormField(
                hint: 'اسم الدكتور او المعيد',
                controller: _instructorController,
                onChanged: (value) {
                  setState(() {
                    _instructor = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم الدكتور او المعيد';
                  }
                  return null;
                },
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Location
              UnifiedFormField(
                hint: 'المكان',
                controller: _locationController,
                onChanged: (value) {
                  setState(() {
                    _location = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال المكان';
                  }
                  return null;
                },
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              InkWell(
                onTap: _selectTime,
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
                          Icons.access_time_rounded,
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
                              'الوقت',
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
                              _time.isEmpty
                                  ? 'اضغط لاختيار الوقت'
                                  : _timeController.text,
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                fontWeight:
                                    _time.isNotEmpty
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                color:
                                    _time.isNotEmpty
                                        ? Colors.black87
                                        : Colors.grey[600],
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

              Container(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.large),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _notificationEnabled
                          ? Colors.green.shade50
                          : Colors.grey.shade50,
                      _notificationEnabled
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color:
                        _notificationEnabled
                            ? Colors.green.shade200
                            : Colors.grey.shade200,
                  ),
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _notificationEnabled
                              ? Colors.green.shade100
                              : Colors.grey.shade100,
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
                            color:
                                _notificationEnabled
                                    ? Colors.green.shade100
                                    : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _notificationEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_rounded,
                            color:
                                _notificationEnabled
                                    ? Colors.green.shade700
                                    : Colors.grey.shade500,
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
                              'الإشعارات',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                color:
                                    _notificationEnabled
                                        ? Colors.green.shade600
                                        : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _notificationEnabled ? 'مفعلة' : 'معطلة',
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
                    Switch(
                      value: _notificationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationEnabled = value;
                        });
                      },
                      activeThumbColor: Colors.green.shade400,
                      activeTrackColor: Colors.white,
                      inactiveThumbColor: Colors.grey.shade300,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      confirmText: widget.itemToEdit == null ? 'اضافة' : 'حفظ التعديل',
      confirmIcon: widget.itemToEdit == null ? Icons.add : Icons.save,
      onConfirm: _submitForm,
    );
  }
}
