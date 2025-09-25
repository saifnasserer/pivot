import 'dart:io' show Platform;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/services/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  static const String _channelKey = 'pivot_notifications';
  static const String _channelName = 'Pivot Notifications';
  static const String _channelDescription = 'Reminders and updates from Pivot';

  // Group keys
  static const String _groupClass = 'class_reminders';
  static const String _groupTask = 'task_reminders';

  Future<void> initialize() async {
    if (kIsWeb) return; // Local notifications are for mobile/desktop only

    await AwesomeNotifications().initialize(
      'resource://drawable/ic_notification', // use custom notification icon
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: _channelName,
          channelDescription: _channelDescription,
          defaultColor: const Color(0xFF000000),
          ledColor: const Color(0xFF000000),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          defaultRingtoneType: DefaultRingtoneType.Notification,
          playSound: true,
        ),
      ],
      debug: false,
    );

    // Request permission if needed
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<bool> ensurePermissions(BuildContext? context) async {
    if (kIsWeb) return false;
    bool allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed && context != null && context.mounted) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
      allowed = await AwesomeNotifications().isNotificationAllowed();
    }
    return allowed;
  }

  // ===== Helpers =====
  int _stableIdFrom(String key) => key.hashCode & 0x7fffffff;

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  // Check if a task belongs to the current user based on week_tasks.dart filtering logic
  Future<bool> _isTaskForCurrentUser(String taskId) async {
    try {
      // Import necessary services
      final firestore = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;

      final currentUser = auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      // Get the task details
      final taskDoc = await firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        return false;
      }

      final taskData = taskDoc.data()!;
      final taskSectionId = taskData['sectionId'] as String?;

      if (taskSectionId == null) {
        return false;
      }

      // Get current user's profile
      final userDoc =
          await firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data()!;
      final userEnrolledSubjectIds = List<String>.from(
        userData['enrolledSubjects'] ?? [],
      );
      final userSection = userData['section'] as String?;
      final assistantPreferences = Map<String, String>.from(
        userData['assistantPreferences'] ?? {},
      );

      // Get the section details
      final sectionDoc =
          await firestore.collection('sections').doc(taskSectionId).get();
      if (!sectionDoc.exists) {
        return false;
      }

      final sectionData = sectionDoc.data()!;
      final sectionSubjectId = sectionData['subjectId'] as String?;
      final sectionAssistantId = sectionData['assistantId'] as String?;

      if (sectionSubjectId == null || sectionAssistantId == null) {
        return false;
      }

      // Check if user is enrolled in this subject
      if (!userEnrolledSubjectIds.contains(sectionSubjectId)) {
        return false;
      }

      // Check if this is the user's preferred assistant for this subject
      final preferredAssistantId = assistantPreferences[sectionSubjectId];
      if (preferredAssistantId != null &&
          preferredAssistantId != sectionAssistantId) {
        return false;
      }

      // Check if section matches user's section (if user has a section)
      if (userSection != null) {
        final sectionName = sectionData['name'] as String?;
        if (sectionName != null &&
            !_matchesUserSectionNumber(sectionName, userSection)) {
          return false;
        }
      }

      return true;
    } catch (e) {

      return false;
    }
  }

  // Helper method to check if section number matches user's section number
  bool _matchesUserSectionNumber(String sectionName, String userSection) {
    // Extract number from section name (e.g., "سكشن 1" -> "1", "Section A" -> "A")
    final sectionNumber = _extractSectionNumber(sectionName);
    final cleanUserSection = userSection.trim();
    return sectionNumber == cleanUserSection;
  }

  // Extract section number from section name
  String _extractSectionNumber(String sectionName) {
    final cleanName = sectionName.trim().toLowerCase();

    // Try to extract number after "سكشن" or "section"
    final arabicMatch = RegExp(r'سكشن\s*(\w+)').firstMatch(cleanName);
    if (arabicMatch != null) {
      return arabicMatch.group(1) ?? '';
    }

    final englishMatch = RegExp(r'section\s*(\w+)').firstMatch(cleanName);
    if (englishMatch != null) {
      return englishMatch.group(1) ?? '';
    }

    // If no prefix found, try to extract the last word/number
    final words = cleanName.split(RegExp(r'[\s\-_]+'));
    return words.isNotEmpty ? words.last : '';
  }

  // ===== Class Reminders =====

  // Schedule class reminder (supports both one-time and recurring)
  Future<void> scheduleClassReminder({
    required String scheduleItemId,
    required String subjectName,
    required int weekday, // DateTime.monday..sunday
    required int classHour,
    required int classMinute,
    bool isRecurring =
        true, // true for weekly classes, false for one-time lectures
    String? classType, // 'lecture' or 'section'
  }) async {

    if (kIsWeb) {
      return;
    }

    // Check if awesome_notifications is properly initialized and has permissions
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();

      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
        final isAllowedAfterRequest =
            await AwesomeNotifications().isNotificationAllowed();

        if (!isAllowedAfterRequest) {
          return;
        }
      }
    } catch (e) {
      return;
    }

    final id = _stableIdFrom('class:$scheduleItemId');

    if (isRecurring) {
      // For recurring weekly classes
      await _scheduleWeeklyRecurring(
        id: id,
        scheduleItemId: scheduleItemId,
        subjectName: subjectName,
        weekday: weekday,
        classHour: classHour,
        classMinute: classMinute,
        classType: classType,
      );

    } else {
      // For one-time lectures/classes
      await _scheduleOneTimeClass(
        id: id,
        scheduleItemId: scheduleItemId,
        subjectName: subjectName,
        weekday: weekday,
        classHour: classHour,
        classMinute: classMinute,
        classType: classType,
      );
    }
  }

  // Schedule weekly recurring class reminder
  Future<void> _scheduleWeeklyRecurring({
    required int id,
    required String scheduleItemId,
    required String subjectName,
    required int weekday,
    required int classHour,
    required int classMinute,
    String? classType,
  }) async {

    // Calculate reminder time (15 minutes before class)
    int reminderHour = classHour;
    int reminderMinute = classMinute - 15;

    // Handle time overflow (e.g., class at 11:10, reminder at 10:55)
    if (reminderMinute < 0) {
      reminderMinute += 60;
      reminderHour -= 1;
    }

    // Handle day overflow (e.g., class at 00:10, reminder at 23:55 previous day)
    if (reminderHour < 0) {
      reminderHour += 24;
      // Note: awesome_notifications handles day adjustment automatically for weekly reminders
    }



    // Determine if it's a section or lecture for Arabic text
    final isSection = classType == 'section';
    final title = isSection ? 'سكشن قريب' : 'محاضرة قريبة';
    final body =
        isSection
            ? 'سكشن $subjectName يبدأ خلال 15 دقيقة'
            : 'محاضرة $subjectName تبدأ خلال 15 دقيقة';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: _channelKey,
        title: title,
        body: body,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        groupKey: _groupClass,
        icon: 'resource://drawable/ic_notification',
        payload: {
          'type': 'class_reminder',
          'scheduleItemId': scheduleItemId,
          'subjectName': subjectName,
          'isRecurring': 'true',
          'classType': classType ?? 'unknown',
        },
      ),
      schedule: NotificationCalendar(
        weekday: weekday,
        hour: reminderHour,
        minute: reminderMinute,
        second: 0,
        millisecond: 0,
        repeats: true,
        preciseAlarm: Platform.isAndroid,
      ),
    );
  }

  // Schedule one-time class reminder
  Future<void> _scheduleOneTimeClass({
    required int id,
    required String scheduleItemId,
    required String subjectName,
    required int weekday,
    required int classHour,
    required int classMinute,
    String? classType,
  }) async {
    final DateTime now = DateTime.now();

    // Find the next occurrence of this weekday
    DateTime classDate = DateTime(
      now.year,
      now.month,
      now.day,
      classHour,
      classMinute,
    );

    // Adjust to correct weekday
    int daysToAdd = weekday - now.weekday;
    if (daysToAdd < 0) daysToAdd += 7; // Next week

    // For one-time lectures, don't schedule for next week if it's today but soon
    // Instead, we'll handle immediate notifications below

    classDate = classDate.add(Duration(days: daysToAdd));
    final reminderDate = classDate.subtract(const Duration(minutes: 15));


    // Check if we should schedule future reminder or send immediate notification
    if (classDate.isBefore(now)) {
    } else if (classDate.difference(now).inMinutes <= 15) {
      // Class is happening within 15 minutes - send immediate notification
      final minutesToClass = classDate.difference(now).inMinutes;
      // Determine if it's a section or lecture for Arabic text
      final isSection = classType == 'section';
      final immediateTitle = isSection ? 'السكشن هيبدأ!' : 'المحاضرة هتبدأ!';
      final immediateBody =
          isSection
              ? 'سكشن $subjectName يبدأ خلال $minutesToClass دقيقة'
              : 'محاضرة $subjectName تبدأ خلال $minutesToClass دقيقة';

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _channelKey,
          title: immediateTitle,
          body: immediateBody,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          groupKey: _groupClass,
          icon: 'resource://drawable/ic_notification',
          payload: {
            'type': 'class_reminder_immediate',
            'scheduleItemId': scheduleItemId,
            'subjectName': subjectName,
            'minutesToClass': minutesToClass.toString(),
            'classType': classType ?? 'unknown',
          },
        ),
        // No schedule = immediate notification
      );

      // Play custom notification sound for immediate notifications
      await SoundService().playNotificationSound();

    } else {
      // Schedule future reminder (15 minutes before class)
      // Determine if it's a section or lecture for Arabic text
      final isSection = classType == 'section';
      final futureTitle = isSection ? 'سكشن قريب' : 'محاضرة قريبة';
      final futureBody =
          isSection
              ? 'سكشن $subjectName يبدأ خلال 15 دقيقة'
              : 'محاضرة $subjectName تبدأ خلال 15 دقيقة';

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _channelKey,
          title: futureTitle,
          body: futureBody,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          groupKey: _groupClass,
          icon: 'resource://drawable/ic_notification',
          payload: {
            'type': 'class_reminder',
            'scheduleItemId': scheduleItemId,
            'subjectName': subjectName,
            'isRecurring': 'false',
            'classType': classType ?? 'unknown',
          },
        ),
        schedule: NotificationCalendar.fromDate(
          date: reminderDate,
          preciseAlarm: Platform.isAndroid,
        ),
      );
    }
  }

  // Backward compatibility method
  Future<void> scheduleWeeklyClassReminder({
    required String scheduleItemId,
    required String subjectName,
    required int weekday,
    required int classHour,
    required int classMinute,
  }) async {
    await scheduleClassReminder(
      scheduleItemId: scheduleItemId,
      subjectName: subjectName,
      weekday: weekday,
      classHour: classHour,
      classMinute: classMinute,
      isRecurring: true,
      classType: 'section', // Backward compatibility assumes sections
    );
  }

  Future<void> cancelClassReminder(String scheduleItemId) async {
    if (kIsWeb) return;
    final id = _stableIdFrom('class:$scheduleItemId');
    await AwesomeNotifications().cancel(id);
  }

  // ===== Task Reminders =====
  Future<void> scheduleTaskReminders({
    required String taskId,
    required String taskName,
    required DateTime dueDateTime,
    required bool isCompleted,
  }) async {
    if (kIsWeb) return;


    // Always cancel existing before re-scheduling to avoid duplicates
    await cancelTaskReminders(taskId);

    if (isCompleted) {
      return;
    }

    // Check if this task belongs to the current user
    if (!await _isTaskForCurrentUser(taskId)) {
      return;
    }

    final now = DateTime.now();

    // 3 days before at 09:00
    final threeDaysBefore = DateTime(
      dueDateTime.year,
      dueDateTime.month,
      dueDateTime.day - 3, // Subtract 3 days from the day
      9,
      0,
    );

    if (threeDaysBefore.isAfter(now)) {
      await _scheduleOneTime(
        idKey: 'task:$taskId:early',
        title: 'تذكير مبكر',
        body: 'التاسك "$taskName" محتاج يتسلم في خلال 3 ايام',
        dateTime: threeDaysBefore,
        payload: {
          'type': 'task_reminder',
          'reminderType': 'early_reminder',
          'taskId': taskId,
          'taskName': taskName,
        },
      );
    } else {
    }

    // 1 day before at 18:00 (6 PM)
    final oneDayBefore = DateTime(
      dueDateTime.year,
      dueDateTime.month,
      dueDateTime.day - 1,
      18,
      0,
    );

    if (oneDayBefore.isAfter(now)) {
      await _scheduleOneTime(
        idKey: 'task:$taskId:tomorrow',
        title: 'تذكير قريب',
        body: 'التاسك "$taskName" مطلوب بكرة، ابدأ فيه دلوقتي',
        dateTime: oneDayBefore,
        payload: {
          'type': 'task_reminder',
          'reminderType': 'one_day_before',
          'taskId': taskId,
          'taskName': taskName,
        },
      );
    } else {
    }

    // On due day at 08:00
    final dueMorning = DateTime(
      dueDateTime.year,
      dueDateTime.month,
      dueDateTime.day,
      8,
      0,
    );
    if (dueMorning.isAfter(now)) {
      await _scheduleOneTime(
        idKey: 'task:$taskId:due',
        title: 'تاسك اليوم',
        body: 'التاسك "$taskName" لازم يتسلم النهاردة',
        dateTime: dueMorning,
        payload: {
          'type': 'task_reminder',
          'reminderType': 'due_today',
          'taskId': taskId,
          'taskName': taskName,
        },
      );
    } else {
    }

    // Same day evening reminder at 20:00 (8 PM)
    final dueEvening = DateTime(
      dueDateTime.year,
      dueDateTime.month,
      dueDateTime.day,
      20,
      0,
    );

    if (dueEvening.isAfter(now)) {
      await _scheduleOneTime(
        idKey: 'task:$taskId:evening',
        title: 'تاسك اليوم - تذكير أخير',
        body: 'التاسك "$taskName" لسه مطلوب النهاردة، متنساهوش!',
        dateTime: dueEvening,
        payload: {
          'type': 'task_reminder',
          'reminderType': 'due_evening',
          'taskId': taskId,
          'taskName': taskName,
        },
      );
    } else {
    }

    // Overdue daily at 10:00 starting tomorrow if overdue
    if (dueDateTime.isBefore(now)) {
      final daysOverdue = now.difference(dueDateTime).inDays;
      final start = DateTime(
        now.year,
        now.month,
        now.day,
        10,
        0,
      ).add(const Duration(days: 1));
      await _scheduleDailyRepeating(
        idKey: 'task:$taskId:overdue',
        title: 'تاسك متأخر!',
        body: 'التاسك "$taskName" متأخر، افتح Pivot عشان تكمله أو تعدل الميعاد',
        timeOfDay: TimeOfDay(hour: start.hour, minute: start.minute),
        payload: {
          'type': 'task_reminder',
          'reminderType': 'overdue',
          'taskId': taskId,
          'taskName': taskName,
        },
      );
    } else {
    }

  }

  Future<void> cancelTaskReminders(String taskId) async {
    if (kIsWeb) return;
    await AwesomeNotifications().cancel(_stableIdFrom('task:$taskId:early'));
    await AwesomeNotifications().cancel(_stableIdFrom('task:$taskId:due'));
    await AwesomeNotifications().cancel(_stableIdFrom('task:$taskId:overdue'));
  }

  // ===== Debug & Test Methods =====

  // Send immediate test notification to verify local notifications are working
  Future<bool> sendTestNotification({
    String? title,
    String? body,
    String? sound,
  }) async {
    if (kIsWeb) return false;

    try {
      // Use a safe 32-bit ID (current second since epoch % max 32-bit int)
      final safeId =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 2147483647;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: safeId,
          channelKey: _channelKey,
          title: title ?? 'Test Notification',
          body: body ?? 'This is a test notification sent at ${DateTime.now()}',
          category: NotificationCategory.Message,
          wakeUpScreen: true,
          icon: 'resource://drawable/ic_notification',
          payload: {
            'type': 'test_notification',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        ),
      );

      // Play custom notification sound
      await SoundService().playNotificationSound();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get scheduled notifications count and details
  Future<Map<String, dynamic>> getScheduledNotificationsInfo() async {
    if (kIsWeb) return {'count': 0, 'notifications': []};

    try {
      final notifications =
          await AwesomeNotifications().listScheduledNotifications();


      final notificationList =
          notifications.map((n) {
            final schedule = n.schedule;
            final content = n.content;


            if (schedule is NotificationCalendar) {
            }

            return {
              'id': content?.id,
              'title': content?.title,
              'body': content?.body,
              'scheduledDate': schedule?.toString(),
              'weekday':
                  schedule is NotificationCalendar ? schedule.weekday : null,
              'hour': schedule is NotificationCalendar ? schedule.hour : null,
              'minute':
                  schedule is NotificationCalendar ? schedule.minute : null,
              'repeats':
                  schedule is NotificationCalendar ? schedule.repeats : null,
              'payload': content?.payload,
            };
          }).toList();


      return {'count': notifications.length, 'notifications': notificationList};
    } catch (e) {
      return {'count': 0, 'notifications': [], 'error': e.toString()};
    }
  }

  // ===== Generic scheduling helpers =====
  Future<void> _scheduleOneTime({
    required String idKey,
    required String title,
    required String body,
    required DateTime dateTime,
    Map<String, String>? payload,
  }) async {
    final id = _stableIdFrom(idKey);
    if (dateTime.isBefore(DateTime.now())) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: _channelKey,
        title: title,
        body: body,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        groupKey: _groupTask,
        icon: 'resource://drawable/ic_notification',
        payload: payload,
      ),
      schedule: NotificationCalendar.fromDate(
        date: dateTime,
        preciseAlarm: Platform.isAndroid,
      ),
    );
  }

  Future<void> _scheduleDailyRepeating({
    required String idKey,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
    Map<String, String>? payload,
  }) async {
    final id = _stableIdFrom(idKey);
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: _channelKey,
        title: title,
        body: body,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        groupKey: _groupTask,
        icon: 'resource://drawable/ic_notification',
        payload: payload,
      ),
      schedule: NotificationCalendar(
        hour: timeOfDay.hour,
        minute: timeOfDay.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        preciseAlarm: Platform.isAndroid,
      ),
    );
  }
}
