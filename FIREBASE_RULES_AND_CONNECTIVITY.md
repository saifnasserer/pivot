# Firestore Rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // USERS
    match /users/{userId} {
      // Allow all authenticated users to read any user document (for search, subject, and section features)
      allow read: if request.auth != null;
      // Only allow the user to update/delete their own document
      allow update, delete: if request.auth != null && request.auth.uid == userId;
      // Allow any authenticated user to create their own document
      allow create: if request.auth != null;

      // SUBCOLLECTION: TASKS
      match /tasks/{taskId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      // SUBCOLLECTION: SCHEDULE
      match /schedule/{scheduleItemId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      // SUBCOLLECTION: NOTIFICATIONS
      match /notifications/{notificationId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // FEEDBACK
    match /feedback/{feedbackId} {
      allow read, update: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
      allow create: if request.auth != null;
    }

    // ANNOUNCEMENTS
    match /announcements/{announcementId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
      // SUBCOLLECTION: COMMENTS
      match /comments/{commentId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
        allow update, delete: if request.auth != null && (
          resource.data.authorId == request.auth.uid || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
        );
      }
    }

    // GUIDE CONTENT
    match /guide_content/{docId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
    }

    // LECTURES
    match /lectures/{lectureId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin', 'Professor', 'miniProfessor']
      );
    }

    // SCHEDULED NOTIFICATIONS
    match /scheduledNotifications/{notificationId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
    }

    // SECTIONS
    match /sections/{sectionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin', 'Professor', 'miniProfessor']
      );
    }

    // SETTINGS
    match /settings/{settingId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
    }

    // SUBJECTS
    match /subjects/{subjectId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin', 'Professor', 'miniProfessor']
      );
    }

    // TEAMS
    match /teams/{teamId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin', 'Professor', 'miniProfessor']
      );
    }

    // TEAM MEMBERS
    match /team_members/{memberId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin', 'Professor', 'miniProfessor']
      );
    }

    // DEFAULT DENY
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```
