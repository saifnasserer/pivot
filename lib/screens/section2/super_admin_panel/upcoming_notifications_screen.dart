import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/scheduled_notification_provider.dart';
import 'package:pivot/models/scheduled_notification.dart';
import 'package:pivot/responsive.dart';
import 'package:intl/intl.dart';
import 'package:pivot/services/notification_trigger_service.dart';
import 'package:pivot/services/notification_service.dart';

class UpcomingNotificationsScreen extends StatefulWidget {
  // = 'upcoming_notifications_screen';

  const UpcomingNotificationsScreen({super.key});

  @override
  State<UpcomingNotificationsScreen> createState() =>
      _UpcomingNotificationsScreenState();
}

class _UpcomingNotificationsScreenState
    extends State<UpcomingNotificationsScreen> {
  String _selectedFilter = 'all';
  String _selectedStatus = 'all';
  bool _showOverdueOnly = false;

  final List<String> _filterOptions = [
    'all',
    'today',
    'tomorrow',
    'this_week',
    'next_week',
  ];

  final List<String> _statusOptions = [
    'all',
    'pending',
    'sent',
    'cancelled',
    'failed',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScheduledNotificationProvider>(
        context,
        listen: false,
      ).fetchScheduledNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'الإشعارات المجدولة',
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ScheduledNotificationProvider>(
                context,
                listen: false,
              ).fetchScheduledNotifications();
            },
          ),
          // Test button - remove in production
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Test Automatic Notifications',
            onPressed: () async {
              try {
                NotificationTriggerService().initializeAutomaticNotifications();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Automatic notifications initialized'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh the list
                  Provider.of<ScheduledNotificationProvider>(
                    context,
                    listen: false,
                  ).fetchScheduledNotifications();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          // Test notification button
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Send Test Notification',
            onPressed: () async {
              try {
                final notificationService = NotificationService();
                await notificationService.sendNotification(
                  targetToken: 'test_token',
                  title: 'إشعار تجريبي',
                  body: 'هذا إشعار تجريبي لاختبار النظام',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: Consumer<ScheduledNotificationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            color: Colors.red[700],
                          ),
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearError();
                            provider.fetchScheduledNotifications();
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredNotifications = _getFilteredNotifications(
                  provider,
                );

                if (filteredNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        Text(
                          'لا توجد إشعارات مجدولة',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchScheduledNotifications(),
                  child: ListView.builder(
                    padding: Responsive.padding(context, size: Space.medium),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return _buildNotificationCard(notification, provider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Time filter
          Row(
            children: [
              Text(
                'الوقت:',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _filterOptions.map((filter) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            child: FilterChip(
                              label: Text(_getFilterText(filter)),
                              selected: _selectedFilter == filter,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          // Status filter
          Row(
            children: [
              Text(
                'الحالة:',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _statusOptions.map((status) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            child: FilterChip(
                              label: Text(_getStatusText(status)),
                              selected: _selectedStatus == status,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStatus = status;
                                });
                              },
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          // Overdue toggle
          Row(
            children: [
              Checkbox(
                value: _showOverdueOnly,
                onChanged: (value) {
                  setState(() {
                    _showOverdueOnly = value ?? false;
                  });
                },
              ),
              Text(
                'إظهار المتأخر فقط',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    ScheduledNotification notification,
    ScheduledNotificationProvider provider,
  ) {
    return Card(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getStatusColor(notification.status), width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showNotificationDetails(notification, provider),
        child: Padding(
          padding: Responsive.padding(context, size: Space.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.small),
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        notification.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notification.statusText,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: _getStatusColor(notification.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  SizedBox(width: Responsive.space(context, size: Space.tiny)),
                  Text(
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(notification.scheduledTime),
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.grey[600],
                    ),
                  ),
                  Spacer(),
                  if (notification.isPending) ...[
                    Text(
                      notification.timeUntilScheduled,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color:
                            notification.isOverdue ? Colors.red : Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    notification.createdByName,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.grey[600],
                    ),
                  ),
                  Spacer(),
                  if (notification.sendToAllUsers)
                    Text(
                      'جميع المستخدمين',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      '${notification.targetUserIds.length} مستخدم',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              if (notification.isPending) ...[
                SizedBox(height: Responsive.space(context, size: Space.small)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _sendNow(notification, provider),
                      child: Text('إرسال الآن'),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    TextButton(
                      onPressed:
                          () => _cancelNotification(notification, provider),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text('إلغاء'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(
    ScheduledNotification notification,
    ScheduledNotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('تفاصيل الإشعار'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('العنوان', notification.title),
                  _buildDetailRow('المحتوى', notification.body),
                  _buildDetailRow(
                    'الوقت المجدول',
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(notification.scheduledTime),
                  ),
                  _buildDetailRow('الحالة', notification.statusText),
                  _buildDetailRow('أنشئ بواسطة', notification.createdByName),
                  _buildDetailRow(
                    'تاريخ الإنشاء',
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(notification.createdAt),
                  ),
                  _buildDetailRow(
                    'نوع الإرسال',
                    notification.sendToAllUsers
                        ? 'جميع المستخدمين'
                        : 'مستخدمين محددين',
                  ),
                  if (!notification.sendToAllUsers)
                    _buildDetailRow(
                      'عدد المستهدفين',
                      notification.targetUserIds.length.toString(),
                    ),
                  if (notification.sentCount != null)
                    _buildDetailRow(
                      'تم الإرسال',
                      '${notification.sentCount}/${notification.totalCount}',
                    ),
                  if (notification.errorMessage != null)
                    _buildDetailRow('رسالة الخطأ', notification.errorMessage!),
                  if (notification.sentAt != null)
                    _buildDetailRow(
                      'وقت الإرسال',
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(notification.sentAt!),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إغلاق'),
              ),
              if (notification.isPending) ...[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _sendNow(notification, provider);
                  },
                  child: Text('إرسال الآن'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _cancelNotification(notification, provider);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('إلغاء'),
                ),
              ],
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNow(
    ScheduledNotification notification,
    ScheduledNotificationProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('تأكيد الإرسال'),
            content: Text('هل تريد إرسال هذا الإشعار الآن؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('إرسال'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await provider.sendScheduledNotificationNow(notification);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم الإرسال بنجاح' : 'فشل في الإرسال'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelNotification(
    ScheduledNotification notification,
    ScheduledNotificationProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('تأكيد الإلغاء'),
            content: Text('هل تريد إلغاء هذا الإشعار؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('إلغاء الإشعار'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await provider.cancelScheduledNotification(
        notification.id!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم الإلغاء بنجاح' : 'فشل في الإلغاء'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  List<ScheduledNotification> _getFilteredNotifications(
    ScheduledNotificationProvider provider,
  ) {
    List<ScheduledNotification> notifications = provider.scheduledNotifications;

    // Apply status filter
    if (_selectedStatus != 'all') {
      notifications =
          notifications.where((n) => n.status == _selectedStatus).toList();
    }

    // Apply time filter
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'today':
        notifications =
            notifications.where((n) {
              final scheduledDate = DateTime(
                n.scheduledTime.year,
                n.scheduledTime.month,
                n.scheduledTime.day,
              );
              final today = DateTime(now.year, now.month, now.day);
              return scheduledDate.isAtSameMomentAs(today);
            }).toList();
        break;
      case 'tomorrow':
        notifications =
            notifications.where((n) {
              final scheduledDate = DateTime(
                n.scheduledTime.year,
                n.scheduledTime.month,
                n.scheduledTime.day,
              );
              final tomorrow = DateTime(now.year, now.month, now.day + 1);
              return scheduledDate.isAtSameMomentAs(tomorrow);
            }).toList();
        break;
      case 'this_week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        notifications =
            notifications.where((n) {
              return n.scheduledTime.isAfter(startOfWeek) &&
                  n.scheduledTime.isBefore(endOfWeek);
            }).toList();
        break;
      case 'next_week':
        final startOfNextWeek = now.add(Duration(days: 8 - now.weekday));
        final endOfNextWeek = startOfNextWeek.add(const Duration(days: 7));
        notifications =
            notifications.where((n) {
              return n.scheduledTime.isAfter(startOfNextWeek) &&
                  n.scheduledTime.isBefore(endOfNextWeek);
            }).toList();
        break;
    }

    // Apply overdue filter
    if (_showOverdueOnly) {
      notifications = notifications.where((n) => n.isOverdue).toList();
    }

    return notifications;
  }

  String _getFilterText(String filter) {
    switch (filter) {
      case 'all':
        return 'الكل';
      case 'today':
        return 'اليوم';
      case 'tomorrow':
        return 'غداً';
      case 'this_week':
        return 'هذا الأسبوع';
      case 'next_week':
        return 'الأسبوع القادم';
      default:
        return filter;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'all':
        return 'الكل';
      case 'pending':
        return 'في الانتظار';
      case 'sent':
        return 'تم الإرسال';
      case 'cancelled':
        return 'ملغي';
      case 'failed':
        return 'فشل';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'sent':
        return Colors.green;
      case 'cancelled':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
