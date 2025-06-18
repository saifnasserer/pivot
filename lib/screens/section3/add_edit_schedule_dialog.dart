import 'package:flutter/material.dart';
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/schedule_item.dart';
// import 'package:pivot/utils/responsive.dart';
import 'package:provider/provider.dart';
import '../models/custom_text_field.dart'; // Corrected import path

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
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
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
        );
        print('TODO: Implement updateScheduleItem: $updatedItem');
      } else {
        scheduleProvider.addScheduleItem(
          day: widget.day,
          title: _title,
          location: _location,
          time: _time,
          type: _selectedType,
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.itemToEdit == null ? 'اضافة للجدول' : 'تعديل الجدول',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: Responsive.text(context, size: TextSize.heading),
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('سكشن'),
                  Radio<ScheduleItemType>(
                    value: ScheduleItemType.section,
                    groupValue: _selectedType,
                    onChanged: (ScheduleItemType? value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                  SizedBox(width: Responsive.space(context)),
                  Text('محاضرة'),
                  Radio<ScheduleItemType>(
                    value: ScheduleItemType.lecture,
                    groupValue: _selectedType,
                    onChanged: (ScheduleItemType? value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: Responsive.space(context)),

              CustomTextField(
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
              SizedBox(height: Responsive.space(context)),

              CustomTextField(
                hint: 'المكان ',
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
              SizedBox(height: Responsive.space(context)),

              TextFormField(
                controller: _timeController,
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'الوقت',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _time = picked.format(context);
                      _timeController.text = _time;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الوقت';
                  }
                  return null;
                },
              ),
              SizedBox(height: Responsive.space(context)),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('الغاء'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          onPressed: _submitForm,
          child: Text(
            widget.itemToEdit == null ? 'اضافة' : 'حفظ التعديل',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
