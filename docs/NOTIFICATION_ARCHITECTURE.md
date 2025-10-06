# 📱 Notification Architecture - Complete Guide

## 🎯 Overview

Our app uses **TWO SEPARATE** notification systems working together:

1. **Local Notifications** (AwesomeNotifications) - For scheduled reminders
2. **FCM Push Notifications** (Firebase Cloud Messaging) - For server-initiated messages

---

## ✅ System 1: Local Notifications (AwesomeNotifications)

### **Purpose**

Scheduled, predictable, time-based reminders that work **offline** and in **background**.

### **When to Use**

- ✅ Task reminders (3 days before, 1 day before, due day, overdue)
- ✅ Class reminders (15 minutes before lecture/section)
- ✅ Recurring weekly schedule notifications

### **Key Features**

- ⚡ **Works when app is CLOSED** - OS handles notification delivery
- 🔌 **Works OFFLINE** - No internet needed
- 📱 **Survives device reboot** - Notifications persist after restart
- 🎯 **User-specific** - Each user controls their own reminders
- ⏰ **Precise timing** - Exact scheduling down to the minute

### **How It Works**

```
1. User creates task/schedule
          ↓
2. LocalNotificationService schedules notification
          ↓
3. Notification registered with Android/iOS OS
          ↓
4. OS fires notification at scheduled time
          ↓
5. Works even if app is closed!
```

### **Background Operation - YES!**

**Q: Do local notifications work when app is closed?**  
**A: YES! Absolutely!**

When you schedule a local notification:

1. It's registered with the **Operating System** (Android/iOS)
2. The **OS takes responsibility** for firing it
3. **App doesn't need to be running**
4. Notifications fire even if:
   - App is closed
   - App is in background
   - Device was restarted (Android with `RECEIVE_BOOT_COMPLETED` permission)

### **Android Manifest Configuration**

```xml
<!-- Ensures notifications work after device reboot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- For Android 13+ notification permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Wake device for notifications -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

### **Code Implementation**

**File:** `lib/services/local_notification_service.dart`

**Scheduling Task Reminders:**

```dart
await LocalNotificationService.instance.scheduleTaskReminders(
  taskId: docRef.id,
  taskName: task.title,
  dueDateTime: task.dueDate,
  isCompleted: false,
);
```

**Scheduling Class Reminders:**

```dart
await LocalNotificationService.instance.scheduleClassReminder(
  scheduleItemId: item.id,
  subjectName: item.title,
  weekday: DateTime.monday,
  classHour: 10,
  classMinute: 0,
  isRecurring: true,
  classType: 'lecture',
);
```

### **Used By:**

- `TaskService.addTask()` - When task is created
- `TaskService.updateTask()` - When task is updated
- `ScheduleService.addScheduleItem()` - When schedule is created
- `ScheduleService.updateScheduleItem()` - When schedule is updated

---

## 📡 System 2: FCM Push Notifications (Firebase)

### **Purpose**

Server-initiated, dynamic notifications for real-time updates and broadcasts.

### **When to Use**

- ✅ Admin announcements
- ✅ Professor broadcasts to class
- ✅ Department/Level notifications
- ✅ Welcome messages to new users
- ✅ Immediate notification when task is assigned (by professor)

### **Key Features**

- 🌐 **Requires internet** - Server-to-device communication
- 🎯 **Targeted** - Send to specific users/groups/departments
- 💬 **Dynamic content** - Content comes from server
- 🚀 **Real-time** - Immediate delivery
- 📲 **Multi-user** - Broadcast to many users at once

### **How It Works**

```
1. Admin/Professor initiates notification
          ↓
2. Backend Cloud Function sends FCM message
          ↓
3. Firebase delivers to user's device
          ↓
4. Device shows notification (even if app closed)
          ↓
5. Tap notification → App opens to relevant screen
```

### **Background Operation - YES!**

FCM notifications also work in background:

- App closed: ✅ Works
- App in background: ✅ Works
- App in foreground: ✅ Works (converted to local notification)

**How we handle FCM in different states:**

1. **Foreground** - App is open:

   ```dart
   FirebaseMessaging.onMessage.listen((message) {
     // Convert to local notification for display
     LocalNotificationService.instance.sendImmediateNotification(...);
   });
   ```

2. **Background** - App is closed/minimized:

   ```dart
   @pragma('vm:entry-point')
   Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
     // Show local notification
     await LocalNotificationService.instance.sendImmediateNotification(...);
   }
   ```

3. **Terminated** - App was force-closed:
   ```dart
   FirebaseMessaging.instance.getInitialMessage().then((message) {
     if (message != null) {
       NotificationController.handleFCMNotificationTap(message.data);
     }
   });
   ```

### **Code Implementation**

**File:** `lib/services/notification_trigger_service.dart`

**Send Announcement:**

```dart
await NotificationTriggerService().sendAnnouncement(
  'عطلة رسمية',
  'تذكير: غداً عطلة رسمية، لا توجد محاضرات',
  targetUserIds: ['user1', 'user2'], // or null for all users
);
```

**Send Department Notification:**

```dart
await NotificationTriggerService().sendDepartmentNotification(
  'Computer Science',
  'إعلان مهم',
  'اجتماع لطلاب علوم الحاسب غداً الساعة 10 صباحاً',
);
```

~~**Send Welcome Notification:**~~ (DISABLED)

**Note:** Welcome notifications via FCM have been disabled because:

- User is already in the app during signup
- FCM token may not be ready yet at signup time
- Redundant to notify someone actively using the app

### **Cloud Function**

**File:** `functions/main.py`

```python
@https_fn.on_request(cors=options.CorsOptions(cors_origins="*"))
def send_notification(req: https_fn.Request) -> https_fn.Response:
    # Validate request
    # Send FCM message
    # Handle errors
```

---

## 🔄 Complete Flow Examples

### Example 1: Task Created by Professor

```
┌─────────────────────────────────────────┐
│  Professor creates task for students    │
└──────────────┬──────────────────────────┘
               │
               ├─ IMMEDIATE: FCM Push Notification
               │  "تاسك جديد تم إضافته"
               │  (via NotificationTriggerService)
               │
               └─ SCHEDULED: Local Notifications
                  • 3 days before: "تذكير مبكر"
                  • 1 day before: "تذكير قريب"
                  • Due day morning: "تاسك اليوم"
                  • Due day evening: "تذكير أخير"
                  • Overdue: "تاسك متأخر!"
                  (via LocalNotificationService)
```

### Example 2: User Creates Schedule

```
┌─────────────────────────────────────────┐
│  User adds class to schedule            │
└──────────────┬──────────────────────────┘
               │
               └─ SCHEDULED: Local Notification
                  Every week, 15 min before class
                  "محاضرة قريبة - تبدأ خلال 15 دقيقة"
                  (via LocalNotificationService)
```

### Example 3: Admin Announcement

```
┌─────────────────────────────────────────┐
│  Admin sends announcement               │
└──────────────┬──────────────────────────┘
               │
               └─ IMMEDIATE: FCM Push to All
                  "إعلان: عطلة غداً"
                  (via NotificationTriggerService)
```

---

## 🔐 Logout Handling

When user logs out, **BOTH** systems are cleaned up:

**File:** `lib/services/logout_service.dart`

```dart
Future<void> logout() async {
  // 1. Invalidate FCM token in Firestore
  await _firestore.collection('users').doc(userId).update({
    'fcmToken': FieldValue.delete(),
    'tokenStatus': 'logged_out',
  });

  // 2. Delete local FCM token
  await FCMTokenManager().deleteLocalToken();

  // 3. Cancel ALL local notifications
  await AwesomeNotifications().cancelAll();

  // 4. Clear session & cache
  await SessionPersistenceService().clearSession();
  await CacheService.instance.clearUserCache(userId);

  // 5. Sign out from Firebase
  await _auth.signOut();
}
```

This ensures:

- ✅ No FCM push notifications received after logout
- ✅ No local scheduled notifications fire after logout
- ✅ Next user doesn't see previous user's notifications

---

## 🎯 Notification Tap Handling

**File:** `lib/services/notification_controller.dart`

When user taps a notification:

```dart
static Future<void> onActionReceivedMethod(ReceivedAction action) async {
  final payload = action.payload ?? {};
  final type = payload['type'] ?? '';

  switch (type) {
    case 'task_reminder':
      _navigateToTasks();
      break;
    case 'class_reminder':
      _navigateToSchedule();
      break;
    case 'announcement':
      _navigateToAnnouncements();
      break;
  }
}
```

---

## 📊 Decision Matrix

| Scenario                | System                              | Why                    |
| ----------------------- | ----------------------------------- | ---------------------- |
| Task due in 3 days      | Local                               | Scheduled, predictable |
| Class in 15 minutes     | Local                               | Time-based, recurring  |
| Admin announces exam    | FCM                                 | Dynamic, from server   |
| Professor assigns task  | FCM (immediate) + Local (reminders) | Both!                  |
| Welcome new student     | FCM                                 | Server-initiated       |
| Department announcement | FCM                                 | Multi-user broadcast   |
| User sets own reminder  | Local                               | User-specific, offline |

---

## ✅ Best Practices

### DO ✅

- Use Local for scheduled, user-specific reminders
- Use FCM for server-initiated, dynamic content
- Clean up notifications on logout
- Handle notification taps properly
- Request permissions at appropriate times
- Test both foreground and background states

### DON'T ❌

- Don't use FCM for scheduled reminders (use Local)
- Don't use Local for server broadcasts (use FCM)
- Don't leave notifications after logout
- Don't schedule too many notifications (rate limiting)
- Don't ignore permission requests

---

## 🐛 Troubleshooting

### Local Notifications Not Working

1. **Check permissions:**

   ```dart
   final allowed = await AwesomeNotifications().isNotificationAllowed();
   ```

2. **Check if notification was scheduled:**

   ```dart
   final scheduled = await LocalNotificationService.instance
       .getScheduledNotificationsInfo();
   print('Scheduled: ${scheduled['count']}');
   ```

3. **Verify time is in future:**

   - Notifications scheduled in the past won't fire

4. **Check Android settings:**
   - Settings → Apps → Pivot → Notifications → Enabled

### FCM Notifications Not Working

1. **Check token exists:**

   ```dart
   final token = await NotificationService().getToken();
   print('FCM Token: $token');
   ```

2. **Check token in Firestore:**

   - `users/{uid}/fcmToken` should exist and be valid

3. **Check internet connection:**

   - FCM requires internet

4. **Check Cloud Function logs:**
   - Firebase Console → Functions → Logs

---

## 📝 Files Reference

**Core Services:**

- `lib/services/local_notification_service.dart` - Local notifications
- `lib/services/notification_service_mobile.dart` - FCM for mobile
- `lib/services/notification_trigger_service.dart` - FCM triggers
- `lib/services/notification_controller.dart` - Tap handling
- `lib/services/fcm_token_manager.dart` - Token management
- `lib/services/logout_service.dart` - Cleanup on logout

**Usage:**

- `lib/features/tasks/services/task_service.dart` - Task notifications
- `lib/features/schedule/services/schedule_service.dart` - Class notifications

**Backend:**

- `functions/main.py` - FCM Cloud Function
- `android/app/src/main/AndroidManifest.xml` - Android permissions

---

## 🎓 Summary

**Two systems, clear purposes:**

```
┌──────────────────────────────────────────────────────────┐
│             LOCAL NOTIFICATIONS                          │
│  AwesomeNotifications                                    │
│  • Scheduled reminders                                   │
│  • Works offline                                         │
│  • Works in background                                   │
│  • User-specific                                         │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│             FCM PUSH NOTIFICATIONS                        │
│  Firebase Cloud Messaging                                │
│  • Server-initiated                                      │
│  • Requires internet                                     │
│  • Works in background                                   │
│  • Multi-user broadcasts                                 │
└──────────────────────────────────────────────────────────┘
```

**Both cleaned up on logout!** ✅
