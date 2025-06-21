import 'package:flutter/material.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationTriggerService {
  static final NotificationTriggerService _instance =
      NotificationTriggerService._internal();
  factory NotificationTriggerService() => _instance;
  NotificationTriggerService._internal();

  final NotificationService _notificationService = NotificationService();

  // Send task reminder notifications
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

  // Send announcement notifications
  Future<void> sendAnnouncement(
    String title,
    String body, {
    List<String>? targetUserIds,
  }) async {
    try {
      List<String> tokens = [];

      if (targetUserIds != null) {
        // Send to specific users
        tokens = await _notificationService.getMultipleUserFCMTokens(
          targetUserIds,
        );
      } else {
        // Send to all users
        tokens = await _notificationService.getAllUserFCMTokens();
      }

      for (String token in tokens) {
        await _notificationService.sendNotification(
          targetToken: token,
          title: title,
          body: body,
        );
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

  // 2. Task due today
  Future<void> sendTaskDueTodayNotifications() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get tasks due today
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('dueDate', isEqualTo: today)
              .where('completed', isEqualTo: false)
              .get();

      for (var doc in querySnapshot.docs) {
        final taskData = doc.data();
        final userId = taskData['userId'] as String?;
        final taskName = taskData['title'] as String?;

        if (userId != null && taskName != null) {
          final token = await _notificationService.getUserFCMToken(userId);
          if (token != null) {
            await _notificationService.sendNotification(
              targetToken: token,
              title: 'تاسك اليوم',
              body: 'التاسك "$taskName" لازم يتسلم النهاردة',
            );
          }
        }
      }
    } catch (e) {
      print('Error sending task due today notifications: $e');
    }
  }

  // 3. Task overdue - urgent reminders
  Future<void> sendOverdueTaskNotifications() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get overdue tasks
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('dueDate', isLessThan: today)
              .where('completed', isEqualTo: false)
              .get();

      for (var doc in querySnapshot.docs) {
        final taskData = doc.data();
        final userId = taskData['userId'] as String?;
        final taskName = taskData['title'] as String?;
        final dueDate = taskData['dueDate'] as Timestamp?;

        if (userId != null && taskName != null && dueDate != null) {
          final daysOverdue = today.difference(dueDate.toDate()).inDays;

          final token = await _notificationService.getUserFCMToken(userId);
          if (token != null) {
            await _notificationService.sendNotification(
              targetToken: token,
              title: 'تاسك متأخر!',
              body: 'التاسك "$taskName" متأخر $daysOverdue يوم',
            );
          }
        }
      }
    } catch (e) {
      print('Error sending overdue task notifications: $e');
    }
  }

  // 4. 3 days before task due - early reminders
  Future<void> sendEarlyTaskReminders() async {
    try {
      final now = DateTime.now();
      final threeDaysFromNow = DateTime(now.year, now.month, now.day + 3);

      // Get tasks due in 3 days
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('dueDate', isEqualTo: threeDaysFromNow)
              .where('completed', isEqualTo: false)
              .get();

      for (var doc in querySnapshot.docs) {
        final taskData = doc.data();
        final userId = taskData['userId'] as String?;
        final taskName = taskData['title'] as String?;

        if (userId != null && taskName != null) {
          final token = await _notificationService.getUserFCMToken(userId);
          if (token != null) {
            await _notificationService.sendNotification(
              targetToken: token,
              title: 'تذكير مبكر',
              body: 'التاسك "$taskName" محتاج يتسلم في خلال 3 ايام',
            );
          }
        }
      }
    } catch (e) {
      print('Error sending early task reminders: $e');
    }
  }

  // 5. New announcements from user department
  Future<void> sendNewAnnouncementNotification(
    String announcementTitle,
    String department,
  ) async {
    try {
      await sendDepartmentNotification(
        department,
        'خبر جديد',
        'خبر جديد: $announcementTitle',
      );
    } catch (e) {
      print('Error sending new announcement notification: $e');
    }
  }

  // Run all auto notifications
  Future<void> runAllAutoNotifications() async {
    await sendClassReminders();
    await sendTaskDueTodayNotifications();
    await sendOverdueTaskNotifications();
    await sendEarlyTaskReminders();
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
        await sendTaskDueTodayNotifications();
        await sendOverdueTaskNotifications();
        await sendEarlyTaskReminders();
      }
    } catch (e) {
      print('Error in periodic notification check: $e');
    }
  }
}
