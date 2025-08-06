import 'package:flutter/material.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:provider/provider.dart';

class AddEditScheduleDialog extends StatefulWidget {
  final String day;
  final ScheduleItem? itemToEdit; // Optional: for editing existing items

  const AddEditScheduleDialog({super.key, required this.day, this.itemToEdit});

  @override
  State<AddEditScheduleDialog> createState() => _AddEditScheduleDialogState();
}

class _AddEditScheduleDialogState extends State<AddEditScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _location = '';
  String _time = '';
  final _timeController = TextEditingController();
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
      _timeController.text = item.time;
      _selectedType = item.type;
      _notificationEnabled = item.notificationEnabled;
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
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
    if (_formKey.currentState!.validate()) {
      final scheduleProvider = Provider.of<ScheduleProvider>(
        context,
        listen: false,
      );

      if (_isEditing) {
        final updatedItem = widget.itemToEdit!.copyWith(
          title: _title,
          location: _location,
          time: _time,
          type: _selectedType,
          notificationEnabled: _notificationEnabled,
        );
        scheduleProvider.updateScheduleItem(updatedItem);
      } else {
        scheduleProvider.addScheduleItem(
          day: widget.day,
          title: _title,
          location: _location,
          time: _time,
          type: _selectedType,
          notificationEnabled: _notificationEnabled,
        );
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
        _time = picked.format(context);
        _timeController.text = _time;
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

              // Location
              UnifiedFormField(
                hint: 'المكان',
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

              // Time Selection
              UnifiedSectionHeader(title: 'الوقت', icon: Icons.access_time),

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
                        Icons.access_time,
                        color: Colors.black,
                        size: Responsive.space(context, size: Space.medium),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        child: Text(
                          _time.isEmpty ? 'اضغط لاختيار الوقت' : _time,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight:
                                _time.isNotEmpty
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                _time.isNotEmpty
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

              // Notification Toggle
              UnifiedSectionHeader(
                title: 'الإشعارات',
                icon: Icons.notifications,
              ),

              Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _notificationEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color:
                              _notificationEnabled
                                  ? Colors.black
                                  : Colors.grey[500],
                          size: Responsive.space(context, size: Space.medium),
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.small),
                        ),
                        Text(
                          'تفعيل الإشعارات',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
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
                      activeColor: Colors.black,
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
