rules_version = '2';
service cloud.firestore {
match /databases/{database}/documents {

    // ===== Helper Functions =====
    function isSignedIn() {
      return request.auth != null;
    }

    function isUser(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }

    function hasRole(roles) {
      return isSignedIn() &&
        (
          request.auth.token.role in roles ||
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in roles
        );
    }

    function isAdmin() {
      return hasRole(['Admin', 'Super Admin']);
    }

    function isProfessor() {
      return hasRole(['Professor', 'miniProfessor', 'Admin', 'Super Admin']);
    }

    function isInTargetList(targetList) {
      return isSignedIn() && (
        request.auth.uid in targetList || isAdmin()
      );
    }

    // ===== USERS =====
    match /users/{userId} {
      allow read: if request.auth != null;
      allow update, delete: if (request.auth != null && request.auth.uid == userId) || isAdmin();
      allow create: if isSignedIn() || isAdmin();

      match /tasks/{taskId} {
        allow read, write: if isUser(userId);
      }

      match /schedule/{scheduleItemId} {
        allow read, write: if isUser(userId);
      }

      match /notifications/{notificationId} {
        allow read, write: if isUser(userId);
      }
    }

    // ===== FEEDBACK =====
    match /feedback/{feedbackId} {
      allow read, update: if isAdmin();
      allow create: if isSignedIn();
    }

    // ===== ANNOUNCEMENTS =====
    match /announcements/{announcementId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();

      match /comments/{commentId} {
        allow read, create: if isSignedIn();
        allow update, delete: if isSignedIn() && (
          request.auth.uid == resource.data.userId || isAdmin()
        );
      }
    }

    // ===== GUIDE CONTENT =====
    match /guide_content/{docId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // ===== LECTURES =====
    match /lectures/{lectureId} {
      allow read: if isSignedIn();
      allow write: if isProfessor();
    }

    // ===== SCHEDULED NOTIFICATIONS =====
    match /scheduledNotifications/{notificationId} {
      // Allow read for:
      // 1. Users who are targets of the notification
      // 2. Admins and Super Admins
      // 3. System queries for automated notification processing
      allow read: if request.auth != null && (
        request.auth.uid in resource.data.targetUserIds ||
        request.auth.token.role in ['Admin', 'Super Admin'] ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin'] ||
        // Allow system queries for automated notification processing
        resource.data.status == 'pending'
      );

      // Allow write for:
      // 1. When creating/updating and user is in targetUserIds
      // 2. Admins and Super Admins
      // 3. System updates for notification status changes
      allow write: if request.auth != null && (
        (exists(/databases/$(database)/documents/users/$(request.auth.uid)) && (
          request.auth.uid in request.resource.data.targetUserIds ||
          request.auth.token.role in ['Admin', 'Super Admin'] ||
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'Super Admin']
        )) ||
        // Allow system to update notification status
        (resource != null && resource.data.status in ['pending', 'sent', 'failed'])
      );
    }

    // ===== SECTIONS =====
    match /sections/{sectionId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // ===== SETTINGS =====
    match /settings/{docId} {
      allow read: if true; // Public read access
      allow write: if isAdmin();
    }

    // ===== SUBJECTS =====
    match /subjects/{subjectId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // ===== TEAMS =====
    match /teams/{teamId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // ===== TEAM MEMBERS =====
    match /team_members/{memberId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // ===== DEFAULT DENY =====
    match /{document=**} {
      allow read, write: if false;
    }

}
}
