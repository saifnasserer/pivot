import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user analytics
  Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      Map<String, int> roleDistribution = {};
      Map<String, int> departmentDistribution = {};
      Map<String, int> levelDistribution = {};
      Map<String, int> genderDistribution = {};

      int totalUsers = usersSnapshot.docs.length;
      int activeUsers = 0;
      int newUsersThisWeek = 0;
      int newUsersThisMonth = 0;
      int newUsersThisYear = 0;

      final now = DateTime.now();
      final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final firstDayOfYear = DateTime(now.year, 1, 1);

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();

        // Role distribution
        final role = data['role'] as String? ?? 'Student';
        roleDistribution[role] = (roleDistribution[role] ?? 0) + 1;

        // Department distribution
        final department = data['department'] as String? ?? 'غير محدد';
        departmentDistribution[department] =
            (departmentDistribution[department] ?? 0) + 1;

        // Level distribution
        final level = data['level'] as String? ?? 'غير محدد';
        levelDistribution[level] = (levelDistribution[level] ?? 0) + 1;

        // Gender distribution
        final gender = data['gender'] as String? ?? 'ذكر';
        final normalizedGender = _normalizeGender(gender);
        genderDistribution[normalizedGender] =
            (genderDistribution[normalizedGender] ?? 0) + 1;

        // Active users (users with recent activity)
        final lastActive = data['lastActiveAt'];
        if (lastActive != null) {
          final lastActiveDate = _parseTimestamp(lastActive);
          if (lastActiveDate != null &&
              lastActiveDate.isAfter(now.subtract(Duration(days: 30)))) {
            activeUsers++;
          }
        }

        // New users counting
        final createdAt = data['createdAt'];
        if (createdAt != null) {
          final createdDate = _parseTimestamp(createdAt);
          if (createdDate != null) {
            if (createdDate.isAfter(firstDayOfWeek)) {
              newUsersThisWeek++;
            }
            if (createdDate.isAfter(firstDayOfMonth)) {
              newUsersThisMonth++;
            }
            if (createdDate.isAfter(firstDayOfYear)) {
              newUsersThisYear++;
            }
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'newUsersThisWeek': newUsersThisWeek,
        'newUsersThisMonth': newUsersThisMonth,
        'newUsersThisYear': newUsersThisYear,
        'roleDistribution': roleDistribution,
        'departmentDistribution': departmentDistribution,
        'levelDistribution': levelDistribution,
        'genderDistribution': genderDistribution,
      };
    } catch (e) {
      throw Exception('Failed to fetch user analytics: $e');
    }
  }

  // Get content analytics
  Future<Map<String, dynamic>> getContentAnalytics() async {
    try {
      final announcementsSnapshot =
          await _firestore.collection('announcements').get();
      final subjectsSnapshot = await _firestore.collection('subjects').get();
      final tasksSnapshot = await _firestore.collection('tasks').get();
      final feedbackSnapshot = await _firestore.collection('feedback').get();

      int totalAnnouncements = announcementsSnapshot.docs.length;
      int totalSubjects = subjectsSnapshot.docs.length;
      int totalTasks = tasksSnapshot.docs.length;
      int totalFeedback = feedbackSnapshot.docs.length;

      // Count active content (created in last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      int activeAnnouncements = 0;
      int activeSubjects = 0;
      int activeTasks = 0;
      int activeFeedback = 0;

      for (var doc in announcementsSnapshot.docs) {
        final createdAt = _parseTimestamp(doc.data()['createdAt']);
        if (createdAt != null && createdAt.isAfter(thirtyDaysAgo)) {
          activeAnnouncements++;
        }
      }

      for (var doc in subjectsSnapshot.docs) {
        final createdAt = _parseTimestamp(doc.data()['createdAt']);
        if (createdAt != null && createdAt.isAfter(thirtyDaysAgo)) {
          activeSubjects++;
        }
      }

      for (var doc in tasksSnapshot.docs) {
        final createdAt = _parseTimestamp(doc.data()['createdAt']);
        if (createdAt != null && createdAt.isAfter(thirtyDaysAgo)) {
          activeTasks++;
        }
      }

      for (var doc in feedbackSnapshot.docs) {
        final createdAt = _parseTimestamp(doc.data()['timestamp']);
        if (createdAt != null && createdAt.isAfter(thirtyDaysAgo)) {
          activeFeedback++;
        }
      }

      return {
        'totalAnnouncements': totalAnnouncements,
        'totalSubjects': totalSubjects,
        'totalTasks': totalTasks,
        'totalFeedback': totalFeedback,
        'activeAnnouncements': activeAnnouncements,
        'activeSubjects': activeSubjects,
        'activeTasks': activeTasks,
        'activeFeedback': activeFeedback,
      };
    } catch (e) {
      throw Exception('Failed to fetch content analytics: $e');
    }
  }

  // Get engagement analytics
  Future<Map<String, dynamic>> getEngagementAnalytics() async {
    try {
      // Get user activity data
      final usersSnapshot = await _firestore.collection('users').get();

      int totalUsers = usersSnapshot.docs.length;
      int activeUsers = 0;
      int highlyActiveUsers = 0;
      int inactiveUsers = 0;

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));
      final thirtyDaysAgo = now.subtract(Duration(days: 30));

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final lastActive = _parseTimestamp(data['lastActiveAt']);

        if (lastActive != null) {
          if (lastActive.isAfter(sevenDaysAgo)) {
            highlyActiveUsers++;
            activeUsers++;
          } else if (lastActive.isAfter(thirtyDaysAgo)) {
            activeUsers++;
          } else {
            inactiveUsers++;
          }
        } else {
          inactiveUsers++;
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'highlyActiveUsers': highlyActiveUsers,
        'inactiveUsers': inactiveUsers,
        'engagementRate':
            totalUsers > 0 ? (activeUsers / totalUsers * 100).round() : 0,
        'highEngagementRate':
            totalUsers > 0 ? (highlyActiveUsers / totalUsers * 100).round() : 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch engagement analytics: $e');
    }
  }

  // Get growth analytics
  Future<Map<String, dynamic>> getGrowthAnalytics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final firstDayOfYear = DateTime(now.year, 1, 1);

      int newUsersThisMonth = 0;
      int newUsersLastMonth = 0;
      int newUsersThisYear = 0;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final createdAt = _parseTimestamp(data['createdAt']);

        if (createdAt != null) {
          if (createdAt.isAfter(firstDayOfMonth)) {
            newUsersThisMonth++;
          }
          if (createdAt.isAfter(firstDayOfLastMonth) &&
              createdAt.isBefore(firstDayOfMonth)) {
            newUsersLastMonth++;
          }
          if (createdAt.isAfter(firstDayOfYear)) {
            newUsersThisYear++;
          }
        }
      }

      double growthRate = 0.0;
      if (newUsersLastMonth > 0) {
        growthRate =
            ((newUsersThisMonth - newUsersLastMonth) / newUsersLastMonth) * 100;
      } else if (newUsersThisMonth > 0) {
        growthRate =
            100.0; // 100% growth if no users last month but users this month
      }

      return {
        'newUsersThisMonth': newUsersThisMonth,
        'newUsersLastMonth': newUsersLastMonth,
        'newUsersThisYear': newUsersThisYear,
        'growthRate': growthRate.round(),
        'totalUsers': usersSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to fetch growth analytics: $e');
    }
  }

  // Get system health analytics
  Future<Map<String, dynamic>> getSystemHealthAnalytics() async {
    try {
      // Get collection sizes
      final usersCount = await _firestore
          .collection('users')
          .get()
          .then((snapshot) => snapshot.docs.length);
      final subjectsCount = await _firestore
          .collection('subjects')
          .get()
          .then((snapshot) => snapshot.docs.length);
      final announcementsCount = await _firestore
          .collection('announcements')
          .get()
          .then((snapshot) => snapshot.docs.length);
      final tasksCount = await _firestore
          .collection('tasks')
          .get()
          .then((snapshot) => snapshot.docs.length);
      final feedbackCount = await _firestore
          .collection('feedback')
          .get()
          .then((snapshot) => snapshot.docs.length);

      // Calculate system health metrics
      int totalRecords =
          usersCount +
          subjectsCount +
          announcementsCount +
          tasksCount +
          feedbackCount;

      return {
        'usersCount': usersCount,
        'subjectsCount': subjectsCount,
        'announcementsCount': announcementsCount,
        'tasksCount': tasksCount,
        'feedbackCount': feedbackCount,
        'totalRecords': totalRecords,
        'systemHealth': _calculateSystemHealth(
          usersCount,
          subjectsCount,
          announcementsCount,
          tasksCount,
          feedbackCount,
        ),
      };
    } catch (e) {
      throw Exception('Failed to fetch system health analytics: $e');
    }
  }

  // Helper method to normalize gender values
  String _normalizeGender(String gender) {
    if (gender == 'انثى' || gender == 'أنثى') {
      return 'أنثى';
    } else if (gender == 'ذكر' || gender == 'male') {
      return 'ذكر';
    } else {
      return 'غير محدد';
    }
  }

  // Helper method to parse timestamp
  DateTime? _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  // Calculate system health score
  String _calculateSystemHealth(
    int users,
    int subjects,
    int announcements,
    int tasks,
    int feedback,
  ) {
    // Simple health calculation based on data distribution
    if (users == 0) return 'Critical';
    if (subjects == 0) return 'Poor';
    if (announcements == 0) return 'Fair';
    if (tasks == 0) return 'Good';
    return 'Excellent';
  }
}
