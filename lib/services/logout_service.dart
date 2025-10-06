import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/services/fcm_token_manager.dart';
import 'package:pivot/services/session_persistence_service.dart';
import 'package:pivot/services/cache_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';

/// Service to handle proper logout with notification cleanup
class LogoutService {
  static final LogoutService _instance = LogoutService._internal();
  factory LogoutService() => _instance;
  LogoutService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Perform complete logout with all cleanup
  /// This ensures no notifications are sent after logout
  Future<void> logout() async {
    print('🚪 Starting logout process...');

    try {
      final user = _auth.currentUser;
      final userId = user?.uid;

      // Step 1: Invalidate FCM token in Firestore (prevent future push notifications)
      if (userId != null) {
        print('  1️⃣ Invalidating FCM token in Firestore...');
        try {
          await _firestore.collection('users').doc(userId).update({
            'fcmToken': FieldValue.delete(),
            'tokenStatus': 'logged_out',
            'lastLogout': FieldValue.serverTimestamp(),
          });
          print('     ✅ FCM token invalidated');
        } catch (e) {
          print('     ⚠️ Could not invalidate FCM token: $e');
          // Continue with logout even if this fails
        }
      }

      // Step 2: Delete local FCM token (prevents receiving notifications on this device)
      if (!kIsWeb) {
        print('  2️⃣ Deleting local FCM token...');
        try {
          await FCMTokenManager().deleteLocalToken();
          print('     ✅ Local FCM token deleted');
        } catch (e) {
          print('     ⚠️ Could not delete local FCM token: $e');
          // Continue with logout
        }
      }

      // Step 3: Cancel ALL scheduled local notifications
      if (!kIsWeb) {
        print('  3️⃣ Cancelling all local notifications...');
        try {
          await AwesomeNotifications().cancelAll();
          print('     ✅ All local notifications cancelled');
        } catch (e) {
          print('     ⚠️ Could not cancel local notifications: $e');
          // Continue with logout
        }
      }

      // Step 4: Clear session persistence
      print('  4️⃣ Clearing session persistence...');
      try {
        await SessionPersistenceService().clearSession();
        print('     ✅ Session cleared');
      } catch (e) {
        print('     ⚠️ Could not clear session: $e');
        // Continue with logout
      }

      // Step 5: Clear cached data
      print('  5️⃣ Clearing cached data...');
      try {
        await CacheService.instance.clearUserCache(userId);
        print('     ✅ Cache cleared');
      } catch (e) {
        print('     ⚠️ Could not clear cache: $e');
        // Continue with logout
      }

      // Step 6: Sign out from Firebase (must be last)
      print('  6️⃣ Signing out from Firebase...');
      await _auth.signOut();
      print('     ✅ Signed out from Firebase');

      print('✅ Logout completed successfully');
    } catch (e) {
      print('❌ Error during logout: $e');
      // Even if there are errors, try to sign out
      try {
        await _auth.signOut();
      } catch (signOutError) {
        print('❌ Critical: Could not sign out: $signOutError');
      }
      rethrow;
    }
  }

  /// Quick logout (minimal cleanup, for emergency cases)
  Future<void> quickLogout() async {
    print('🚪 Quick logout...');
    try {
      // Just sign out and cancel notifications
      if (!kIsWeb) {
        await AwesomeNotifications().cancelAll();
      }
      await _auth.signOut();
      print('✅ Quick logout completed');
    } catch (e) {
      print('❌ Error during quick logout: $e');
      rethrow;
    }
  }
}
