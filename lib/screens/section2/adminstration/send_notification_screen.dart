import 'package:flutter/material.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/providers/scheduled_notification_provider.dart';
import 'package:pivot/models/scheduled_notification.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pivot/screens/section2/super_admin_panel/upcoming_notifications_screen.dart';

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
  bool _isScheduled = false;
  DateTime _scheduledDateTime = DateTime.now().add(const Duration(hours: 1));
  final List<String> _selectedUserIds = [];
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

    if (_isScheduled && _scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون وقت الجدولة في المستقبل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isScheduled) {
        // Create scheduled notification
        await _createScheduledNotification();
      } else {
        // Send immediate notification
        await _sendImmediateNotification();
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

  Future<void> _createScheduledNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final userName = userDoc.data()?['name'] ?? 'مستخدم غير معروف';

    final scheduledNotification = ScheduledNotification(
      title: _titleController.text,
      body: _bodyController.text,
      scheduledTime: _scheduledDateTime,
      createdAt: DateTime.now(),
      createdBy: user.uid,
      createdByName: userName,
      targetUserIds: _sendToAllUsers ? [] : _selectedUserIds,
      sendToAllUsers: _sendToAllUsers,
      status: 'pending',
    );

    final provider = Provider.of<ScheduledNotificationProvider>(
      context,
      listen: false,
    );

    final success = await provider.createScheduledNotification(
      scheduledNotification,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم جدولة الإشعار بنجاح لـ ${DateFormat('dd/MM/yyyy HH:mm').format(_scheduledDateTime)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _selectedUserIds.clear();
        _isScheduled = false;
      });
    } else {
      throw Exception('فشل في جدولة الإشعار');
    }
  }

  Future<void> _sendImmediateNotification() async {
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
        content: Text('تم إرسال الإشعارات: $successCount/${tokens.length} نجح'),
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
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _getTimeUntilScheduled() {
    final now = DateTime.now();
    final difference = _scheduledDateTime.difference(now);

    if (difference.isNegative) {
      return 'وقت ماضي';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} يوم و ${difference.inHours % 24} ساعة';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة و ${difference.inMinutes % 60} دقيقة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: 'الإشعارات المجدولة',
            onPressed: () {
              Navigator.pushNamed(context, UpcomingNotificationsScreen.id);
            },
          ),
        ],
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
                          color: _sendToAllUsers ? Colors.black : Colors.white,
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
                          color: !_sendToAllUsers ? Colors.black : Colors.white,
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
                                            _selectedUserIds.remove(user['id']);
                                          } else {
                                            _selectedUserIds.add(user['id']);
                                          }
                                        });
                                      }
                                      : null,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
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
                SizedBox(height: Responsive.space(context, size: Space.large)),
              ],

              // Scheduling Section
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
                      'جدولة الإشعار',
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

                    // Schedule Toggle
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isScheduled = !_isScheduled;
                        });
                      },
                      child: Container(
                        padding: Responsive.padding(
                          context,
                          size: Space.medium,
                        ),
                        decoration: BoxDecoration(
                          color: _isScheduled ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _isScheduled ? Colors.blue : Colors.grey[300]!,
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
                                    _isScheduled
                                        ? Colors.white
                                        : Colors.transparent,
                                border: Border.all(
                                  color:
                                      _isScheduled
                                          ? Colors.white
                                          : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child:
                                  _isScheduled
                                      ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.blue,
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
                                    'جدولة الإشعار',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _isScheduled
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'إرسال الإشعار في وقت محدد',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ),
                                      color:
                                          _isScheduled
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

                    if (_isScheduled) ...[
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      Container(
                        padding: Responsive.padding(
                          context,
                          size: Space.medium,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'وقت الإرسال',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectDateTime(context),
                                    child: Container(
                                      padding: Responsive.padding(
                                        context,
                                        size: Space.medium,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                          SizedBox(
                                            width: Responsive.space(
                                              context,
                                              size: Space.small,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              DateFormat(
                                                'dd/MM/yyyy HH:mm',
                                              ).format(_scheduledDateTime),
                                              style: TextStyle(
                                                fontSize: Responsive.text(
                                                  context,
                                                  size: TextSize.medium,
                                                ),
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Text(
                              'سيتم إرسال الإشعار في: ${_getTimeUntilScheduled()}',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: Responsive.space(context, size: Space.large)),

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
                                _isScheduled
                                    ? 'جدولة الإشعار'
                                    : 'إرسال الإشعار',
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
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
