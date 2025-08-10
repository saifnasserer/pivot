import 'dart:io' show Platform;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
          soundSource: 'resource://raw/notification',
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
        print('LocalNotification: No current user found');
        return false;
      }

      // Get the task details
      final taskDoc = await firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        print('LocalNotification: Task $taskId not found');
        return false;
      }

      final taskData = taskDoc.data()!;
      final taskSectionId = taskData['sectionId'] as String?;

      if (taskSectionId == null) {
        print('LocalNotification: Task $taskId has no sectionId');
        return false;
      }

      // Get current user's profile
      final userDoc =
          await firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        print('LocalNotification: User profile not found');
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
        print('LocalNotification: Section $taskSectionId not found');
        return false;
      }

      final sectionData = sectionDoc.data()!;
      final sectionSubjectId = sectionData['subjectId'] as String?;
      final sectionAssistantId = sectionData['assistantId'] as String?;

      if (sectionSubjectId == null || sectionAssistantId == null) {
        print(
          'LocalNotification: Section $taskSectionId missing subjectId or assistantId',
        );
        return false;
      }

      // Check if user is enrolled in this subject
      if (!userEnrolledSubjectIds.contains(sectionSubjectId)) {
        print(
          'LocalNotification: User not enrolled in subject $sectionSubjectId',
        );
        return false;
      }

      // Check if this is the user's preferred assistant for this subject
      final preferredAssistantId = assistantPreferences[sectionSubjectId];
      if (preferredAssistantId != null &&
          preferredAssistantId != sectionAssistantId) {
        print(
          'LocalNotification: User prefers different assistant for subject $sectionSubjectId',
        );
        return false;
      }

      // Check if section matches user's section (if user has a section)
      if (userSection != null) {
        final sectionName = sectionData['name'] as String?;
        if (sectionName != null &&
            !_matchesUserSectionNumber(sectionName, userSection)) {
          print(
            'LocalNotification: Section $sectionName does not match user section $userSection',
          );
          return false;
        }
      }

      print('LocalNotification: ✅ Task $taskId belongs to current user');
      return true;
    } catch (e) {
      print('LocalNotification: Error checking if task belongs to user: $e');
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
    print('🔔 === LOCAL NOTIFICATION SERVICE - SCHEDULE CLASS REMINDER ===');
    print('  - Schedule Item ID: $scheduleItemId');
    print('  - Subject Name: $subjectName');
    print('  - Weekday: $weekday (${_weekdayName(weekday)})');
    print('  - Class Hour: $classHour');
    print('  - Class Minute: $classMinute');
    print('  - Is Recurring: $isRecurring');
    print('  - Is Web: $kIsWeb');

    if (kIsWeb) {
      print('  - ⚠️ On web, skipping local notification');
      return;
    }

    // Check if awesome_notifications is properly initialized and has permissions
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      print('  - Notification permission allowed: $isAllowed');

      if (!isAllowed) {
        print('  - ❌ Notifications not allowed, requesting permission...');
        await AwesomeNotifications().requestPermissionToSendNotifications();
        final isAllowedAfterRequest =
            await AwesomeNotifications().isNotificationAllowed();
        print('  - Permission after request: $isAllowedAfterRequest');

        if (!isAllowedAfterRequest) {
          print('  - ❌ User denied notification permission, cannot schedule');
          return;
        }
      }
    } catch (e) {
      print('  - ❌ Error checking notification permissions: $e');
      return;
    }

    final id = _stableIdFrom('class:$scheduleItemId');
    print('  - Generated notification ID: $id');

    if (isRecurring) {
      print('  - Scheduling recurring weekly class...');
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
      print('  - ✅ Recurring weekly class scheduled');
    } else {
      print('  - Scheduling one-time lecture...');
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
      print('  - ✅ One-time lecture scheduled');
    }
    print('🔔 === LOCAL NOTIFICATION SERVICE COMPLETE ===');
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
    print('🔁 === SCHEDULING WEEKLY RECURRING ===');
    print('  - ID: $id');
    print('  - Subject: $subjectName');
    print(
      '  - Class time: $classHour:${classMinute.toString().padLeft(2, '0')}',
    );

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

    print(
      '  - Reminder time: $reminderHour:${reminderMinute.toString().padLeft(2, '0')}',
    );
    print('  - Weekday: $weekday (${_weekdayName(weekday)})');

    print('  - Creating AwesomeNotifications notification...');
    print('  - NotificationCalendar details:');
    print('    * Weekday: $weekday');
    print('    * Hour: $reminderHour');
    print('    * Minute: $reminderMinute');
    print('    * Repeats: true');
    print('    * PreciseAlarm: ${Platform.isAndroid}');

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
    print('  - ✅ Weekly recurring notification created successfully');
    print('🔁 === WEEKLY RECURRING COMPLETE ===');
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

    print('🔔 Scheduling one-time class reminder:');
    print('  - Subject: $subjectName');
    print('  - Target weekday: $weekday (${_weekdayName(weekday)})');
    print('  - Current weekday: ${now.weekday} (${_weekdayName(now.weekday)})');
    print(
      '  - Class time: $classHour:${classMinute.toString().padLeft(2, '0')}',
    );
    print(
      '  - Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    );

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

    print('  - Class date/time: $classDate');
    print('  - Reminder date/time: $reminderDate');
    print('  - Days to add: $daysToAdd');

    // Check if we should schedule future reminder or send immediate notification
    if (classDate.isBefore(now)) {
      print('  - ❌ Class has already passed, no notification scheduled');
    } else if (classDate.difference(now).inMinutes <= 15) {
      // Class is happening within 15 minutes - send immediate notification
      final minutesToClass = classDate.difference(now).inMinutes;
      print(
        '  - ⚡ Sending immediate notification ($minutesToClass minutes to class)',
      );
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
      print('  - ✅ Immediate notification sent successfully');
    } else {
      // Schedule future reminder (15 minutes before class)
      print('  - ✅ Scheduling future reminder notification');
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
      print('  - ✅ Future reminder scheduled successfully');
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

    print('📋 === SCHEDULE TASK REMINDERS ===');
    print('  - Task ID: $taskId');
    print('  - Task Name: $taskName');
    print('  - Due Date: $dueDateTime');
    print('  - Is Completed: $isCompleted');

    // Always cancel existing before re-scheduling to avoid duplicates
    await cancelTaskReminders(taskId);

    if (isCompleted) {
      print('  - ✅ Task completed, no reminders needed');
      return;
    }

    // Check if this task belongs to the current user
    if (!await _isTaskForCurrentUser(taskId)) {
      print('  - ❌ Task does not belong to current user, skipping reminders');
      return;
    }

    final now = DateTime.now();
    print('  - Current time: $now');

    // 3 days before at 09:00
    final threeDaysBefore = DateTime(
      dueDateTime.year,
      dueDateTime.month,
      dueDateTime.day - 3, // Subtract 3 days from the day
      9,
      0,
    );

    if (threeDaysBefore.isAfter(now)) {
      print('  - ⏰ Scheduling 3-day early reminder for: $threeDaysBefore');
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
      print('  - ✅ 3-day early reminder scheduled');
    } else {
      print('  - ⏭️ 3-day early reminder time has passed');
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
      print('  - ⏰ Scheduling 1-day before reminder for: $oneDayBefore');
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
      print('  - ✅ 1-day before reminder scheduled');
    } else {
      print('  - ⏭️ 1-day before reminder time has passed');
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
      print('  - ⏰ Scheduling due day morning reminder for: $dueMorning');
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
      print('  - ✅ Due day morning reminder scheduled');
    } else {
      print('  - ⏭️ Due day morning reminder time has passed');
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
      print('  - ⏰ Scheduling due day evening reminder for: $dueEvening');
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
      print('  - ✅ Due day evening reminder scheduled');
    } else {
      print('  - ⏭️ Due day evening reminder time has passed');
    }

    // Overdue daily at 10:00 starting tomorrow if overdue
    if (dueDateTime.isBefore(now)) {
      final daysOverdue = now.difference(dueDateTime).inDays;
      print('  - 🚨 Task is overdue by $daysOverdue days');
      final start = DateTime(
        now.year,
        now.month,
        now.day,
        10,
        0,
      ).add(const Duration(days: 1));
      print('  - ⏰ Scheduling daily overdue reminders starting: $start');
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
      print('  - ✅ Daily overdue reminders scheduled');
    } else {
      print('  - ✅ Task is not overdue yet');
    }

    print('📋 === TASK REMINDERS COMPLETE ===');
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
      return true;
    } catch (e) {
      print('❌ Error sending test notification: $e');
      return false;
    }
  }

  // Get scheduled notifications count and details
  Future<Map<String, dynamic>> getScheduledNotificationsInfo() async {
    if (kIsWeb) return {'count': 0, 'notifications': []};

    try {
      final notifications =
          await AwesomeNotifications().listScheduledNotifications();

      print('🔍 === SCHEDULED NOTIFICATIONS DEBUG ===');
      print('  - Total scheduled notifications: ${notifications.length}');

      final notificationList =
          notifications.map((n) {
            final schedule = n.schedule;
            final content = n.content;

            print('  - Notification ID: ${content?.id}');
            print('    * Title: ${content?.title}');
            print('    * Payload type: ${content?.payload?['type']}');
            print('    * Subject: ${content?.payload?['subjectName']}');
            print('    * Schedule: ${schedule.toString()}');

            if (schedule is NotificationCalendar) {
              print('    * Weekday: ${schedule.weekday}');
              print('    * Hour: ${schedule.hour}');
              print('    * Minute: ${schedule.minute}');
              print('    * Repeats: ${schedule.repeats}');
            }
            print('    ---');

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

      print('🔍 === SCHEDULED NOTIFICATIONS COMPLETE ===');

      return {'count': notifications.length, 'notifications': notificationList};
    } catch (e) {
      print('❌ Error getting scheduled notifications: $e');
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
