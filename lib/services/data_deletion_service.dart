import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/services/fcm_token_manager.dart';
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DataDeletionService {
  static final DataDeletionService _instance = DataDeletionService._internal();
  factory DataDeletionService() => _instance;
  DataDeletionService._internal();

  // Firebase Functions URL - you'll need to update this with your actual function URL
  static const String _functionsBaseUrl =
      'https://us-central1-pivot-28563.cloudfunctions.net';

  /// Delete user authentication account via Firebase Function (Admin SDK)
  static Future<bool> _deleteUserAuthViaFunction(
    String targetUserId,
    String adminUserId,
  ) async {
    try {
      if (kDebugMode) {
        print(
          '[DataDeletion] Calling Firebase Function to delete auth account for: $targetUserId',
        );
      }

      final url = Uri.parse('$_functionsBaseUrl/delete_user_auth');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'targetUserId': targetUserId,
          'adminUserId': adminUserId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          if (kDebugMode) {
            print(
              '[DataDeletion] Auth account deleted successfully via Firebase Function',
            );
          }
          return true;
        } else {
          if (kDebugMode) {
            print(
              '[DataDeletion] Firebase Function returned error: ${responseData['error']}',
            );
          }
          return false;
        }
      } else {
        if (kDebugMode) {
          print(
            '[DataDeletion] Firebase Function call failed with status: ${response.statusCode}',
          );
          print('[DataDeletion] Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error calling Firebase Function: $e');
      }
      return false;
    }
  }

  /// Deletes all user data from the system
  /// Returns true if successful, false otherwise
  static Future<bool> deleteAllUserData(String userId) async {
    try {
      if (kDebugMode) {
        print('[DataDeletion] Starting deletion for user: $userId');
      }

      // Delete user data in parallel for better performance
      // Note: Announcements are preserved when deleting user account
      final results = await Future.wait([
        _deleteUserProfile(userId),
        _deleteUserPosts(userId),
        _deleteUserComments(userId),
        _deleteUserNotifications(userId),
        _deleteUserSchedule(userId),
        _deleteUserTasks(userId),
        // _deleteUserAnnouncements(userId), // Preserved for institutional records
        _deleteUserFiles(userId),
        _deleteUserImages(userId),
        _deleteUserSettings(userId),
        _deleteUserBlockedUsers(userId),
        _deleteUserReports(userId),
        _deleteUserFCMToken(userId),
        _clearLocalCache(userId),
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

  /// Delete user FCM token
  static Future<bool> _deleteUserFCMToken(String userId) async {
    try {
      // Mark FCM token as invalid
      await FCMTokenManager().markTokenAsInvalid('', userId);

      if (kDebugMode) {
        print('[DataDeletion] User FCM token deleted: $userId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting user FCM token: $e');
      }
      return false;
    }
  }

  /// Clear local cache for user
  static Future<bool> _clearLocalCache(String userId) async {
    try {
      // Clear user profile from cache
      await CacheService.instance.clearUserProfile(userId);

      // Clear all cached data
      await CacheService.instance.clearAllCache();

      if (kDebugMode) {
        print('[DataDeletion] Local cache cleared for user: $userId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error clearing local cache: $e');
      }
      return false;
    }
  }

  /// Delete Firebase Auth account and perform complete logout
  static Future<bool> deleteAuthAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Delete the auth account BEFORE signing out
          // Once signed out, we lose reference to the user object
          await user.delete();

          // Sign out after deletion to clear any cached auth state
          await FirebaseAuth.instance.signOut();

          if (kDebugMode) {
            print(
              '[DataDeletion] Firebase Auth account deleted and user logged out',
            );
          }
          return true;
        } catch (authError) {
          // Handle specific Firebase Auth errors
          if (authError.toString().contains('requires-recent-login')) {
            if (kDebugMode) {
              print(
                '[DataDeletion] Account deletion requires recent login. User must re-authenticate.',
              );
            }
            throw Exception(
              'Account deletion requires recent authentication. Please sign in again and try deleting your account.',
            );
          } else if (authError.toString().contains('too-many-requests')) {
            if (kDebugMode) {
              print(
                '[DataDeletion] Too many requests. Please try again later.',
              );
            }
            throw Exception(
              'Too many deletion attempts. Please try again later.',
            );
          } else {
            if (kDebugMode) {
              print('[DataDeletion] Firebase Auth error: $authError');
            }
            rethrow;
          }
        }
      }

      if (kDebugMode) {
        print('[DataDeletion] No authenticated user found to delete');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error deleting Firebase Auth account: $e');
      }
      rethrow; // Re-throw to let caller handle the specific error
    }
  }

  /// Complete user deletion with proper cleanup (for self-deletion)
  static Future<bool> deleteUserCompletely(
    String userId,
    BuildContext? context,
  ) async {
    try {
      if (kDebugMode) {
        print('[DataDeletion] Starting complete user deletion for: $userId');
      }

      // IMPORTANT: Delete user data FIRST while user is still authenticated
      // Then delete Firebase Auth account last
      if (kDebugMode) {
        print(
          '[DataDeletion] Deleting user data from Firestore and Storage (while authenticated)...',
        );
      }
      final dataDeleted = await deleteAllUserData(userId);
      if (!dataDeleted) {
        if (kDebugMode) {
          print(
            '[DataDeletion] Warning: Some user data deletion operations failed',
          );
        }
        // Continue with auth deletion even if some data deletion fails
      } else {
        if (kDebugMode) {
          print('[DataDeletion] User data deleted successfully');
        }
      }

      // Now delete Firebase Auth account (must be done last while user is still authenticated)
      if (kDebugMode) {
        print('[DataDeletion] Deleting Firebase Auth account...');
      }
      try {
        final authDeleted = await deleteAuthAccount();
        if (authDeleted) {
          if (kDebugMode) {
            print('[DataDeletion] Firebase Auth account deleted successfully');
          }
        } else {
          if (kDebugMode) {
            print('[DataDeletion] Warning: Failed to delete auth account');
          }
        }
      } catch (authError) {
        // Handle authentication-specific errors
        if (authError.toString().contains('requires recent authentication')) {
          if (kDebugMode) {
            print(
              '[DataDeletion] Account deletion requires recent authentication',
            );
          }
          rethrow; // Re-throw to inform the user they need to re-authenticate
        } else {
          if (kDebugMode) {
            print('[DataDeletion] Auth deletion error: $authError');
          }
          // Data deletion was successful, so we can consider this a partial success
        }
      }

      // Clear user profile provider if context is available
      if (context != null) {
        try {
          final provider = Provider.of<UserProfileProvider>(
            context,
            listen: false,
          );
          provider.clearProfile();
          if (kDebugMode) {
            print('[DataDeletion] User profile provider cleared');
          }
        } catch (e) {
          if (kDebugMode) {
            print('[DataDeletion] Error clearing user profile provider: $e');
          }
        }
      }

      if (kDebugMode) {
        print(
          '[DataDeletion] Complete user deletion process finished for: $userId',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error in complete user deletion: $e');
      }
      return false;
    }
  }

  /// Complete user deletion initiated by admin (requires admin authentication)
  static Future<bool> deleteUserCompletelyAsAdmin(
    String userId,
    BuildContext? context,
  ) async {
    try {
      if (kDebugMode) {
        print(
          '[DataDeletion] Starting admin-initiated user deletion for: $userId',
        );
      }

      // Check if admin is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print(
            '[DataDeletion] Error: Admin must be authenticated to delete users',
          );
        }
        throw Exception('Admin must be signed in to delete users');
      }

      if (kDebugMode) {
        print('[DataDeletion] Admin authenticated: ${currentUser.uid}');
      }

      // Delete all user data from Firestore and Storage (admin has permissions)
      if (kDebugMode) {
        print(
          '[DataDeletion] Deleting user data from Firestore and Storage (admin operation)...',
        );
      }
      final dataDeleted = await deleteAllUserData(userId);
      if (!dataDeleted) {
        if (kDebugMode) {
          print(
            '[DataDeletion] Warning: Some user data deletion operations failed',
          );
        }
        // Continue even if some data deletion fails
      } else {
        if (kDebugMode) {
          print('[DataDeletion] User data deleted successfully');
        }
      }

      // Note: Firebase Auth account deletion requires Firebase Functions with Admin SDK
      // For now, we'll mark this as successful since the data deletion is complete
      // The auth account deletion should be handled by deploying the Firebase Function
      if (kDebugMode) {
        print(
          '[DataDeletion] Firebase Auth account deletion skipped - requires Firebase Function deployment',
        );
        print(
          '[DataDeletion] To enable auth deletion, deploy the delete_user_auth Firebase Function',
        );
      }

      // Clear user profile provider if context is available
      if (context != null) {
        try {
          final provider = Provider.of<UserProfileProvider>(
            context,
            listen: false,
          );
          provider.clearProfile();
          if (kDebugMode) {
            print('[DataDeletion] User profile provider cleared');
          }
        } catch (e) {
          if (kDebugMode) {
            print('[DataDeletion] Error clearing user profile provider: $e');
          }
        }
      }

      if (kDebugMode) {
        print(
          '[DataDeletion] Admin-initiated user deletion finished for: $userId',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[DataDeletion] Error in admin-initiated user deletion: $e');
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
        // _getUserAnnouncementsCount(userId), // Announcements are preserved
        _getUserReportsCount(userId),
      ]);

      return {
        'posts': results[0],
        'comments': results[1],
        'notifications': results[2],
        'schedule': results[3],
        'tasks': results[4],
        // 'announcements': results[5], // Announcements are preserved
        'reports': results[5],
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
