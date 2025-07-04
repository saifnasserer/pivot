rules_version = '2';
service cloud.firestore {
match /databases/{database}/documents {

    // Users + subcollections (notifications + schedule)
    match /users/{userId} {
      allow read, write: if request.auth != null && (
        request.auth.uid == userId ||
        request.auth.token.role in ['Admin', 'Super Admin'] ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );

      match /notifications/{notificationId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /schedule/{scheduleItemId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Announcements
    match /announcements/{announcementId} {
      allow read: if true;
      allow write: if request.auth != null && (
        request.auth.token.role in ['Admin', 'Super Admin', 'Professor', 'miniProfessor'] ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
      allow update, delete: if request.auth != null && (
        request.auth.uid == resource.data.createdBy ||
        request.auth.token.role == 'Super Admin' ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'Super Admin'
      );
    }

    // Subjects
    match /subjects/{subjectId} {
      allow read: if true;
      allow write: if request.auth != null && (
        request.auth.token.role in ['Admin', 'Super Admin'] ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
    }

    // Sections
    match /sections/{sectionId} {
      allow read: if true;
      allow write: if request.auth != null && (
        request.auth.token.role in ['Admin', 'Super Admin'] ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
    }

    // Tasks
    match /tasks/{taskId} {
      allow read, write: if request.auth != null && (
        request.auth.uid == resource.data.ownerId ||
        (request.auth.token.role in ['Professor', 'miniProfessor'] &&
         resource.data.subjectId in request.auth.token.teachingSubjects) ||
        request.auth.token.role in ['Admin', 'Super Admin'] ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
    }

    // Scheduled Notifications
    match /scheduledNotifications/{notificationId} {
      allow read, write: if request.auth != null && (
        request.auth.uid in resource.data.targetUserIds ||
        request.auth.uid in request.resource.data.targetUserIds ||
        request.auth.token.role in ['Admin', 'Super Admin'] ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
    }

    // Teams
    match /teams/{teamId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null && (
        request.auth.token.role in ['Admin', 'Super Admin'] ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
    }

    // Team Members
    match /team_members/{memberId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth != null && (
        request.auth.uid == resource.data.userId ||
        request.auth.token.role in ['Admin', 'Super Admin'] ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
      );
    }

    // Bookmarks (لو عندك collection اسمها bookmarks)
    match /bookmarks/{bookmarkId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create, update, delete: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }

    // User management (لو موجود عندك)
    match /userManagement/{docId} {
      allow read, write: if request.auth != null && (
        request.auth.token.role == 'Super Admin' ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'Super Admin'
      );
    }

match /scheduledNotifications/{notificationId} {
allow read, write: if request.auth != null && (
request.auth.uid in resource.data.targetUserIds ||
request.auth.uid in request.resource.data.targetUserIds ||
request.auth.token.role in ['Admin', 'Super Admin'] ||
get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
);
}

// Schedules (top-level)
match /schedules/{scheduleId} {
allow read, write: if request.auth != null && (
// Allow the user who owns the schedule
request.auth.uid == resource.data.userId ||
request.auth.uid == request.resource.data.userId ||
// Allow admins and super admins
request.auth.token.role in ['Admin', 'Super Admin'] ||
get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
);
}

match /users/{userId}/schedule/{scheduleItemId} {
allow read, write: if request.auth != null && (
request.auth.uid == userId ||
(request.auth.token.role in ['Admin', 'Super Admin'])
);
}

match /databases/{database}/documents {
match /{document=**} {
allow read, write: if true;
}
}
// Default deny
match /{document=**} {
allow read, write: if false;
}
}
}
