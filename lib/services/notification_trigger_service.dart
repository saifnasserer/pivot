import 'package:flutter/material.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/scheduled_notification.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationTriggerService {
  static final NotificationTriggerService _instance =
      NotificationTriggerService._internal();
  factory NotificationTriggerService() => _instance;
  NotificationTriggerService._internal();

  final NotificationService _notificationService = NotificationService();

  // Rate limiting cache
  final Map<String, List<DateTime>> _userNotificationTimes = {};

  // Egypt timezone offset (UTC+2)
  static const int egyptTimeZoneOffset = 2;

  // Analytics data structure
  final Map<String, Map<String, int>> _notificationAnalytics = {
    'sent': {
      'task_reminder': 0,
      'class_reminder': 0,
      'announcement': 0,
      'department': 0,
      'level': 0,
      'welcome': 0,
      'unknown': 0,
    },
    'opened': {
      'task_reminder': 0,
      'class_reminder': 0,
      'announcement': 0,
      'department': 0,
      'level': 0,
      'welcome': 0,
      'unknown': 0,
    },
    'failed': {
      'task_reminder': 0,
      'class_reminder': 0,
      'announcement': 0,
      'department': 0,
      'level': 0,
      'welcome': 0,
      'unknown': 0,
    },
  };

  // Batch notification queue
  final Map<String, List<ScheduledNotification>> _batchQueue = {};
  static const int _batchSize = 10;
  static const Duration _batchInterval = Duration(minutes: 5);

  // Maximum retry attempts
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(minutes: 5);

  // Check rate limit for a user
  bool _checkRateLimit(String userId, UserProfile userProfile) {
    final now = DateTime.now();
    final hourAgo = now.subtract(const Duration(hours: 1));

    // Initialize or clean old notifications
    _userNotificationTimes[userId] =
        _userNotificationTimes[userId]
            ?.where((time) => time.isAfter(hourAgo))
            .toList() ??
        [];

    // Check against user's preferences
    final maxPerHour =
        userProfile.notificationPreferences.maxNotificationsPerHour;
    if (_userNotificationTimes[userId]!.length >= maxPerHour) {
      return false;
    }

    _userNotificationTimes[userId]!.add(now);
    return true;
  }

  // Add notification to batch queue
  void _addToBatchQueue(ScheduledNotification notification) {
    final userId = notification.targetUserIds.first;
    _batchQueue[userId] = _batchQueue[userId] ?? [];
    _batchQueue[userId]!.add(notification);

    // Process batch if size threshold reached
    if (_batchQueue[userId]!.length >= _batchSize) {
      _processBatch(userId);
    }
  }

  // Process batch of notifications
  Future<void> _processBatch(String userId) async {
    if (_batchQueue[userId] == null || _batchQueue[userId]!.isEmpty) return;

    final batch = _batchQueue[userId]!;
    _batchQueue[userId] = [];

    try {
      final token = await _notificationService.getUserFCMToken(userId);
      if (token != null) {
        // Combine similar notifications
        final combinedNotifications = _combineSimilarNotifications(batch);

        for (var notification in combinedNotifications) {
          await _sendWithRetry(notification, token, userId);
        }
      }
    } catch (e) {
      print('Error processing batch for user $userId: $e');
    }
  }

  // Combine similar notifications
  List<ScheduledNotification> _combineSimilarNotifications(
    List<ScheduledNotification> notifications,
  ) {
    final Map<String, List<ScheduledNotification>> groupedByType = {};

    for (var notification in notifications) {
      final type = notification.additionalData?['type'] as String? ?? 'unknown';
      groupedByType[type] = groupedByType[type] ?? [];
      groupedByType[type]!.add(notification);
    }

    final List<ScheduledNotification> combined = [];

    groupedByType.forEach((type, typeNotifications) {
      if (typeNotifications.length == 1) {
        combined.add(typeNotifications.first);
      } else {
        // Combine similar notifications
        combined.add(
          ScheduledNotification(
            title: 'Multiple ${type.replaceAll('_', ' ')} Notifications',
            body:
                'You have ${typeNotifications.length} ${type.replaceAll('_', ' ')} notifications',
            scheduledTime: typeNotifications.first.scheduledTime,
            createdAt: DateTime.now(),
            createdBy: 'system',
            createdByName: 'النظام التلقائي',
            targetUserIds: typeNotifications.first.targetUserIds,
            sendToAllUsers: false,
            status: 'pending',
            additionalData: {
              'type': type,
              'count': typeNotifications.length,
              'combined': true,
            },
          ),
        );
      }
    });

    return combined;
  }

  // Send notification with retry mechanism
  Future<bool> _sendWithRetry(
    ScheduledNotification notification,
    String token,
    String userId, {
    int attempt = 1,
  }) async {
    try {
      final success = await _notificationService.sendNotification(
        targetToken: token,
        userId: userId,
        title: notification.title,
        body: notification.body,
      );

      if (success) {
        _updateAnalytics(
          'sent',
          notification.additionalData?['type'] ?? 'unknown',
        );
        return true;
      }

      if (attempt < _maxRetryAttempts) {
        await Future.delayed(_retryDelay * attempt);
        return _sendWithRetry(
          notification,
          token,
          userId,
          attempt: attempt + 1,
        );
      }

      _updateAnalytics(
        'failed',
        notification.additionalData?['type'] ?? 'unknown',
      );
      return false;
    } catch (e) {
      print('Error sending notification (attempt $attempt): $e');
      if (attempt < _maxRetryAttempts) {
        await Future.delayed(_retryDelay * attempt);
        return _sendWithRetry(
          notification,
          token,
          userId,
          attempt: attempt + 1,
        );
      }
      _updateAnalytics(
        'failed',
        notification.additionalData?['type'] ?? 'unknown',
      );
      return false;
    }
  }

  // Update analytics
  void _updateAnalytics(String metric, String type) {
    _notificationAnalytics[metric]![type] =
        (_notificationAnalytics[metric]![type] ?? 0) + 1;
  }

  // Get analytics data
  Map<String, Map<String, int>> getAnalytics() {
    return Map.from(_notificationAnalytics);
  }

  // Record notification opened
  Future<void> recordNotificationOpened(String type) async {
    _updateAnalytics('opened', type);
  }

  // Convert to Egypt time
  DateTime _toEgyptTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return utc.add(const Duration(hours: egyptTimeZoneOffset));
  }

  // Override the existing sendScheduledNotification method
  @override
  Future<void> sendScheduledNotification(
    ScheduledNotification notification,
  ) async {
    try {
      if (notification.sendToAllUsers) {
        final tokens = await _notificationService.getAllUserFCMTokens();
        for (final token in tokens) {
          await _sendWithRetry(notification, token, 'all_users');
        }
      } else {
        for (final userId in notification.targetUserIds) {
          // Get user profile to check preferences
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get();

          if (!userDoc.exists) continue;

          final userProfile = UserProfile.fromJson(userDoc.data()!);

          // Check user preferences
          final type =
              notification.additionalData?['type'] as String? ?? 'unknown';
          if (!_shouldSendNotification(
            type,
            userProfile.notificationPreferences,
          )) {
            continue;
          }

          // Check rate limit
          if (!_checkRateLimit(userId, userProfile)) {
            print('Rate limit reached for user $userId');
            continue;
          }

          // Add to batch queue
          _addToBatchQueue(notification);
        }
      }
    } catch (e) {
      print('Error sending scheduled notification: $e');
      await _updateNotificationStatus(
        notification.id!,
        'failed',
        errorMessage: e.toString(),
      );
    }
  }

  // Helper to check if notification should be sent based on user preferences
  bool _shouldSendNotification(String type, NotificationPreferences prefs) {
    switch (type) {
      case 'task_reminder':
        return prefs.taskReminders;
      case 'class_reminder':
        return prefs.classReminders;
      case 'announcement':
        return prefs.announcements;
      case 'department':
        return prefs.departmentNotifications;
      case 'level':
        return prefs.levelNotifications;
      case 'welcome':
        return prefs.welcomeNotification;
      default:
        return true;
    }
  }

  // Update notification status in Firestore
  Future<void> _updateNotificationStatus(
    String notificationId,
    String status, {
    String? errorMessage,
  }) async {
    await FirebaseFirestore.instance
        .collection('scheduledNotifications')
        .doc(notificationId)
        .update({
          'status': status,
          'errorMessage': errorMessage,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // Process batch queue periodically
  Future<void> processBatchQueue() async {
    _batchQueue.keys.toList().forEach(_processBatch);
  }

  // Start periodic batch processing
  void startBatchProcessing() {
    Future.doWhile(() async {
      await processBatchQueue();
      await Future.delayed(_batchInterval);
      return true;
    });
  }

  // Send task reminder notifications for tasks due today
  Future<void> sendTaskReminders() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get tasks due today or overdue
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('dueDate', isLessThanOrEqualTo: today)
              .where('completed', isEqualTo: false)
              .get();

      for (var doc in querySnapshot.docs) {
        final taskData = doc.data();
        final userId = taskData['userId'] as String?;
        final taskName = taskData['title'] as String?;
        final dueDate = taskData['dueDate'] as Timestamp?;

        if (userId != null && taskName != null) {
          final token = await _notificationService.getUserFCMToken(userId);
          if (token != null) {
            final isOverdue =
                dueDate != null && dueDate.toDate().isBefore(today);

            await _notificationService.sendNotification(
              targetToken: token,
              userId: userId,
              title: isOverdue ? 'Task Overdue!' : 'Task Due Today',
              body:
                  'Your task "$taskName" is ${isOverdue ? 'overdue' : 'due today'}.',
            );
          }
        }
      }
    } catch (e) {
      print('Error sending task reminders: $e');
    }
  }

  // Send immediate notification for newly added task
  Future<void> sendNewTaskNotification(
    String userId,
    String taskName,
    DateTime dueDate,
  ) async {
    try {
      print('FCM Task: Sending new task notification for user: $userId');
      print('FCM Task: Task: $taskName, Due: $dueDate');

      final token = await _notificationService.getUserFCMToken(userId);
      if (token != null) {
        print('FCM Task: Found token for user: ${token.substring(0, 20)}...');

        // Format due date for display
        final now = DateTime.now();
        final daysUntilDue = dueDate.difference(now).inDays;

        String dueText;
        if (daysUntilDue == 0) {
          dueText = 'اليوم';
        } else if (daysUntilDue == 1) {
          dueText = 'غداً';
        } else if (daysUntilDue > 1) {
          dueText = 'خلال $daysUntilDue أيام';
        } else {
          dueText = 'متأخر';
        }

        print('FCM Task: Sending notification with title: تاسك جديد تم إضافته');
        print('FCM Task: Body: تم إضافة التاسك "$taskName" - مطلوب $dueText');

        final success = await _notificationService.sendNotification(
          targetToken: token,
          userId: userId,
          title: 'تاسك جديد تم إضافته',
          body: 'تم إضافة التاسك "$taskName"',
          data: {
            'type': 'new_task',
            'taskName': taskName,
            'dueDate': dueDate.toIso8601String(),
          },
        );

        if (success) {
          print('FCM Task: ✅ New task notification sent successfully');
        } else {
          print('FCM Task: ❌ Failed to send new task notification');
        }
      } else {
        print('FCM Task: ❌ No FCM token found for user: $userId');
      }
    } catch (e) {
      print('FCM Task: ❌ Error sending new task notification: $e');
    }
  }

  // Send announcement notifications
  Future<void> sendAnnouncement(
    String title,
    String body, {
    List<String>? targetUserIds,
  }) async {
    try {
      if (targetUserIds != null && targetUserIds.isNotEmpty) {
        for (String userId in targetUserIds) {
          final token = await _notificationService.getUserFCMToken(userId);
          if (token != null) {
            await _notificationService.sendNotification(
              targetToken: token,
              userId: userId,
              title: title,
              body: body,
            );
          }
        }
      } else {
        // This case needs re-evaluation. Sending to all users means we don't have individual IDs to store notifications.
        // For now, let's assume announcements are not stored in individual user histories if sent to all.
        final tokens = await _notificationService.getAllUserFCMTokens();
        for (String token in tokens) {
          await _notificationService.sendNotification(
            targetToken: token,
            title: title,
            body: body,
          );
        }
      }
    } catch (e) {
      print('Error sending announcement: $e');
    }
  }

  // Send welcome notification to new users
  Future<void> sendWelcomeNotification(String userId, String userName) async {
    try {
      final token = await _notificationService.getUserFCMToken(userId);
      if (token != null) {
        await _notificationService.sendNotification(
          targetToken: token,
          userId: userId,
          title: 'Welcome to Pivot!',
          body: 'Hello $userName! Welcome to your organized university life.',
        );
      }
    } catch (e) {
      print('Error sending welcome notification: $e');
    }
  }

  // Send schedule reminder notifications
  Future<void> sendScheduleReminders() async {
    try {
      final now = DateTime.now();
      final currentTime = TimeOfDay.fromDateTime(now);

      // Get schedules for today
      final today = DateTime(now.year, now.month, now.day);
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('schedules')
              .where('date', isEqualTo: today)
              .get();

      for (var doc in querySnapshot.docs) {
        final scheduleData = doc.data();
        final userId = scheduleData['userId'] as String?;
        final subjectName = scheduleData['subjectName'] as String?;
        final startTime = scheduleData['startTime'] as String?;
        final endTime = scheduleData['endTime'] as String?;

        if (userId != null && subjectName != null && startTime != null) {
          // Parse start time and check if it's within 15 minutes
          final startTimeParts = startTime.split(':');
          final startHour = int.parse(startTimeParts[0]);
          final startMinute = int.parse(startTimeParts[1]);
          final scheduleStartTime = TimeOfDay(
            hour: startHour,
            minute: startMinute,
          );

          final difference = _getTimeDifference(currentTime, scheduleStartTime);

          if (difference.inMinutes <= 15 && difference.inMinutes >= 0) {
            final token = await _notificationService.getUserFCMToken(userId);
            if (token != null) {
              await _notificationService.sendNotification(
                targetToken: token,
                userId: userId,
                title: 'Upcoming Class',
                body:
                    'You have $subjectName starting in ${difference.inMinutes} minutes.',
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error sending schedule reminders: $e');
    }
  }

  // Send notification when new content is added
  Future<void> notifyNewContent(
    String contentType,
    String contentName, {
    List<String>? targetUserIds,
  }) async {
    try {
      List<String> tokens = [];

      if (targetUserIds != null) {
        tokens = await _notificationService.getMultipleUserFCMTokens(
          targetUserIds,
        );
      } else {
        tokens = await _notificationService.getAllUserFCMTokens();
      }

      for (String token in tokens) {
        await _notificationService.sendNotification(
          targetToken: token,
          title: 'New $contentType Available',
          body: '$contentName has been added to your $contentType.',
        );
      }
    } catch (e) {
      print('Error sending new content notification: $e');
    }
  }

  // Helper method to calculate time difference
  Duration _getTimeDifference(TimeOfDay time1, TimeOfDay time2) {
    final minutes1 = time1.hour * 60 + time1.minute;
    final minutes2 = time2.hour * 60 + time2.minute;
    return Duration(minutes: minutes2 - minutes1);
  }

  // Send notification to users in specific department
  Future<void> sendDepartmentNotification(
    String department,
    String title,
    String body,
  ) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('department', isEqualTo: department)
              .get();

      final userIds = querySnapshot.docs.map((doc) => doc.id).toList();
      final tokens = await _notificationService.getMultipleUserFCMTokens(
        userIds,
      );

      for (String token in tokens) {
        await _notificationService.sendNotification(
          targetToken: token,
          userId: userIds[tokens.indexOf(token)],
          title: title,
          body: body,
        );
      }
    } catch (e) {
      print('Error sending department notification: $e');
    }
  }

  // Send notification to users in specific level
  Future<void> sendLevelNotification(
    String level,
    String title,
    String body,
  ) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('level', isEqualTo: level)
              .get();

      final userIds = querySnapshot.docs.map((doc) => doc.id).toList();
      final tokens = await _notificationService.getMultipleUserFCMTokens(
        userIds,
      );

      for (String token in tokens) {
        await _notificationService.sendNotification(
          targetToken: token,
          userId: userIds[tokens.indexOf(token)],
          title: title,
          body: body,
        );
      }
    } catch (e) {
      print('Error sending level notification: $e');
    }
  }

  // ===== AUTO NOTIFICATION METHODS =====

  // 1. 15 minutes before class
  Future<void> sendClassReminders() async {
    try {
      final now = DateTime.now();
      final currentTime = TimeOfDay.fromDateTime(now);
      final today = DateTime(now.year, now.month, now.day);

      // Get today's schedules
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('schedules')
              .where('date', isEqualTo: today)
              .get();

      for (var doc in querySnapshot.docs) {
        final scheduleData = doc.data();
        final userId = scheduleData['userId'] as String?;
        final subjectName = scheduleData['subjectName'] as String?;
        final startTime = scheduleData['startTime'] as String?;

        if (userId != null && subjectName != null && startTime != null) {
          // Parse start time
          final startTimeParts = startTime.split(':');
          final startHour = int.parse(startTimeParts[0]);
          final startMinute = int.parse(startTimeParts[1]);
          final scheduleStartTime = TimeOfDay(
            hour: startHour,
            minute: startMinute,
          );

          final difference = _getTimeDifference(currentTime, scheduleStartTime);

          // Send notification 15 minutes before class
          if (difference.inMinutes == 15) {
            final token = await _notificationService.getUserFCMToken(userId);
            if (token != null) {
              await _notificationService.sendNotification(
                targetToken: token,
                userId: userId,
                title: 'محاضرة قريبة',
                body: 'محاضرة $subjectName تبدأ خلال 15 دقيقة',
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error sending class reminders: $e');
    }
  }

  // Schedule automatic class reminder notifications
  Future<void> scheduleClassReminderNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // Not logged in
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get all schedules for today and future dates for the current user
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('schedule')
              .where('date', isGreaterThanOrEqualTo: today)
              .get();

      for (var doc in querySnapshot.docs) {
        final scheduleData = doc.data();
        final userId = scheduleData['userId'] as String?;
        final subjectName = scheduleData['subjectName'] as String?;
        final startTime = scheduleData['startTime'] as String?;
        final date = scheduleData['date'] as Timestamp?;

        if (userId != null &&
            subjectName != null &&
            startTime != null &&
            date != null) {
          // Parse start time
          final startTimeParts = startTime.split(':');
          final startHour = int.parse(startTimeParts[0]);
          final startMinute = int.parse(startTimeParts[1]);

          // Calculate scheduled notification time (15 minutes before class)
          final classDateTime = DateTime(
            date.toDate().year,
            date.toDate().month,
            date.toDate().day,
            startHour,
            startMinute,
          );

          final reminderTime = classDateTime.subtract(
            const Duration(minutes: 15),
          );

          // Only schedule if the reminder time is in the future
          if (reminderTime.isAfter(now)) {
            await scheduleClassReminder(
              userId: userId,
              subjectName: subjectName,
              classDateTime: classDateTime,
              reminderTime: reminderTime,
            );
          }
        }
      }
    } catch (e) {
      print('Error scheduling class reminder notifications: $e');
    }
  }

  // Schedule a single class reminder notification
  Future<void> scheduleClassReminder({
    required String userId,
    required String subjectName,
    required DateTime classDateTime,
    required DateTime reminderTime,
  }) async {
    try {
      // Check if notification already exists
      final existingQuery =
          await FirebaseFirestore.instance
              .collection('scheduledNotifications')
              .where('createdBy', isEqualTo: 'system')
              .where('targetUserIds', arrayContains: userId)
              .where(
                'scheduledTime',
                isEqualTo: Timestamp.fromDate(reminderTime),
              )
              .where('title', isEqualTo: 'محاضرة قريبة')
              .get();

      if (existingQuery.docs.isNotEmpty) {
        // Notification already scheduled
        return;
      }

      // Create scheduled notification
      final scheduledNotification = ScheduledNotification(
        title: 'محاضرة قريبة',
        body: 'محاضرة $subjectName تبدأ خلال 15 دقيقة',
        scheduledTime: reminderTime,
        createdAt: DateTime.now(),
        createdBy: 'system',
        createdByName: 'النظام التلقائي',
        targetUserIds: [userId],
        sendToAllUsers: false,
        status: 'pending',
        additionalData: {
          'type': 'class_reminder',
          'classDateTime': Timestamp.fromDate(classDateTime),
          'subjectName': subjectName,
        },
      );

      await FirebaseFirestore.instance
          .collection('scheduledNotifications')
          .add(scheduledNotification.toJson());

      print(
        'Scheduled class reminder for $subjectName at ${reminderTime.toString()}',
      );
    } catch (e) {
      print('Error scheduling class reminder: $e');
    }
  }

  // Schedule task reminder notifications
  Future<void> scheduleTaskReminderNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // Not logged in
      final now = DateTime.now();

      // Get all incomplete tasks for the current user
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('tasks')
              .where('completed', isEqualTo: false)
              .get();

      for (var doc in querySnapshot.docs) {
        final taskData = doc.data();
        final userId = taskData['userId'] as String?;
        final taskName = taskData['title'] as String?;
        final dueDate = taskData['dueDate'] as Timestamp?;

        if (userId != null && taskName != null && dueDate != null) {
          final dueDateTime = dueDate.toDate();

          // Schedule different types of reminders
          await _scheduleTaskReminders(
            userId: userId,
            taskName: taskName,
            dueDateTime: dueDateTime,
          );
        }
      }
    } catch (e) {
      print('Error scheduling task reminder notifications: $e');
    }
  }

  // Schedule task reminders
  Future<void> _scheduleTaskReminders({
    required String userId,
    required String taskName,
    required DateTime dueDateTime,
  }) async {
    try {
      final now = DateTime.now();

      // 3 days before due date
      final threeDaysBefore = DateTime(
        dueDateTime.year,
        dueDateTime.month,
        dueDateTime.day - 3,
        9, // 9 AM
        0,
      );

      if (threeDaysBefore.isAfter(now)) {
        await _scheduleTaskReminder(
          userId: userId,
          taskName: taskName,
          scheduledTime: threeDaysBefore,
          title: 'تذكير مبكر',
          body: 'التاسك "$taskName" محتاج يتسلم في خلال 3 ايام',
          type: 'early_reminder',
        );
      }

      // Day of due date
      final dueDay = DateTime(
        dueDateTime.year,
        dueDateTime.month,
        dueDateTime.day,
        8, // 8 AM
        0,
      );

      if (dueDay.isAfter(now)) {
        await _scheduleTaskReminder(
          userId: userId,
          taskName: taskName,
          scheduledTime: dueDay,
          title: 'تاسك اليوم',
          body: 'التاسك "$taskName" لازم يتسلم النهاردة',
          type: 'due_today',
        );
      }

      // Overdue reminders (every day after due date)
      if (dueDateTime.isBefore(now)) {
        final daysOverdue = now.difference(dueDateTime).inDays;
        final overdueReminder = DateTime(
          now.year,
          now.month,
          now.day + 1, // Tomorrow
          10, // 10 AM
          0,
        );

        await _scheduleTaskReminder(
          userId: userId,
          taskName: taskName,
          scheduledTime: overdueReminder,
          title: 'تاسك متأخر!',
          body: 'التاسك "$taskName" متأخر $daysOverdue يوم',
          type: 'overdue',
        );
      }
    } catch (e) {
      print('Error scheduling task reminders: $e');
    }
  }

  // Schedule a single task reminder
  Future<void> _scheduleTaskReminder({
    required String userId,
    required String taskName,
    required DateTime scheduledTime,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      // Check if notification already exists
      final existingQuery =
          await FirebaseFirestore.instance
              .collection('scheduledNotifications')
              .where('createdBy', isEqualTo: 'system')
              .where('targetUserIds', arrayContains: userId)
              .where(
                'scheduledTime',
                isEqualTo: Timestamp.fromDate(scheduledTime),
              )
              .where('title', isEqualTo: title)
              .get();

      if (existingQuery.docs.isNotEmpty) {
        // Notification already scheduled
        return;
      }

      // Create scheduled notification
      final scheduledNotification = ScheduledNotification(
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        createdAt: DateTime.now(),
        createdBy: 'system',
        createdByName: 'النظام التلقائي',
        targetUserIds: [userId],
        sendToAllUsers: false,
        status: 'pending',
        additionalData: {
          'type': 'task_reminder',
          'taskName': taskName,
          'reminderType': type,
        },
      );

      await FirebaseFirestore.instance
          .collection('scheduledNotifications')
          .add(scheduledNotification.toJson());

      print(
        'Scheduled task reminder: $title for $taskName at ${scheduledTime.toString()}',
      );
    } catch (e) {
      print('Error scheduling task reminder: $e');
    }
  }

  // Schedule welcome notifications for new users
  Future<void> scheduleWelcomeNotification(
    String userId,
    String userName,
  ) async {
    try {
      final welcomeTime = DateTime.now().add(
        const Duration(minutes: 5),
      ); // 5 minutes from now

      final scheduledNotification = ScheduledNotification(
        title: 'Welcome to Pivot!',
        body: 'Hello $userName! Welcome to your organized university life.',
        scheduledTime: welcomeTime,
        createdAt: DateTime.now(),
        createdBy: 'system',
        createdByName: 'النظام التلقائي',
        targetUserIds: [userId],
        sendToAllUsers: false,
        status: 'pending',
        additionalData: {'type': 'welcome', 'userName': userName},
      );

      await FirebaseFirestore.instance
          .collection('scheduledNotifications')
          .add(scheduledNotification.toJson());

      // print('Scheduled welcome notification for $userName');
    } catch (e) {
      // print('Error scheduling welcome notification: $e');
    }
  }

  // Initialize all automatic notifications
  void initializeAutomaticNotifications() {
    // print('Initializing automatic notifications...');
    scheduleClassReminderNotifications().catchError((e) {
      // print('Error scheduling class reminder notifications: $e');
    });
    scheduleTaskReminderNotifications().catchError((e) {
      // print('Error scheduling task reminder notifications: $e');
    });
    // print('Automatic notifications initialization started in background');
  }

  // Clean up old scheduled notifications
  Future<void> cleanupOldNotifications() async {
    try {
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('scheduledNotifications')
              .where(
                'scheduledTime',
                isLessThan: Timestamp.fromDate(oneMonthAgo),
              )
              .where('status', whereIn: ['sent', 'cancelled', 'failed'])
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      // print('Cleaned up ${querySnapshot.docs.length} old notifications');
    } catch (e) {
      // print('Error cleaning up old notifications: $e');
    }
  }

  // Periodic notification check (call this every 15 minutes)
  Future<void> checkAndSendPeriodicNotifications() async {
    try {
      final now = DateTime.now();
      final currentMinute = now.minute;

      // Only run class reminders every 15 minutes (at :00, :15, :30, :45)
      if (currentMinute % 15 == 0) {
        await sendClassReminders();
      }

      // Run task notifications every hour (at :00)
      if (currentMinute == 0) {
        await sendTaskReminders();
      }
    } catch (e) {
      // print('Error in periodic notification check: $e');
    }
  }

  // Process scheduled notifications (called by background service)
  Future<void> processScheduledNotifications() async {
    try {
      final now = DateTime.now();

      // Get pending scheduled notifications that are due
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('scheduledNotifications')
              .where('status', isEqualTo: 'pending')
              .where('scheduledTime', isLessThanOrEqualTo: now)
              .get();

      for (var doc in querySnapshot.docs) {
        final notificationData = doc.data();
        final notification = ScheduledNotification.fromJson({
          'id': doc.id,
          ...notificationData,
        });

        // Send the notification
        await sendScheduledNotification(notification);
      }
    } catch (e) {
      // print('Error processing scheduled notifications: $e');
    }
  }

  // Handle schedule changes and automatically schedule notifications
  Future<void> handleScheduleCreated(Map<String, dynamic> scheduleData) async {
    try {
      final userId = scheduleData['userId'] as String?;
      final subjectName = scheduleData['subjectName'] as String?;
      final startTime = scheduleData['startTime'] as String?;
      final date = scheduleData['date'] as Timestamp?;

      if (userId != null &&
          subjectName != null &&
          startTime != null &&
          date != null) {
        // Parse start time
        final startTimeParts = startTime.split(':');
        final startHour = int.parse(startTimeParts[0]);
        final startMinute = int.parse(startTimeParts[1]);

        // Calculate scheduled notification time (15 minutes before class)
        final classDateTime = DateTime(
          date.toDate().year,
          date.toDate().month,
          date.toDate().day,
          startHour,
          startMinute,
        );

        final reminderTime = classDateTime.subtract(
          const Duration(minutes: 15),
        );

        // Only schedule if the reminder time is in the future
        if (reminderTime.isAfter(DateTime.now())) {
          await scheduleClassReminder(
            userId: userId,
            subjectName: subjectName,
            classDateTime: classDateTime,
            reminderTime: reminderTime,
          );
        }
      }
    } catch (e) {
      // print('Error handling schedule creation: $e');
    }
  }

  // Handle task changes and automatically schedule notifications
  Future<void> handleTaskCreated(Map<String, dynamic> taskData) async {
    try {
      final userId = taskData['userId'] as String?;
      final taskName = taskData['title'] as String?;
      final dueDate = taskData['dueDate'] as Timestamp?;

      if (userId != null && taskName != null && dueDate != null) {
        final dueDateTime = dueDate.toDate();

        // Schedule different types of reminders
        await _scheduleTaskReminders(
          userId: userId,
          taskName: taskName,
          dueDateTime: dueDateTime,
        );
      }
    } catch (e) {
      // print('Error handling task creation: $e');
    }
  }

  // Handle user registration and schedule welcome notification
  Future<void> handleUserRegistered(String userId, String userName) async {
    try {
      await scheduleWelcomeNotification(userId, userName);
    } catch (e) {
      // print('Error handling user registration: $e');
    }
  }

  // Reschedule notifications for a specific user (when their schedule changes)
  Future<void> rescheduleUserNotifications(String userId) async {
    try {
      // Remove existing scheduled notifications for this user
      final existingQuery =
          await FirebaseFirestore.instance
              .collection('scheduledNotifications')
              .where('createdBy', isEqualTo: 'system')
              .where('targetUserIds', arrayContains: userId)
              .where('status', isEqualTo: 'pending')
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in existingQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Reschedule class reminders
      final scheduleQuery =
          await FirebaseFirestore.instance
              .collection('schedules')
              .where('userId', isEqualTo: userId)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
              )
              .get();

      for (var doc in scheduleQuery.docs) {
        await handleScheduleCreated(doc.data());
      }

      // Reschedule task reminders
      final taskQuery =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('userId', isEqualTo: userId)
              .where('completed', isEqualTo: false)
              .get();

      for (var doc in taskQuery.docs) {
        await handleTaskCreated(doc.data());
      }
    } catch (e) {
      // print('Error rescheduling user notifications: $e');
    }
  }
}
