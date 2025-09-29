import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserNumberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates the next sequential user number
  /// Uses a counter document to ensure atomic increments
  static Future<int> getNextUserNumber() async {
    try {
      // Use a transaction to ensure atomic increment
      int userNumber = await _firestore.runTransaction<int>((
        transaction,
      ) async {
        final counterRef = _firestore.collection('counters').doc('userNumber');
        final counterDoc = await transaction.get(counterRef);

        int currentNumber = 0;
        if (counterDoc.exists) {
          currentNumber = (counterDoc.data()?['count'] as int?) ?? 0;
        }

        // Calculate next number: if no counter exists, start from 1, otherwise increment
        int nextNumber = counterDoc.exists ? currentNumber + 1 : 1;

        transaction.set(counterRef, {'count': nextNumber});

        if (kDebugMode) {
          print(
            '[UserNumberService] Counter updated: $currentNumber -> $nextNumber',
          );
        }

        return nextNumber;
      });

      if (kDebugMode) {
        print('[UserNumberService] Generated user number: $userNumber');
      }

      return userNumber;
    } catch (e) {
      if (kDebugMode) {
        print('[UserNumberService] Error generating user number: $e');
      }
      // Fallback: try to get current count and increment manually
      try {
        final currentCount = await getCurrentUserCount();
        return currentCount + 1;
      } catch (fallbackError) {
        if (kDebugMode) {
          print('[UserNumberService] Fallback also failed: $fallbackError');
        }
        // Last resort: use timestamp but warn about it
        final timestampNumber = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (kDebugMode) {
          print(
            '[UserNumberService] Using timestamp fallback: $timestampNumber',
          );
        }
        return timestampNumber;
      }
    }
  }

  /// Initializes the counter if it doesn't exist
  static Future<void> initializeCounter() async {
    try {
      final counterRef = _firestore.collection('counters').doc('userNumber');
      final counterDoc = await counterRef.get();

      if (!counterDoc.exists) {
        await counterRef.set({'count': 0});
        if (kDebugMode) {
          print('[UserNumberService] Counter initialized with 0');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[UserNumberService] Error initializing counter: $e');
      }
    }
  }

  /// Resets the counter to 0 (use with caution - for testing only)
  static Future<void> resetCounter() async {
    try {
      final counterRef = _firestore.collection('counters').doc('userNumber');
      await counterRef.set({'count': 0});
      if (kDebugMode) {
        print('[UserNumberService] Counter reset to 0');
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
