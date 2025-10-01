import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserNumberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates the next sequential user number
  /// Uses Firestore's atomic increment to ensure unique numbers even with concurrent signups
  static Future<int> getNextUserNumber() async {
    try {
      final counterRef = _firestore.collection('counters').doc('userNumber');

      // First, ensure the counter document exists
      final counterDoc = await counterRef.get();
      if (!counterDoc.exists) {
        // Initialize counter if it doesn't exist
        await counterRef.set({
          'count': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) {
          print('[UserNumberService] Counter initialized');
        }
      }

      // Use atomic increment - this is thread-safe and handles concurrent requests
      await counterRef.update({
        'count': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Read the updated count
      final updatedDoc = await counterRef.get();
      final userNumber = (updatedDoc.data()?['count'] as int?) ?? 1;

      if (kDebugMode) {
        print('[UserNumberService] Generated user number: $userNumber');
      }

      return userNumber;
    } catch (e) {
      if (kDebugMode) {
        print('[UserNumberService] Error generating user number: $e');
      }

      // Fallback: try to initialize and increment again
      try {
        final counterRef = _firestore.collection('counters').doc('userNumber');

        // Set initial value if the error was because document doesn't exist
        await counterRef.set({
          'count': 1,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (kDebugMode) {
          print('[UserNumberService] Counter initialized via fallback');
        }

        return 1;
      } catch (fallbackError) {
        if (kDebugMode) {
          print('[UserNumberService] Fallback also failed: $fallbackError');
        }

        // Last resort: get current count from all users and add 1
        try {
          final usersSnapshot =
              await _firestore
                  .collection('users')
                  .orderBy('userNumber', descending: true)
                  .limit(1)
                  .get();

          if (usersSnapshot.docs.isNotEmpty) {
            final lastNumber =
                usersSnapshot.docs.first.data()['userNumber'] as int? ?? 0;
            return lastNumber + 1;
          }

          return 1;
        } catch (finalError) {
          if (kDebugMode) {
            print('[UserNumberService] All fallbacks failed: $finalError');
          }
          // Absolute last resort: use timestamp
          return DateTime.now().millisecondsSinceEpoch ~/ 1000;
        }
      }
    }
  }

  /// Initializes the counter if it doesn't exist
  static Future<void> initializeCounter() async {
    try {
      final counterRef = _firestore.collection('counters').doc('userNumber');
      final counterDoc = await counterRef.get();

      if (!counterDoc.exists) {
        await counterRef.set({
          'count': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
          'initialized': true,
        });
        if (kDebugMode) {
          print('[UserNumberService] Counter initialized with 0');
        }
      } else {
        if (kDebugMode) {
          final currentCount = counterDoc.data()?['count'] ?? 0;
          print(
            '[UserNumberService] Counter already exists with count: $currentCount',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[UserNumberService] Error initializing counter: $e');
      }
    }
  }

  /// Resets the counter to a specific value (use with caution - for testing/admin only)
  static Future<void> resetCounter({int startValue = 0}) async {
    try {
      final counterRef = _firestore.collection('counters').doc('userNumber');
      await counterRef.set({
        'count': startValue,
        'lastUpdated': FieldValue.serverTimestamp(),
        'reset': true,
      });
      if (kDebugMode) {
        print('[UserNumberService] Counter reset to $startValue');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[UserNumberService] Error resetting counter: $e');
      }
    }
  }

  /// Gets the current user count (for statistics)
  static Future<int> getCurrentUserCount() async {
    try {
      final counterDoc =
          await _firestore.collection('counters').doc('userNumber').get();

      if (counterDoc.exists) {
        return (counterDoc.data()?['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('[UserNumberService] Error getting user count: $e');
      }
      return 0;
    }
  }

  /// Gets user milestone message based on user number
  static String getUserMilestoneMessage(int userNumber) {
    if (userNumber <= 100) {
      return 'المؤسسون الأوائل'; // Early Founders
    } else if (userNumber <= 500) {
      return 'المبادرون'; // Pioneers
    } else if (userNumber <= 1000) {
      return 'الرواد'; // Trailblazers
    } else if (userNumber <= 5000) {
      return 'المشاركون الأوائل'; // Early Participants
    } else {
      return 'عضو'; // Member
    }
  }

  /// Gets congratulatory message for registration
  static String getCongratulatoryMessage(int userNumber) {
    final milestone = getUserMilestoneMessage(userNumber);

    if (userNumber <= 100) {
      return 'مبروك! أنت المستخدم رقم #$userNumber 🎉\n'
          'أنت من $milestone - نتمنى أن نضيف قيمة لحياتك الأكاديمية 🎓\n'
          'شكراً لثقتك فينا منذ البداية!';
    } else if (userNumber <= 500) {
      return 'مبروك! أنت المستخدم رقم #$userNumber 🎊\n'
          'أنت من $milestone - نتمنى أن نضيف قيمة لحياتك الأكاديمية 🎓\n'
          'نرحب بك في عائلتنا!';
    } else {
      return 'مبروك! أنت المستخدم رقم #$userNumber ✨\n'
          'نتمنى أن نضيف قيمة لحياتك الأكاديمية 🎓\n'
          'نرحب بك في مجتمعنا!';
    }
  }
}
