import 'package:flutter/material.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendNotificationScreen extends StatefulWidget {
  static const String id = 'send_notification_screen';

  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  bool _sendToAllUsers = true;
  List<String> _selectedUserIds = [];
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      setState(() {
        _users =
            querySnapshot.docs
                .map(
                  (doc) => {
                    'id': doc.id,
                    'name': doc.data()['name'] ?? 'Unknown',
                    'role': doc.data()['role'] ?? 'Student',
                    'department': doc.data()['department'] ?? '',
                    'fcmToken': doc.data()['fcmToken'],
                  },
                )
                .toList();
      });
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء العنوان والمحتوى'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> tokens = [];

      if (_sendToAllUsers) {
        // Send to all users with FCM tokens
        tokens = await _notificationService.getAllUserFCMTokens();
      } else {
        // Send to selected users
        tokens = await _notificationService.getMultipleUserFCMTokens(
          _selectedUserIds,
        );
      }

      if (tokens.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على رموز FCM صالحة'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Send notifications to all tokens
      int successCount = 0;
      for (String token in tokens) {
        final success = await _notificationService.sendNotification(
          targetToken: token,
          title: _titleController.text,
          body: _bodyController.text,
        );
        if (success) successCount++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال الإشعارات: $successCount/${tokens.length} نجح',
          ),
          backgroundColor: successCount > 0 ? Colors.green : Colors.red,
        ),
      );

      // Clear form on success
      if (successCount > 0) {
        _titleController.clear();
        _bodyController.clear();
        setState(() {
          _selectedUserIds.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إرسال الإشعارات: $e'),
          backgroundColor: Colors.red,
        ),
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
            'إرسال إشعارات',
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
                // Notification Type Selection
                Container(
                  width: double.infinity,
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
                        'نوع الإشعار',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Send to All Users Option
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _sendToAllUsers = true;
                            _selectedUserIds.clear();
                          });
                        },
                        child: Container(
                          padding: Responsive.padding(
                            context,
                            size: Space.medium,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _sendToAllUsers ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _sendToAllUsers
                                      ? Colors.black
                                      : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _sendToAllUsers
                                          ? Colors.white
                                          : Colors.transparent,
                                  border: Border.all(
                                    color:
                                        _sendToAllUsers
                                            ? Colors.white
                                            : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child:
                                    _sendToAllUsers
                                        ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.black,
                                        )
                                        : null,
                              ),
                              SizedBox(
                                width: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'إرسال لجميع المستخدمين',
                                      style: TextStyle(
                                        fontSize: Responsive.text(
                                          context,
                                          size: TextSize.medium,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _sendToAllUsers
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'إرسال الإشعار لجميع المستخدمين الذين لديهم رموز FCM',
                                      style: TextStyle(
                                        fontSize: Responsive.text(
                                          context,
                                          size: TextSize.small,
                                        ),
                                        color:
                                            _sendToAllUsers
                                                ? Colors.white70
                                                : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),

                      // Send to Selected Users Option
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _sendToAllUsers = false;
                          });
                        },
                        child: Container(
                          padding: Responsive.padding(
                            context,
                            size: Space.medium,
                          ),
                          decoration: BoxDecoration(
                            color:
                                !_sendToAllUsers ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  !_sendToAllUsers
                                      ? Colors.black
                                      : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      !_sendToAllUsers
                                          ? Colors.white
                                          : Colors.transparent,
                                  border: Border.all(
                                    color:
                                        !_sendToAllUsers
                                            ? Colors.white
                                            : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child:
                                    !_sendToAllUsers
                                        ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.black,
                                        )
                                        : null,
                              ),
                              SizedBox(
                                width: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'إرسال لمستخدمين محددين',
                                      style: TextStyle(
                                        fontSize: Responsive.text(
                                          context,
                                          size: TextSize.medium,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        color:
                                            !_sendToAllUsers
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'اختيار مستخدمين محددين للإشعار',
                                      style: TextStyle(
                                        fontSize: Responsive.text(
                                          context,
                                          size: TextSize.small,
                                        ),
                                        color:
                                            !_sendToAllUsers
                                                ? Colors.white70
                                                : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                // User Selection (if not sending to all)
                if (!_sendToAllUsers) ...[
                  Container(
                    width: double.infinity,
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
                          'اختيار المستخدمين',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.heading,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              final hasToken = user['fcmToken'] != null;
                              final isSelected = _selectedUserIds.contains(
                                user['id'],
                              );

                              return GestureDetector(
                                onTap:
                                    hasToken
                                        ? () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedUserIds.remove(
                                                user['id'],
                                              );
                                            } else {
                                              _selectedUserIds.add(user['id']);
                                            }
                                          });
                                        }
                                        : null,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: Responsive.padding(
                                    context,
                                    size: Space.medium,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Colors.black
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.black
                                              : Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                        ),
                                        child:
                                            isSelected
                                                ? const Icon(
                                                  Icons.check,
                                                  size: 10,
                                                  color: Colors.black,
                                                )
                                                : null,
                                      ),
                                      SizedBox(
                                        width: Responsive.space(
                                          context,
                                          size: Space.medium,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user['name'],
                                              style: TextStyle(
                                                fontSize: Responsive.text(
                                                  context,
                                                  size: TextSize.medium,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    isSelected
                                                        ? Colors.white
                                                        : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '${user['role']} - ${user['department']}',
                                              style: TextStyle(
                                                fontSize: Responsive.text(
                                                  context,
                                                  size: TextSize.small,
                                                ),
                                                color:
                                                    isSelected
                                                        ? Colors.white70
                                                        : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        hasToken
                                            ? Icons.notifications_active
                                            : Icons.notifications_off,
                                        color:
                                            hasToken
                                                ? (isSelected
                                                    ? Colors.white
                                                    : Colors.green)
                                                : Colors.grey,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.large),
                  ),
                ],

                // Notification Content
                Container(
                  width: double.infinity,
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
                        'محتوى الإشعار',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Title Field
                      CustomTextField(
                        controller: _titleController,
                        hint: 'أدخل عنوان الإشعار',
                        onChanged: (value) {
                          // Handle title change if needed
                        },
                      ),

                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Body Field
                      CustomTextField(
                        controller: _bodyController,
                        hint: 'أدخل رسالة الإشعار',
                        maxLines: 4,
                        onChanged: (value) {
                          // Handle body change if needed
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
                      onTap: _isLoading ? null : _sendNotification,
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
                                  'إرسال الإشعار',
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
