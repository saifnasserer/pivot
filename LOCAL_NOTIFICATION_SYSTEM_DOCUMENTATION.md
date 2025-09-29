# Local Notification System Documentation

## 📱 Overview

The Pivot app implements a comprehensive local notification system using the `awesome_notifications` package to provide timely reminders for tasks and class schedules. The system is designed to work offline and provides Arabic-language notifications for Egyptian users.

## 🏗️ Architecture

### Core Components

1. **LocalNotificationService** - Main service for managing notifications
2. **TaskProvider** - Integrates with task management
3. **ScheduleProvider** - Handles class schedule notifications
4. **NotificationTriggerService** - Remote notification coordination
5. **SoundService** - Custom notification sounds

### Key Features

- ✅ **Offline Support** - Works without internet connection
- ✅ **Arabic Language** - All notifications in Arabic
- ✅ **Smart Scheduling** - Multiple reminder types
- ✅ **Permission Management** - Automatic permission requests
- ✅ **Sound Integration** - Custom notification sounds
- ✅ **Grouped Notifications** - Organized by type (tasks/classes)

## 🔧 Implementation Details

### 1. Service Initialization

```dart
// lib/services/local_notification_service.dart
class LocalNotificationService {
  static final LocalNotificationService instance = LocalNotificationService._();

  // Notification channels
  static const String _channelKey = 'pivot_notifications';
  static const String _channelName = 'Pivot Notifications';
  static const String _channelDescription = 'Reminders and updates from Pivot';

  // Group keys for notification organization
  static const String _groupClass = 'class_reminders';
  static const String _groupTask = 'task_reminders';
}
```

### 2. Permission Management

```dart
Future<void> initialize() async {
  if (kIsWeb) return; // Web doesn't support local notifications

  await AwesomeNotifications().initialize(
    'resource://drawable/ic_notification', // Custom icon
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

  // Request permissions
  final allowed = await AwesomeNotifications().isNotificationAllowed();
  if (!allowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
}
```

## 📋 Task Reminder System

### Reminder Types

The system provides **3 types of task reminders**:

1. **Early Reminder** (3 days before)

   - Time: 9:00 AM
   - Message: "التاسك [taskName] محتاج يتسلم في خلال 3 ايام"

2. **Tomorrow Reminder** (1 day before)

   - Time: 6:00 PM
   - Message: "التاسك [taskName] مطلوب بكرة، ابدأ فيه دلوقتي"

3. **Due Today Reminder** (on due date)
   - Time: 8:00 AM
   - Message: "التاسك [taskName] لازم يتسلم النهاردة"

### Implementation

```dart
Future<void> scheduleTaskReminders({
  required String taskId,
  required String taskName,
  required DateTime dueDateTime,
  required bool isCompleted,
}) async {
  if (kIsWeb) return;

  // Cancel existing reminders to avoid duplicates
  await cancelTaskReminders(taskId);

  if (isCompleted) return;

  final now = DateTime.now();

  // 3 days before at 09:00
  final threeDaysBefore = DateTime(
    dueDateTime.year,
    dueDateTime.month,
    dueDateTime.day - 3,
    9, 0,
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
  }

  // Additional reminders...
}
```

### Integration with TaskProvider

```dart
// lib/providers/task_provider.dart
Future<void> addTask(Task task) async {
  try {
    await _tasksCollection.doc(task.id).set(task.toMap());

    // Schedule local reminders
    if (!kIsWeb) {
      await LocalNotificationService.instance.scheduleTaskReminders(
        taskId: task.id,
        taskName: task.title,
        dueDateTime: task.dueDate,
        isCompleted: false,
      );
    }
  } catch (e) {
    throw Exception('Failed to add task: $e');
  }
}
```

## 🎓 Class Schedule Notifications

### Reminder Types

1. **Weekly Recurring Classes** (Sections)

   - Reminder: 15 minutes before class
   - Repeats: Every week on the same day/time
   - Message: "سكشن [subjectName] يبدأ خلال 15 دقيقة"

2. **One-time Lectures**
   - Reminder: 15 minutes before class
   - Single occurrence
   - Message: "محاضرة [subjectName] تبدأ خلال 15 دقيقة"

### Implementation

```dart
Future<void> scheduleClassReminder({
  required String scheduleItemId,
  required String subjectName,
  required int weekday, // DateTime.monday..sunday
  required int classHour,
  required int classMinute,
  bool isRecurring = true,
  String? classType, // 'lecture' or 'section'
}) async {
  if (kIsWeb) return;

  final id = _stableIdFrom('class:$scheduleItemId');

  if (isRecurring) {
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
```

### Weekly Recurring Implementation

```dart
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

  // Handle time overflow
  if (reminderMinute < 0) {
    reminderMinute += 60;
    reminderHour -= 1;
  }

  // Handle day overflow
  if (reminderHour < 0) {
    reminderHour += 24;
  }

  // Determine notification text
  final isSection = classType == 'section';
  final title = isSection ? 'سكشن قريب' : 'محاضرة قريبة';
  final body = isSection
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
```

## 🔄 Integration with Providers

### TaskProvider Integration

```dart
// lib/providers/task_provider.dart
class TaskProvider extends ChangeNotifier {
  // When adding a task
  Future<void> addTask(Task task) async {
    await _tasksCollection.doc(task.id).set(task.toMap());

    // Schedule local reminders
    if (!kIsWeb) {
      await LocalNotificationService.instance.scheduleTaskReminders(
        taskId: task.id,
        taskName: task.title,
        dueDateTime: task.dueDate,
        isCompleted: false,
      );
    }
  }

  // When completing a task
  Future<void> toggleTaskCompletion(String taskId) async {
    // Update task status
    // ...

    // Re-schedule reminders based on new status
    if (!kIsWeb) {
      await LocalNotificationService.instance.scheduleTaskReminders(
        taskId: task.id,
        taskName: task.title,
        dueDateTime: task.dueDate,
        isCompleted: updatedCompleted,
      );
    }
  }
}
```

### ScheduleProvider Integration

```dart
// lib/providers/schadule_provider.dart
class ScheduleProvider extends ChangeNotifier {
  Future<void> addScheduleItem({
    required String title,
    required String time,
    required String location,
    required String day,
    required ScheduleItemType type,
    bool notificationEnabled = true,
  }) async {
    // Create schedule item
    // ...

    // Schedule class notifications
    if (notificationEnabled && !kIsWeb) {
      final isRecurring = item.type == ScheduleItemType.section;

      await LocalNotificationService.instance.scheduleClassReminder(
        scheduleItemId: item.id,
        subjectName: item.title,
        weekday: dayOfWeek,
        classHour: hour,
        classMinute: minute,
        isRecurring: isRecurring,
        classType: item.type == ScheduleItemType.section ? 'section' : 'lecture',
      );
    }
  }
}
```

## 🎵 Sound Integration

### Custom Notification Sounds

```dart
// lib/services/sound_service.dart
class SoundService {
  Future<void> playNotificationSound() async {
    // Play custom notification sound
    // Implementation depends on audio package used
  }

  Future<void> playCorrectSound() async {
    // Play success sound for task completion
  }
}
```

### Integration with Notifications

```dart
// In LocalNotificationService
Future<bool> sendTestNotification({
  String? title,
  String? body,
  String? sound,
}) async {
  try {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: safeId,
        channelKey: _channelKey,
        title: title ?? 'Test Notification',
        body: body ?? 'This is a test notification',
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
```

## 🧹 Cleanup and Management

### Canceling Notifications

```dart
// Cancel task reminders
Future<void> cancelTaskReminders(String taskId) async {
  if (kIsWeb) return;

  final earlyId = _stableIdFrom('task:$taskId:early');
  final tomorrowId = _stableIdFrom('task:$taskId:tomorrow');
  final dueId = _stableIdFrom('task:$taskId:due');

  await AwesomeNotifications().cancel(earlyId);
  await AwesomeNotifications().cancel(tomorrowId);
  await AwesomeNotifications().cancel(dueId);
}

// Cancel class reminders
Future<void> cancelClassReminder(String scheduleItemId) async {
  if (kIsWeb) return;

  final id = _stableIdFrom('class:$scheduleItemId');
  await AwesomeNotifications().cancel(id);
}
```

### Notification Statistics

```dart
Future<Map<String, dynamic>> getScheduledNotificationsInfo() async {
  if (kIsWeb) {
    return {
      'totalScheduled': 0,
      'taskReminders': 0,
      'classReminders': 0,
      'platform': 'web',
    };
  }

  try {
    final scheduledNotifications = await AwesomeNotifications().listScheduledNotifications();

    int taskReminders = 0;
    int classReminders = 0;

    for (final notification in scheduledNotifications) {
      final payload = notification.content?.payload;
      if (payload != null) {
        if (payload['type'] == 'task_reminder') {
          taskReminders++;
        } else if (payload['type'] == 'class_reminder') {
          classReminders++;
        }
      }
    }

    return {
      'totalScheduled': scheduledNotifications.length,
      'taskReminders': taskReminders,
      'classReminders': classReminders,
      'platform': Platform.operatingSystem,
    };
  } catch (e) {
    return {
      'error': e.toString(),
      'totalScheduled': 0,
      'taskReminders': 0,
      'classReminders': 0,
    };
  }
}
```

## 🔧 Configuration

### Notification Channels

```dart
static const String _channelKey = 'pivot_notifications';
static const String _channelName = 'Pivot Notifications';
static const String _channelDescription = 'Reminders and updates from Pivot';

// Channel configuration
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
)
```

### Group Keys

```dart
// Group notifications by type
static const String _groupClass = 'class_reminders';
static const String _groupTask = 'task_reminders';
```

## 📱 Platform Support

### Mobile Platforms

- ✅ **Android** - Full support with precise alarms
- ✅ **iOS** - Full support with proper permissions
- ❌ **Web** - Not supported (graceful fallback)

### Platform-Specific Features

```dart
// Android-specific features
schedule: NotificationCalendar(
  weekday: weekday,
  hour: reminderHour,
  minute: reminderMinute,
  second: 0,
  millisecond: 0,
  repeats: true,
  preciseAlarm: Platform.isAndroid, // Android 12+ precise alarms
),

// iOS-specific features
wakeUpScreen: true, // Wake device for important notifications
```

## 🚀 Usage Examples

### Basic Task Reminder

```dart
// Schedule task reminders
await LocalNotificationService.instance.scheduleTaskReminders(
  taskId: 'task_123',
  taskName: 'Complete Assignment',
  dueDateTime: DateTime.now().add(Duration(days: 3)),
  isCompleted: false,
);
```

### Class Schedule Reminder

```dart
// Schedule weekly class reminder
await LocalNotificationService.instance.scheduleClassReminder(
  scheduleItemId: 'class_456',
  subjectName: 'Mathematics',
  weekday: DateTime.monday,
  classHour: 10,
  classMinute: 30,
  isRecurring: true,
  classType: 'section',
);
```

### Test Notification

```dart
// Send test notification
await LocalNotificationService.instance.sendTestNotification(
  title: 'Test Title',
  body: 'Test message',
);
```

## 🔍 Debugging and Monitoring

### Get Notification Statistics

```dart
final stats = await LocalNotificationService.instance.getScheduledNotificationsInfo();
print('Total scheduled: ${stats['totalScheduled']}');
print('Task reminders: ${stats['taskReminders']}');
print('Class reminders: ${stats['classReminders']}');
```

### Check Permissions

```dart
final isAllowed = await AwesomeNotifications().isNotificationAllowed();
if (!isAllowed) {
  await AwesomeNotifications().requestPermissionToSendNotifications();
}
```

## 🛠️ Troubleshooting

### Common Issues

1. **Notifications not showing**

   - Check permissions
   - Verify channel configuration
   - Ensure device is not in Do Not Disturb mode

2. **Sound not playing**

   - Check device volume
   - Verify sound file exists
   - Check notification channel sound settings

3. **Scheduled notifications not firing**
   - Check if device has battery optimization disabled
   - Verify notification scheduling logic
   - Check for timezone issues

### Debug Mode

```dart
// Enable debug mode during development
await AwesomeNotifications().initialize(
  'resource://drawable/ic_notification',
  [/* channels */],
  debug: true, // Enable debug logging
);
```

## 📊 Performance Considerations

### Memory Usage

- Notifications are stored locally on device
- Minimal memory footprint
- Automatic cleanup of expired notifications

### Battery Impact

- Uses system notification scheduler
- No background processing required
- Optimized for battery life

### Storage

- Notifications stored in system database
- No additional storage required
- Automatic cleanup by system

## 🔒 Security Considerations

### Data Privacy

- No sensitive data in notification payload
- Only task/schedule IDs and names
- No personal information exposed

### Permission Handling

- Graceful permission requests
- Fallback behavior when permissions denied
- No data loss if notifications disabled

## 📈 Future Enhancements

### Planned Features

- [ ] Notification templates
- [ ] Custom notification sounds
- [ ] Notification analytics
- [ ] Smart notification timing
- [ ] Notification categories
- [ ] Rich notifications with actions

### Integration Opportunities

- [ ] Calendar integration
- [ ] Email reminders
- [ ] SMS notifications
- [ ] Push notification fallback
- [ ] Notification preferences

---

## 📝 Summary

The Pivot app's local notification system provides a comprehensive solution for task and class reminders with:

- **Arabic language support** for Egyptian users
- **Offline functionality** for reliability
- **Smart scheduling** with multiple reminder types
- **Platform optimization** for Android and iOS
- **Sound integration** for better user experience
- **Easy integration** with existing providers

The system is designed to be maintainable, scalable, and user-friendly while providing essential reminder functionality for academic success.




