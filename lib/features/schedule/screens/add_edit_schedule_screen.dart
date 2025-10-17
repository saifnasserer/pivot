import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/schedule/providers/schedule_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/features/home/screens/adminstration/animated_route.dart';

class AddEditScheduleScreen extends ConsumerStatefulWidget {
  final String day;
  final ScheduleItem? itemToEdit; // Optional: for editing existing items

  const AddEditScheduleScreen({super.key, required this.day, this.itemToEdit});

  @override
  ConsumerState<AddEditScheduleScreen> createState() =>
      _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends ConsumerState<AddEditScheduleScreen>
    with TickerProviderStateMixin {
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
  bool _isSubmitting = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
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
    _timeController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _instructorController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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

  Future<void> _submitForm() async {
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
      setState(() => _isSubmitting = true);

      try {
        if (_isEditing) {
          final updatedItem = widget.itemToEdit!.copyWith(
            title: _title,
            location: _location,
            time: _time,
            type: _selectedType,
            notificationEnabled: _notificationEnabled,
            instructor: _instructor,
          );
          await ref
              .read(scheduleProvider.notifier)
              .updateScheduleItem(widget.itemToEdit!.id, updatedItem);

          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم تحديث العنصر بنجاح',
                  textAlign: TextAlign.center,
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
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
          await ref.read(scheduleProvider.notifier).addScheduleItem(newItem);

          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم إضافة العنصر بنجاح',
                  textAlign: TextAlign.center,
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        // Handle errors gracefully
        if (mounted) {
          Navigator.of(context).pop();

          // Check if it's a network/Firebase error
          final errorMessage = e.toString();
          final isNetworkError =
              errorMessage.contains('firebase') ||
              errorMessage.contains('network') ||
              errorMessage.contains('connection') ||
              errorMessage.contains('offline');

          if (isNetworkError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'لا يوجد اتصال بالإنترنت. سيتم حفظ التعديلات وإرسالها عند الاتصال.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'حسناً',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('حدث خطأ: $errorMessage'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.itemToEdit == null ? 'اضافة للجدول' : 'تعديل الجدول',
            style: TextStyle(
              color: Colors.black,
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _isSubmitting ? null : _submitForm,
              icon:
                  _isSubmitting
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                      : Icon(
                        widget.itemToEdit == null ? Icons.add : Icons.save,
                        color: Colors.black,
                      ),
              tooltip: widget.itemToEdit == null ? 'اضافة' : 'حفظ التعديل',
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Type Selection
            _buildSectionHeader('نوع المادة', Icons.category),

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
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
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
            _buildFormField(
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
            _buildFormField(
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
            _buildFormField(
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

            // Time Selection
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

            // Notification Toggle
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
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: Responsive.space(context, size: Space.medium),
          ),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: Responsive.text(context, size: TextSize.medium),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        contentPadding: EdgeInsets.all(
          Responsive.space(context, size: Space.large),
        ),
      ),
      style: TextStyle(
        fontSize: Responsive.text(context, size: TextSize.medium),
        color: Colors.black87,
      ),
    );
  }
}

Future<void> showAddEditScheduleScreen({
  required BuildContext context,
  required String day,
  ScheduleItem? itemToEdit,
}) async {
  await Navigator.of(context).push(
    AnimatedAddRoute(
      child: AddEditScheduleScreen(day: day, itemToEdit: itemToEdit),
      startPosition: Offset(0, 1),
    ),
  );
}
