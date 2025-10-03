# TODO Implementation Plan

**Generated:** October 3, 2025  
**Total TODOs Found:** 36 items across the codebase

This document lists all TODO items in the application, organized from easiest to hardest to implement.

---

## 🟢 **Level 1: Easy** (Quick Wins - 1-2 hours each)

### 1. Open URL in Browser

**File:** `lib/features/administration/screens/doctor/profile/social_media_widget.dart:217`  
**Effort:** 30 minutes  
**Description:** Add URL launcher functionality for social media links.  
**Implementation:**

- Import `url_launcher` package (already in dependencies)
- Use `launchUrl()` method to open URLs
- Add error handling for invalid URLs

**Code Location:**

```dart
// Line 217: social_media_widget.dart
onPressed: () {
  // TODO: Open URL in browser
},
```

---

### 2. Clear Profile Using Riverpod (3 instances)

**Files:**

- `lib/features/onboarding/screens/auth_wrapper.dart:43`
- `lib/features/onboarding/screens/auth_wrapper.dart:84`
- `lib/features/onboarding/screens/auth_wrapper.dart:93`

**Effort:** 1 hour  
**Description:** Replace old profile clearing logic with Riverpod state management.  
**Implementation:**

- Use Riverpod's `ref.invalidate()` or `ref.refresh()` to clear profile state
- Ensure UserProfileProvider is properly invalidated on auth state changes
- Test logout flow to ensure profile is cleared

**Code Locations:**

```dart
// Lines 43, 84, 93: auth_wrapper.dart
// TODO: Clear profile using Riverpod
```

---

### 3. Initialize User Profile Using Riverpod

**File:** `lib/main.dart:194`  
**Effort:** 1 hour  
**Description:** Properly initialize user profile on app startup using Riverpod.  
**Implementation:**

- Use `ProviderScope` overrides or initialization logic
- Fetch user profile data on app start if authenticated
- Handle edge cases for offline mode

**Code Location:**

```dart
// Line 194: main.dart
// TODO: Initialize user profile using Riverpod
```

---

## 🟡 **Level 2: Medium** (Moderate complexity - 2-4 hours each)

### 4. Implement Fullscreen Functionality

**File:** `lib/features/media/screens/video_player_screen.dart:236`  
**Effort:** 2 hours  
**Description:** Add fullscreen mode for video player.  
**Implementation:**

- Toggle system UI overlays (status bar, navigation bar)
- Handle orientation changes (portrait ↔ landscape)
- Add fullscreen toggle button
- Ensure proper exit from fullscreen mode

**Code Location:**

```dart
// Line 236: video_player_screen.dart
// TODO: Implement fullscreen functionality
```

---

### 5. Implement PDF Download Functionality

**File:** `lib/features/media/screens/pdf_viewer_screen.dart:148`  
**Effort:** 2-3 hours  
**Description:** Allow users to download PDF files to device storage.  
**Implementation:**

- Use `file_picker` or `path_provider` for storage location
- Implement download progress indicator
- Handle permissions (Android storage permissions)
- Show success/failure notifications

**Code Location:**

```dart
// Line 148: pdf_viewer_screen.dart
// TODO: Implement PDF download functionality
```

---

### 6. Implement Rating Functionality

**File:** `lib/features/media/screens/material_links_screen.dart:659`  
**Effort:** 3 hours  
**Description:** Add rating system for educational materials.  
**Implementation:**

- Update MaterialsProvider to handle ratings
- Create Firestore structure for ratings (user-based)
- Add UI for rating display and interaction
- Calculate and display average ratings
- Prevent duplicate ratings from same user

**Code Location:**

```dart
// Line 659: material_links_screen.dart
// TODO: Implement rating functionality in MaterialsProvider
```

---

### 7. Integrate Notifications with LocalNotificationService

**File:** `lib/services/notification_service_mobile.dart:65`  
**Effort:** 2 hours  
**Description:** Connect FCM notifications with local notification display.  
**Implementation:**

- Use `LocalNotificationService` to show notifications
- Map FCM message data to local notification format
- Handle notification actions (tap, dismiss)
- Test foreground and background notification scenarios

**Code Location:**

```dart
// Line 65: notification_service_mobile.dart
// TODO: Integrate with LocalNotificationService to show the notification
```

---

## 🟠 **Level 3: Medium-Hard** (Complex features - 4-8 hours each)

### 8. Implement Sound Service

**Files:**

- `lib/features/tasks/services/task_service.dart:45`
- `lib/features/tasks/services/task_service.dart:100`

**Effort:** 4 hours  
**Description:** Add sound notifications for task actions (completion, reminders).  
**Implementation:**

- Create or extend SoundService class
- Use `audioplayers` package (already in dependencies)
- Load sound assets (correct.mp3, notification.mp3)
- Respect user preferences for sound on/off
- Handle audio playback errors gracefully

**Code Locations:**

```dart
// Lines 45, 100: task_service.dart
// TODO: Implement sound service
```

---

### 9. Implement Schedule Notification Services (5 instances)

**Files:**

- `lib/features/schedule/services/schedule_service.dart:84`
- `lib/features/schedule/services/schedule_service.dart:116`
- `lib/features/schedule/services/schedule_service.dart:147`
- `lib/features/schedule/services/schedule_service.dart:184`
- `lib/features/schedule/services/schedule_service.dart:199`

**Effort:** 6 hours  
**Description:** Add notification system for schedule events (classes, exams).  
**Implementation:**

- Create notification scheduling logic
- Use `awesome_notifications` package (already in dependencies)
- Schedule notifications for upcoming events
- Handle notification cancellation when events are modified/deleted
- Implement reminder preferences (15 min, 1 hour, 1 day before)
- Test notification reliability across app restarts

**Code Locations:**

```dart
// Lines 84, 116, 147, 184, 199: schedule_service.dart
// TODO: Implement notification services
```

---

### 10. Implement Task Notification Services (4 instances)

**Files:**

- `lib/features/tasks/services/task_service.dart:59`
- `lib/features/tasks/services/task_service.dart:73`
- `lib/features/tasks/services/task_service.dart:177`
- `lib/features/tasks/services/task_service.dart:191`

**Effort:** 5 hours  
**Description:** Add notification system for task deadlines and reminders.  
**Implementation:**

- Schedule notifications for task due dates
- Send reminders before deadlines
- Cancel notifications for completed tasks
- Handle recurring task notifications
- Implement notification actions (complete task, snooze)

**Code Locations:**

```dart
// Lines 59, 73, 177, 191: task_service.dart
// TODO: Implement notification services
```

---

### 11. Implement Task Notes Functionality (4 instances)

**Files:**

- `lib/features/tasks/services/task_service.dart:133`
- `lib/features/tasks/services/task_service.dart:143`
- `lib/features/tasks/services/task_service.dart:158`
- `lib/features/tasks/services/task_service.dart:162`

**Effort:** 5-6 hours  
**Description:** Add notes feature to tasks (add, update, view notes).  
**Implementation:**

- Update Task model to include notes array
- Create TaskNote model with properties (id, content, createdAt, updatedAt)
- Implement Firestore structure for notes storage
- Add UI for note creation, editing, and display
- Implement note deletion and editing logic
- Add timestamps and user tracking for notes

**Code Locations:**

```dart
// Lines 133, 143, 158, 162: task_service.dart
// TODO: Implement notes functionality
// TODO: Implement notes update
```

---

### 12. Implement Profile Image Upload

**File:** `lib/features/user/services/user_profile_service.dart:173`  
**Effort:** 4 hours  
**Description:** Enable users to upload and update profile pictures.  
**Implementation:**

- Uncomment and implement the StorageOptimizationService integration
- Add image compression before upload
- Generate unique filenames using timestamps
- Update user profile with new image URL
- Delete old profile image from storage
- Add loading state and error handling

**Code Location:**

```dart
// Line 173: user_profile_service.dart
// TODO: Implement image upload
// Commented code already exists, needs to be activated and tested
```

---

### 13. Implement Guide Image Upload

**File:** `lib/features/guide/services/guide_service.dart:118`  
**Effort:** 3-4 hours  
**Description:** Enable image uploads in guide creation/editing.  
**Implementation:**

- Use StorageOptimizationService for optimized uploads
- Support multiple image uploads for guides
- Implement image compression and resizing
- Add progress indicators for uploads
- Handle upload failures gracefully

**Code Location:**

```dart
// Line 118: guide_service.dart
// TODO: Implement image upload using StorageOptimizationService
```

---

### 14. Migrate SubjectProvider to Riverpod (5 instances)

**Files:**

- `lib/features/administration/screens/doctor/profile/doctor_profile.dart:128`
- `lib/features/administration/screens/assistants/profile/assistant_profile_main_new.dart:106`
- `lib/features/administration/screens/assistants/profile/assistant_profile_main.dart:106`
- `lib/features/administration/screens/assistants/profile/assistant_profile_main.dart:275`

**Effort:** 6-8 hours  
**Description:** Migrate legacy SubjectProvider to modern Riverpod state management.  
**Implementation:**

- Create new Riverpod provider for subjects
- Convert all Consumer widgets to ConsumerWidget/ConsumerStatefulWidget
- Replace Provider.of() calls with ref.watch()/ref.read()
- Update all dependent components
- Test thoroughly to ensure no regressions
- Remove old Provider implementation

**Code Locations:**

```dart
// Multiple files (doctor_profile.dart, assistant_profile_main*.dart)
// TODO: Migrate SubjectProvider to Riverpod
```

---

## 🔴 **Level 4: Hard** (Complex/Requires backend - 8+ hours)

### 15. Move Users Collection Fetch to Backend

**File:** `lib/services/storage_optimization_service.dart:312`  
**Effort:** 8-12 hours  
**Description:** Critical security fix - move users collection query to backend/Cloud Function.  
**Implementation:**

- Create Firebase Cloud Function for user data fetching
- Implement admin-only access controls
- Add authentication and authorization checks
- Update client-side code to call the function
- Implement pagination for large datasets
- Add comprehensive error handling
- Test security rules thoroughly
- Deploy and monitor function performance

**Code Location:**

```dart
// Line 312: storage_optimization_service.dart
// TODO: The following code fetches the entire users collection and should be
// moved to a backend/admin function for security and privacy reasons.
final users = await _firestore.collection('users').get();
```

**Security Concerns:**

- Current implementation exposes all user data to client
- Violates privacy principles
- Could lead to data leaks
- Should be restricted to admin-only backend operations

---

## 📊 **Implementation Summary**

| Priority Level | Count                    | Estimated Total Time |
| -------------- | ------------------------ | -------------------- |
| 🟢 Easy        | 3                        | 2.5 hours            |
| 🟡 Medium      | 4                        | 9-11 hours           |
| 🟠 Medium-Hard | 7                        | 43-51 hours          |
| 🔴 Hard        | 1                        | 8-12 hours           |
| **TOTAL**      | **15 groups (36 items)** | **62.5-76.5 hours**  |

---

## 🎯 **Recommended Implementation Order**

### Phase 1: Quick Wins (Week 1)

1. Open URL in browser
2. Clear profile using Riverpod
3. Initialize user profile using Riverpod

### Phase 2: User Experience (Week 2)

4. Implement fullscreen functionality
5. Implement PDF download
6. Implement rating functionality
7. Integrate local notifications

### Phase 3: Notifications & Sound (Week 3-4)

8. Implement sound service
9. Implement schedule notifications
10. Implement task notifications

### Phase 4: Feature Completion (Week 5-6)

11. Implement task notes functionality
12. Implement profile image upload
13. Implement guide image upload
14. Migrate SubjectProvider to Riverpod

### Phase 5: Security & Backend (Week 7)

15. Move users collection fetch to backend ⚠️ **CRITICAL SECURITY**

---

## ⚠️ **Critical Notes**

1. **Security Priority:** Item #15 (users collection fetch) should be prioritized despite complexity, as it poses a security risk.

2. **Testing Required:** All notification-related TODOs require extensive testing across:

   - App states (foreground, background, terminated)
   - Android versions
   - Permission scenarios

3. **Dependencies:** Some TODOs depend on others:

   - Image uploads require StorageOptimizationService to be fully functional
   - Notification TODOs should share common notification service architecture
   - Riverpod migration should be done before other state management changes

4. **Configuration:** Some TODOs reference moving values to Remote Config:
   - FCM server key (`fcm_token_manager.dart:16`)
   - Notification settings (`notification_service_mobile.dart:18`)

---

## 📝 **Notes**

- All notification implementations should use the existing `awesome_notifications` package
- Sound implementations should use the existing `audioplayers` package
- Image uploads should use the existing `StorageOptimizationService`
- All Riverpod migrations should follow the existing pattern in the codebase
- Consider creating reusable components for similar TODOs (e.g., notification helper)

---

**Last Updated:** October 3, 2025  
**Next Review:** After Phase 1 completion
