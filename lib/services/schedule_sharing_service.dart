import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pivot/models/shared_schedule.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/services/auth_service.dart';

class ScheduleSharingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final Uuid _uuid = const Uuid();

  static const String _collection = 'shared_schedules';

  /// Create a shareable link for a schedule
  Future<String?> createShareableLink({
    required String title,
    required String description,
    required Map<String, List<ScheduleItem>> schedule,
    DateTime? expiresAt,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user profile for owner name
      final userProfile = await _authService.getUserProfile(user.uid);
      final ownerName = userProfile?.name ?? 'مستخدم مجهول';

      // Flatten schedule items into a single list
      final List<ScheduleItem> allItems = [];
      schedule.forEach((day, items) {
        allItems.addAll(items);
      });

      if (allItems.isEmpty) {
        throw Exception('لا يمكن مشاركة جدول فارغ');
      }

      // Generate unique share ID
      final shareId = _uuid.v4();

      // Create shared schedule
      final sharedSchedule = SharedSchedule(
        shareId: shareId,
        ownerId: user.uid,
        ownerName: ownerName,
        title: title,
        description: description,
        items: allItems,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      // Save to Firestore
      await _firestore
          .collection(_collection)
          .doc(shareId)
          .set(sharedSchedule.toJson());

      print('✅ Shared schedule created with ID: $shareId');
      return shareId;
    } catch (e) {
      print('❌ Error creating shareable link: $e');
      return null;
    }
  }

  /// Get a shared schedule by its share ID
  Future<SharedSchedule?> getSharedSchedule(String shareId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(shareId).get();

      if (!doc.exists) {
        return null;
      }

      final sharedSchedule = SharedSchedule.fromJson(doc.data()!);

      // Check if schedule is still valid
      if (!sharedSchedule.isValid) {
        return null;
      }

      // Increment access count
      await _incrementAccessCount(shareId);

      return sharedSchedule;
    } catch (e) {
      print('❌ Error getting shared schedule: $e');
      return null;
    }
  }

  /// Import a shared schedule to current user's schedule (replaces existing schedule)
  Future<bool> importSharedSchedule(
    String shareId, {
    bool preserveNotifications = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get the shared schedule
      final sharedSchedule = await getSharedSchedule(shareId);
      if (sharedSchedule == null) {
        throw Exception('الرابط غير صحيح أو منتهي الصلاحية');
      }

      print('🔄 ScheduleSharingService: Starting import (replace mode)');
      print('  - User ID: ${user.uid}');
      print('  - Share ID: $shareId');
      print('  - Items to import: ${sharedSchedule.items.length}');
      print('  - Preserve notifications: $preserveNotifications');

      // Count items with notifications enabled in original schedule
      final itemsWithNotifications =
          sharedSchedule.items.where((item) => item.notificationEnabled).length;
      print(
        '  - Items with notifications in original: $itemsWithNotifications',
      );

      // Import items with new IDs to avoid conflicts
      final List<ScheduleItem> itemsToImport =
          sharedSchedule.items.map((item) {
            return ScheduleItem(
              id: _uuid.v4(), // Generate new ID
              title: item.title,
              time: item.time,
              location: item.location,
              day: item.day,
              type: item.type,
              notificationEnabled:
                  preserveNotifications
                      ? item
                          .notificationEnabled // Preserve original notification settings
                      : false, // Disable all notifications if user chooses
              order: item.order,
              instructor:
                  item.instructor, // Also preserve instructor information
            );
          }).toList();

      // Step 1: Clear all existing schedule items completely
      await _clearAllScheduleItems();

      // Step 2: Verify old schedule is completely removed
      await _verifyScheduleCleared();

      // Step 3: Add all imported items (only after old schedule is confirmed removed)
      final scheduleRef = _firestore.collection('schedules').doc(user.uid);

      // Group imported items by day
      final Map<String, List<Map<String, dynamic>>> groupedItems = {};
      for (final item in itemsToImport) {
        groupedItems.putIfAbsent(item.day, () => []).add(item.toMap());
      }

      // Set the new schedule data
      await scheduleRef.set(groupedItems);

      // Count final items with notifications enabled
      final finalItemsWithNotifications =
          itemsToImport.where((item) => item.notificationEnabled).length;

      print(
        '✅ Successfully replaced schedule with ${itemsToImport.length} imported items',
      );
      print(
        '  - Items with notifications enabled after import: $finalItemsWithNotifications',
      );

      return true;
    } catch (e) {
      print('❌ Error importing shared schedule: $e');
      return false;
    }
  }

  /// Clear all schedule items for the current user
  Future<void> _clearAllScheduleItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('🗑️ ScheduleSharingService: Clearing existing schedule items');

      final scheduleRef = _firestore.collection('schedules').doc(user.uid);

      // Delete the entire schedule document
      await scheduleRef.delete();

      print('  - ✅ Cleared existing schedule document');
    } catch (e) {
      print('  - ❌ Error clearing schedule items: $e');
      rethrow;
    }
  }

  /// Verify that all schedule items have been completely removed
  Future<void> _verifyScheduleCleared() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print(
        '🔍 ScheduleSharingService: Verifying schedule is completely cleared',
      );

      final scheduleRef = _firestore.collection('schedules').doc(user.uid);

      // Wait a moment for Firestore to process the deletion
      await Future.delayed(Duration(milliseconds: 500));

      final snapshot = await scheduleRef.get();

      if (snapshot.exists) {
        print('  - ❌ Warning: Schedule document still exists after clearing');
        // Force delete the document again
        await scheduleRef.delete();

        // Verify again
        await Future.delayed(Duration(milliseconds: 300));
        final finalSnapshot = await scheduleRef.get();
        if (finalSnapshot.exists) {
          throw Exception(
            'Failed to completely clear existing schedule document',
          );
        }
      }

      print('  - ✅ Verified: Schedule document is completely cleared');
    } catch (e) {
      print('  - ❌ Error verifying schedule cleared: $e');
      rethrow;
    }
  }

  /// Share the link via system share dialog (for Firestore-saved schedules)
  /// Note: This requires deep linking setup to work properly
  Future<void> shareScheduleLink(String shareId) async {
    try {
      // For now, share the schedule ID with instructions
      final shareText = '''
🔗 مفتاح الجدول المشترك:
$shareId

📝 ملاحظة: لاستيراد هذا الجدول، استخدم خاصية "استيراد جدول" في التطبيق وأدخل المفتاح أعلاه.

مشارك عبر تطبيق Pivot 🎓
''';

      await Share.share(shareText, subject: 'مشاركة جدول دراسي');
    } catch (e) {
      print('❌ Error sharing link: $e');
    }
  }

  /// Get user's own shared schedules
  Future<List<SharedSchedule>> getUserSharedSchedules() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('ownerId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => SharedSchedule.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting user shared schedules: $e');
      return [];
    }
  }

  /// Delete a shared schedule
  Future<bool> deleteSharedSchedule(String shareId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection(_collection).doc(shareId).get();

      if (!doc.exists) return false;

      final sharedSchedule = SharedSchedule.fromJson(doc.data()!);
      if (sharedSchedule.ownerId != user.uid) {
        throw Exception('ليس لديك صلاحية لحذف هذا الجدول');
      }

      await _firestore.collection(_collection).doc(shareId).delete();

      print('✅ Shared schedule deleted: $shareId');
      return true;
    } catch (e) {
      print('❌ Error deleting shared schedule: $e');
      return false;
    }
  }

  /// Private helper to increment access count
  Future<void> _incrementAccessCount(String shareId) async {
    try {
      await _firestore.collection(_collection).doc(shareId).update({
        'accessCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('❌ Error incrementing access count: $e');
    }
  }

  /// Validate share ID format
  static bool isValidShareId(String shareId) {
    // UUID v4 format validation
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(shareId);
  }

  /// Extract share ID from a full URL
  static String? extractShareIdFromUrl(String url) {
    final regex = RegExp(r'/schedule/([a-f0-9-]{36})', caseSensitive: false);
    final match = regex.firstMatch(url);
    return match?.group(1);
  }
}
