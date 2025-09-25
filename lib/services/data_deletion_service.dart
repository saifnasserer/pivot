import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:pivot/models/user_profile.dart';

class DataDeletionService {
  static final DataDeletionService _instance = DataDeletionService._internal();
  factory DataDeletionService() => _instance;
  DataDeletionService._internal();

  /// Deletes all user data from the system
  /// Returns true if successful, false otherwise
  static Future<bool> deleteAllUserData(String userId) async {
    try {
      if (kDebugMode) {
        print('[DataDeletion] Starting deletion for user: $userId');
      }

      // Delete user data in parallel for better performance
      final results = await Future.wait([
        _deleteUserProfile(userId),
        _deleteUserPosts(userId),
        _deleteUserComments(userId),
        _deleteUserNotifications(userId),
        _deleteUserSchedule(userId),
        _deleteUserTasks(userId),
        _deleteUserAnnouncements(userId),
        _deleteUserFiles(userId),
        _deleteUserImages(userId),
        _deleteUserSettings(userId),
        _deleteUserBlockedUsers(userId),
        _deleteUserReports(userId),
      ]);

      // Check if all deletions were successful
      final allSuccessful = results.every((result) => result == true);

      if (kDebugMode) {
        print('[DataDeletion] Deletion completed. Success: $allSuccessful');
      }

      return allSuccessful;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error during deletion: $e');
      }
      return false;
    }
  }

  /// Delete user profile from Firestore
  static Future<bool> _deleteUserProfile(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      if (kDebugMode) {
        print('[DataDeletion] User profile deleted: $userId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user profile: $e');
      }
      return false;
    }
  }

  /// Delete all user posts
  static Future<bool> _deleteUserPosts(String userId) async {
    try {
      // Delete posts where user is the author
      final postsQuery =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('authorId', isEqualTo: userId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in postsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (kDebugMode) {
        print('[DataDeletion] User posts deleted: ${postsQuery.docs.length}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user posts: $e');
      }
      return false;
    }
  }

  /// Delete all user comments
  static Future<bool> _deleteUserComments(String userId) async {
    try {
      // Delete comments where user is the author
      final commentsQuery =
          await FirebaseFirestore.instance
              .collection('comments')
              .where('authorId', isEqualTo: userId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in commentsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (kDebugMode) {
        print(
          '[DataDeletion] User comments deleted: ${commentsQuery.docs.length}',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user comments: $e');
      }
      return false;
    }
  }

  /// Delete all user notifications
  static Future<bool> _deleteUserNotifications(String userId) async {
    try {
      // Delete notifications for this user
      final notificationsQuery =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in notificationsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (kDebugMode) {
        print(
          '[DataDeletion] User notifications deleted: ${notificationsQuery.docs.length}',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user notifications: $e');
      }
      return false;
    }
  }

  /// Delete user schedule data
  static Future<bool> _deleteUserSchedule(String userId) async {
    try {
      // Delete user schedule
      final scheduleQuery =
          await FirebaseFirestore.instance
              .collection('schedules')
              .where('userId', isEqualTo: userId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in scheduleQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (kDebugMode) {
        print(
          '[DataDeletion] User schedule deleted: ${scheduleQuery.docs.length}',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user schedule: $e');
      }
      return false;
    }
  }

  /// Delete user tasks
  static Future<bool> _deleteUserTasks(String userId) async {
    try {
      // Delete user tasks
      final tasksQuery =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('userId', isEqualTo: userId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in tasksQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (kDebugMode) {
        print('[DataDeletion] User tasks deleted: ${tasksQuery.docs.length}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user tasks: $e');
      }
      return false;
    }
  }

  /// Delete user announcements
  static Future<bool> _deleteUserAnnouncements(String userId) async {
    try {
      // Delete announcements created by user
      final announcementsQuery =
          await FirebaseFirestore.instance
              .collection('announcements')
              .where('authorId', isEqualTo: userId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in announcementsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (kDebugMode) {
        print(
          '[DataDeletion] User announcements deleted: ${announcementsQuery.docs.length}',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user announcements: $e');
      }
      return false;
    }
  }

  /// Delete user files from Firebase Storage
  static Future<bool> _deleteUserFiles(String userId) async {
    try {
      // Delete user files from storage
      final storageRef = FirebaseStorage.instance.ref().child('users/$userId');

      try {
        final listResult = await storageRef.listAll();

        // Delete all files
        for (var item in listResult.items) {
          await item.delete();
        }

        // Delete all folders
        for (var folder in listResult.prefixes) {
          await folder.delete();
        }
      } catch (e) {
        // Folder might not exist, which is fine
        if (kDebugMode) {
          print('[DataDeletion] No files to delete for user: $userId');
        }
      }

      if (kDebugMode) {
        print('[DataDeletion] User files deleted from storage');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user files: $e');
      }
      return false;
    }
  }

  /// Delete user images from Firebase Storage
  static Future<bool> _deleteUserImages(String userId) async {
    try {
      // Delete profile images
      final profileImageRef = FirebaseStorage.instance.ref().child(
        'profile_images/$userId',
      );

      try {
        await profileImageRef.delete();
      } catch (e) {
        // Image might not exist, which is fine
        if (kDebugMode) {
          print('[DataDeletion] No profile image to delete for user: $userId');
        }
      }

      if (kDebugMode) {
        print('[DataDeletion] User images deleted from storage');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user images: $e');
      }
      return false;
    }
  }

  /// Delete user settings
  static Future<bool> _deleteUserSettings(String userId) async {
    try {
      // Delete user settings
      final settingsQuery =
          await FirebaseFirestore.instance
              .collection('user_settings')
              .where('userId', isEqualTo: userId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in settingsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (kDebugMode) {
        print(
          '[DataDeletion] User settings deleted: ${settingsQuery.docs.length}',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user settings: $e');
      }
      return false;
    }
  }

  /// Delete user blocked users list
  static Future<bool> _deleteUserBlockedUsers(String userId) async {
    try {
      // Remove user from other users' blocked lists
      final blockedUsersQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('blockedUsers', arrayContains: userId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in blockedUsersQuery.docs) {
        batch.update(doc.reference, {
          'blockedUsers': FieldValue.arrayRemove([userId]),
        });
      }
      await batch.commit();

      if (kDebugMode) {
        print(
          '[DataDeletion] User removed from blocked lists: ${blockedUsersQuery.docs.length}',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error removing user from blocked lists: $e');
      }
      return false;
    }
  }

  /// Delete user reports
  static Future<bool> _deleteUserReports(String userId) async {
    try {
      // Delete reports made by user
      final reportsQuery =
          await FirebaseFirestore.instance
              .collection('reports')
              .where('reporterId', isEqualTo: userId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in reportsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (kDebugMode) {
        print(
          '[DataDeletion] User reports deleted: ${reportsQuery.docs.length}',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user reports: $e');
      }
      return false;
    }
  }

  /// Delete Firebase Auth account
  static Future<bool> deleteAuthAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();

        if (kDebugMode) {
          print('[DataDeletion] Firebase Auth account deleted');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting Firebase Auth account: $e');
      }
      return false;
    }
  }

  /// Get data deletion summary for user
  static Future<Map<String, int>> getDataSummary(String userId) async {
    try {
      final results = await Future.wait([
        _getUserPostsCount(userId),
        _getUserCommentsCount(userId),
        _getUserNotificationsCount(userId),
        _getUserScheduleCount(userId),
        _getUserTasksCount(userId),
        _getUserAnnouncementsCount(userId),
        _getUserReportsCount(userId),
      ]);

      return {
        'posts': results[0],
        'comments': results[1],
        'notifications': results[2],
        'schedule': results[3],
        'tasks': results[4],
        'announcements': results[5],
        'reports': results[6],
      };
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error getting data summary: $e');
      }
      return {};
    }
  }

  static Future<int> _getUserPostsCount(String userId) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('authorId', isEqualTo: userId)
              .get();
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> _getUserCommentsCount(String userId) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('comments')
              .where('authorId', isEqualTo: userId)
              .get();
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> _getUserNotificationsCount(String userId) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .get();
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> _getUserScheduleCount(String userId) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('schedules')
              .where('userId', isEqualTo: userId)
              .get();
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> _getUserTasksCount(String userId) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('userId', isEqualTo: userId)
              .get();
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> _getUserAnnouncementsCount(String userId) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('announcements')
              .where('authorId', isEqualTo: userId)
              .get();
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> _getUserReportsCount(String userId) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('reports')
              .where('reporterId', isEqualTo: userId)
              .get();
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
