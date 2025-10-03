## Database Usage by Phases

This document captures how Firestore and Firebase Auth are used in each migration phase.

### Phase 1 — Auth (Login/Registration)

- Services: `AuthService` uses Firebase Auth and Firestore.
- Repositories: `AuthRepository` wraps `AuthService`.
- Collections/Docs:
  - `users/{uid}`: User profile document with fields (example):
    - `id: string`
    - `name: string`
    - `email: string`
    - `department: string`
    - `level: string`
    - `section: string`
    - `profileImageUrl: string?`
    - `userNumber: int`
    - `gender: string`
    - `createdAt: serverTimestamp`
- Operations:
  - Read `users/{uid}` on login to hydrate `UserProfile`.
  - Write `users/{uid}` on registration with generated `userNumber` and `createdAt`.
  - Additional registration metadata captured in-memory (e.g., `registrationDate`) prior to profile write.

### Phase 2 — Onboarding (Introduction & First Run)

- Services: `OnboardingService` uses SharedPreferences for local storage.
- Repositories: `OnboardingRepository` wraps `OnboardingService`.
- Local Storage Keys:
  - `first_run_completed`: Boolean flag for first run completion
  - `intro_shown`: Boolean flag for introduction video completion
  - `pending_deep_link`: String for storing deep links during onboarding
- Operations:
  - Read/write first run status to determine if user needs onboarding
  - Read/write intro shown status to determine if user needs introduction
  - Read/write pending deep links for post-onboarding navigation
  - Clear pending deep links after successful navigation

### Phase 3 — Home/Landing (Dashboard)

- Services: `HomeService` aggregates CategoryService and UpdateService.
- Repositories: `HomeRepository` wraps `HomeService`.
- Data Sources:
  - CategoryService: Department-based category filtering and time filters
  - UpdateService: App update checks and team formation settings
  - UserProfile: Department information for category determination
- Operations:
  - Load categories based on user department
  - Get department codes and time filters for announcements
  - Check for app updates and team formation availability
  - Manage category navigation state

### Phase 4 — Profile (View/Edit/Profile Widgets)

- Services: `ProfileService` aggregates AuthService, LocalAuthService, NotificationService, and CacheService.
- Repositories: `ProfileRepository` wraps `ProfileService`.
- Data Sources:
  - AuthService: User profile management, password changes, profile image updates
  - LocalAuthService: Biometric authentication settings
  - NotificationService: Notification preferences and settings
  - CacheService: Cache management and cleanup
- Operations:
  - Load and update user profile information
  - Change password and update profile image
  - Manage biometric authentication settings
  - Update notification preferences
  - Clear cache and handle logout
  - Manage profile state (loading, updating, error handling)

### Phase 5 — Subjects (Selection, Listing, Details)

- Services: `SubjectsService` aggregates SubjectService, PaginationService, and CacheService.
- Repositories: `SubjectsRepository` wraps `SubjectsService`.
- Data Sources:
  - SubjectService: Subject CRUD operations, user enrollment, filtering, and search
  - PaginationService: Paginated subject loading for performance
  - CacheService: Subject caching for offline access and performance
- Operations:
  - Load all subjects with caching support
  - Search and filter subjects by query, year, department, level
  - Enroll/unenroll users from subjects
  - Update user subject selections
  - Get available years, departments, and levels for filtering
  - Paginated loading for large subject lists
  - Cache management for subjects

### Phase 6 — Administration (Users, Sections, Global Subjects)

- Services: `AdministrationService` aggregates AuthService, SubjectService, DataDeletionService, StorageOptimizationService, and NotificationService.
- Repositories: `AdministrationRepository` wraps `AdministrationService`.
- Data Sources:
  - AuthService: User management, role updates, user deletion
  - SubjectService: Subject CRUD operations, subject management
  - DataDeletionService: User data deletion and cleanup
  - StorageOptimizationService: Storage statistics and optimization
  - NotificationService: User notifications and bulk messaging
- Operations:
  - User Management: Create, read, update, delete users; role management; bulk operations
  - Subject Management: CRUD operations for subjects; year-based filtering
  - Data Management: User data deletion; bulk data cleanup
  - Storage Management: Storage statistics; cache optimization; storage cleanup
  - Notification Management: Send notifications to users; bulk messaging
  - Search and Filter: User and subject search; role-based filtering; year-based filtering
  - Selection Management: Multi-select users and subjects; bulk operations

### Phase 7 — Administration: Notifications & Feedback

- Services: `NotificationsService` aggregates NotificationService, LocalNotificationService, NotificationTriggerService, NotificationTestService, and FCMTokenManager. `FeedbackService` handles feedback operations.
- Repositories: `NotificationsRepository` wraps `NotificationsService`. `FeedbackRepository` wraps `FeedbackService`.
- Data Sources:
  - NotificationService: FCM token management, notification sending, token statistics
  - LocalNotificationService: Local notification scheduling and management
  - NotificationTriggerService: Automatic notification triggers and batch processing
  - NotificationTestService: Notification system testing and diagnostics
  - FCMTokenManager: FCM token lifecycle management
  - FeedbackService: Feedback submission, image upload, status management
- Collections/Docs:
  - `scheduledNotifications/{id}`: Scheduled notification documents with fields:
    - `title: string`
    - `body: string`
    - `scheduledTime: timestamp`
    - `createdAt: timestamp`
    - `createdBy: string`
    - `createdByName: string`
    - `targetUserIds: array`
    - `sendToAllUsers: boolean`
    - `status: string` (pending, sent, failed)
    - `sentCount: number?`
    - `totalCount: number?`
    - `errorMessage: string?`
    - `updatedAt: timestamp?`
  - `feedback/{id}`: Feedback documents with fields:
    - `userId: string`
    - `userName: string`
    - `userEmail: string`
    - `category: string`
    - `feedback: string`
    - `imageUrl: string?`
    - `timestamp: serverTimestamp`
    - `status: string` (pending, resolved, rejected)
    - `updatedAt: timestamp?`
  - `users/{uid}/notifications/{id}`: User notification documents with fields:
    - `title: string`
    - `body: string`
    - `createdAt: timestamp`
    - `isRead: boolean`
    - `data: object?`
- Operations:
  - Notification Management: Send immediate notifications, create scheduled notifications, execute scheduled notifications, get notification statistics
  - Feedback Management: Submit feedback, upload feedback images, get feedback by status/category, update feedback status, delete feedback, get feedback statistics
  - User Notifications: Get user notifications, mark notifications as read, get unread count
  - Token Management: Get FCM tokens, cleanup invalid tokens, refresh tokens, get token statistics
  - Testing: Test notification system, get test results, validate notification components

### Phase 8 — Super Admin & Analytics

- Services: `SuperAdminService` handles admin operations and user statistics. `AnalyticsService` handles analytics and reporting operations.
- Repositories: `SuperAdminRepository` wraps `SuperAdminService`. `AnalyticsRepository` wraps `AnalyticsService`.
- Data Sources:
  - SuperAdminService: User statistics, dashboard data, system statistics, department/level analytics
  - AnalyticsService: User analytics, content analytics, engagement analytics, growth analytics, system health analytics
- Collections/Docs:
  - `users/{uid}`: User documents with fields:
    - `role: string` (Super Admin, Admin, Professor, miniProfessor, Student)
    - `department: string`
    - `level: string`
    - `gender: string` (ذكر, أنثى, غير محدد)
    - `createdAt: timestamp`
    - `lastActiveAt: timestamp?`
  - `subjects/{id}`: Subject documents for content analytics
  - `announcements/{id}`: Announcement documents for content analytics
  - `tasks/{id}`: Task documents for content analytics
  - `feedback/{id}`: Feedback documents for content analytics
- Operations:
  - Dashboard Data: Fetch user statistics, role distribution, department/level/gender stats, new users metrics
  - User Analytics: Get user distribution, active users, engagement metrics, growth rates
  - Content Analytics: Analyze announcements, subjects, tasks, feedback counts and activity
  - Engagement Analytics: Calculate user activity levels, engagement rates, inactive users
  - Growth Analytics: Track user growth over time, calculate growth rates, compare periods
  - System Health: Monitor collection sizes, system performance, data integrity
  - Statistics: Get top departments, top levels, available departments/levels, system metrics

### Phase 9 — Media: PDF/Video & Materials

- Services: `MediaService` handles PDF/Video operations and URL validation. `MaterialsService` handles materials management and analytics.
- Repositories: `MediaRepository` wraps `MediaService`. `MaterialsRepository` wraps `MaterialsService`.
- Data Sources:
  - MediaService: URL validation, YouTube video ID extraction, browser launching, material type detection
  - MaterialsService: Materials fetching, searching, statistics, CRUD operations
- Collections/Docs:
  - `lectures/{id}`: Lecture documents with fields:
    - `links: array` (MaterialLink objects with fields):
      - `title: string`
      - `url: string`
      - `thumbnail: string?`
      - `description: string?`
      - `type: string` (video, pdf, document, image, link)
      - `metadata: object`
      - `createdAt: timestamp`
      - `lastAccessed: timestamp?`
      - `userRatings: object`
      - `totalRatings: number`
      - `averageRating: number`
- Operations:
  - Media Operations: Open PDF/video/image in browser, validate URLs, extract YouTube video IDs, get embed URLs, detect material types
  - Materials Management: Get all materials, filter by type/lecture/subject/doctor, search materials, get statistics
  - Materials Analytics: Get recent materials, popular materials, materials by lecture, materials statistics
  - Materials CRUD: Add material to lecture, remove material from lecture, update material in lecture
  - URL Processing: Validate video/PDF/image URLs, extract metadata, create MaterialLink objects

### Phase 10 — Teams & Tasks

- Services: `TeamsService` handles team member operations and analytics. `TasksService` handles task operations and management.
- Repositories: `TeamsRepository` wraps `TeamsService`. `TasksRepository` wraps `TasksService`.
- Data Sources:
  - TeamsService: Team member management, team statistics, skill analytics, team formation
  - TasksService: Task management, task statistics, task filtering, task completion tracking
- Collections/Docs:
  - `team_members/{id}`: Team member documents with fields:
    - `name: string`
    - `skills: array<string>`
    - `previousProjects: array<string>`
    - `purpose: string`
    - `whatsappNumber: string`
    - `linkedinProfile: string?`
    - `userId: string`
    - `createdAt: timestamp`
    - `teamName: string`
  - `users/{uid}/tasks/{id}`: Task documents with fields:
    - `id: string`
    - `title: string`
    - `description: string`
    - `dueDate: timestamp`
    - `importance: string` (high, mid, low)
    - `subjectId: string?`
    - `sectionId: string?`
    - `assistantId: string?`
    - `completedBy: array<string>`
    - `isPersonal: boolean`
    - `attachments: array<object>?`
- Operations:
  - Team Operations: Get all team members, get by team name, get by skills, search team members, add/update/delete team members
  - Team Analytics: Get team statistics, get available team names, get available skills, get team member counts
  - Task Operations: Get all tasks, get by section/subject/importance, get personal/completed/pending/overdue tasks, get tasks due today
  - Task Management: Add/update/delete tasks, mark as completed/not completed, search tasks, get task statistics
  - Task Filtering: Filter by date range, bulk update/delete tasks, local filtering by various criteria
  - Team Formation: Check if user is team member, get team member by user ID, team member validation

### Phase 11 — Settings, Bookmarks, Schedule, Notifications

- Services: `SettingsService` handles user settings and preferences. `BookmarksService` handles bookmark operations. `ScheduleService` handles schedule management. `UserNotificationsService` handles notification operations.
- Repositories: `SettingsRepository` wraps `SettingsService`. `BookmarksRepository` wraps `BookmarksService`. `ScheduleRepository` wraps `ScheduleService`. `UserNotificationsRepository` wraps `UserNotificationsService`.
- Data Sources:
  - SettingsService: User settings management, notification preferences, app settings, privacy settings, display settings, local preferences
  - BookmarksService: Bookmark management, bookmark search, bookmark statistics, bookmark export/import
  - ScheduleService: Schedule management, schedule items, schedule statistics, schedule export/import
  - UserNotificationsService: Notification management, notification preferences, notification statistics
- Collections/Docs:
  - `users/{uid}`: User documents with fields:
    - `notificationPreferences: object` (taskReminders, classReminders, announcements, departmentNotifications, levelNotifications, maxNotificationsPerHour, welcomeNotification)
    - `appSettings: object` (theme, language, fontSize, autoSync, offlineMode, cacheSize)
    - `privacySettings: object` (profileVisibility, contactSharing, dataSharing)
    - `displaySettings: object` (fontSize, theme, language, accessibility)
    - `bookmarks: array<string>` (bookmarked item IDs)
    - `lastUpdated: timestamp`
  - `users/{uid}/schedule/{id}`: Schedule item documents with fields:
    - `id: string`
    - `title: string`
    - `time: string`
    - `location: string`
    - `day: string`
    - `type: string` (lecture, section)
    - `notificationEnabled: boolean`
    - `order: number`
  - `notifications/{id}`: Notification documents with fields:
    - `title: string`
    - `body: string`
    - `scheduledTime: timestamp`
    - `createdAt: timestamp`
    - `createdBy: string`
    - `createdByName: string`
    - `targetUserIds: array<string>`
    - `sendToAllUsers: boolean`
    - `department: string?`
    - `level: string?`
    - `status: string` (pending, sent, cancelled, failed)
    - `sentCount: number?`
    - `totalCount: number?`
    - `errorMessage: string?`
    - `sentAt: timestamp?`
    - `additionalData: object?`
- Operations:
  - Settings Operations: Get/update user settings, get/update local preferences, reset to defaults, export/import settings, validate settings
  - Bookmarks Operations: Get user bookmarks, add/remove bookmarks, toggle bookmarks, search bookmarks, get bookmarks by type, clear all bookmarks
  - Schedule Operations: Get user schedule, get schedule for day, add/update/remove schedule items, toggle notifications, search schedule items, get upcoming items
  - Notifications Operations: Get user notifications, get unread notifications, mark as read, delete notifications, search notifications, get notifications by type/date range
  - Statistics: Get settings statistics, get bookmarks statistics, get schedule statistics, get notification statistics
  - Export/Import: Export settings, export bookmarks, export schedule, import settings, import bookmarks, import schedule

Planned next phases will append their collections and operations here.
