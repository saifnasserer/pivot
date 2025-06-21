import 'package:flutter/material.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:pivot/responsive.dart';

class NotificationDemoScreen extends StatefulWidget {
  static const String id = 'notification_demo_screen';

  const NotificationDemoScreen({super.key});

  @override
  State<NotificationDemoScreen> createState() => _NotificationDemoScreenState();
}

class _NotificationDemoScreenState extends State<NotificationDemoScreen> {
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  String _selectedIcon = 'ic_launcher';
  String _selectedColor = '#000000';
  String _selectedSound = 'default';
  bool _isLoading = false;

  final List<Map<String, String>> _iconOptions = [
    {'name': 'App Icon', 'value': 'ic_launcher'},
    {'name': 'Notification Icon', 'value': 'ic_notification'},
    {'name': 'Default', 'value': 'default'},
  ];

  final List<Map<String, String>> _colorOptions = [
    {'name': 'Black', 'value': '#000000'},
    {'name': 'Blue', 'value': '#2196F3'},
    {'name': 'Green', 'value': '#4CAF50'},
    {'name': 'Red', 'value': '#F44336'},
    {'name': 'Purple', 'value': '#9C27B0'},
  ];

  final List<Map<String, String>> _soundOptions = [
    {'name': 'Default', 'value': 'default'},
    {'name': 'Notification', 'value': 'notification'},
    {'name': 'Alert', 'value': 'alert'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Test Notification';
    _bodyController.text = 'This is a test notification with custom styling!';
  }

  Future<void> _sendTestNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title and body'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Show a local notification for instant testing
      await _notificationService.showLocalTestNotification(
        title: _titleController.text,
        body: _bodyController.text,
        payload: {'screen': 'demo_screen'},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local test notification created!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
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
          title: Text(
            'Notification Demo',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: Responsive.padding(context, size: Space.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Field
                Container(
                  padding: Responsive.padding(context, size: Space.large),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Title',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter notification title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                // Body Field
                Container(
                  padding: Responsive.padding(context, size: Space.large),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Body',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      TextField(
                        controller: _bodyController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter notification message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                // Customization Options
                Container(
                  padding: Responsive.padding(context, size: Space.large),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customization Options',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Icon Selection
                      Text(
                        'Icon',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedIcon,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items:
                            _iconOptions.map((option) {
                              return DropdownMenuItem(
                                value: option['value'],
                                child: Text(option['name']!),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedIcon = value!;
                          });
                        },
                      ),

                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Color Selection
                      Text(
                        'Color',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedColor,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items:
                            _colorOptions.map((option) {
                              return DropdownMenuItem(
                                value: option['value'],
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Color(
                                          int.parse(
                                            option['value']!.replaceAll(
                                              '#',
                                              '0xFF',
                                            ),
                                          ),
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(option['name']!),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedColor = value!;
                          });
                        },
                      ),

                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Sound Selection
                      Text(
                        'Sound',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedSound,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items:
                            _soundOptions.map((option) {
                              return DropdownMenuItem(
                                value: option['value'],
                                child: Text(option['name']!),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSound = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Responsive.space(context, size: Space.xlarge)),

                // Send Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLoading ? null : _sendTestNotification,
                      child: Center(
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  'Send Test Notification',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
