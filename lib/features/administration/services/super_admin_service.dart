import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch dashboard data including user statistics
  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Initialize stats
      Map<String, int> userRolesCount = {
        'Super Admin': 0,
        'Admin': 0,
        'Professor': 0,
        'miniProfessor': 0,
        'Student': 0,
      };

      Map<String, int> departmentStats = {};
      Map<String, int> levelStats = {};
      Map<String, int> genderStats = {'ذكر': 0, 'أنثى': 0, 'غير محدد': 0};

      int newUsersThisMonth = 0;

      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();

        // Role stats
        final role = data['role'] as String? ?? 'Student';
        if (userRolesCount.containsKey(role)) {
          userRolesCount[role] = userRolesCount[role]! + 1;
        }

        // Department stats
        final department = data['department'] as String? ?? 'غير محدد';
        departmentStats[department] = (departmentStats[department] ?? 0) + 1;

        // Level stats
        final level = data['level'] as String? ?? 'غير محدد';
        levelStats[level] = (levelStats[level] ?? 0) + 1;

        // Gender stats
        final gender = data['gender'] as String? ?? 'ذكر';
        String normalizedGender = _normalizeGender(gender);
        if (!genderStats.containsKey(normalizedGender)) {
          genderStats[normalizedGender] = 0;
        }
        genderStats[normalizedGender] = genderStats[normalizedGender]! + 1;

        // New users this month
        final createdAt = data['createdAt'];
        if (createdAt != null) {
          DateTime? userCreatedAt = _parseTimestamp(createdAt);
          if (userCreatedAt != null && userCreatedAt.isAfter(firstDayOfMonth)) {
            newUsersThisMonth++;
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'userRolesCount': userRolesCount,
        'departmentStats': departmentStats,
        'levelStats': levelStats,
        'genderStats': genderStats,
        'newUsersThisMonth': newUsersThisMonth,
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard data: $e');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      Map<String, int> roleCounts = {};
      Map<String, int> departmentCounts = {};
      Map<String, int> levelCounts = {};
      Map<String, int> genderCounts = {};

      int totalUsers = usersSnapshot.docs.length;
      int activeUsers = 0;
      int newUsersThisWeek = 0;
      int newUsersThisMonth = 0;

      final now = DateTime.now();
      final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();

        // Role counting
        final role = data['role'] as String? ?? 'Student';
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;

        // Department counting
        final department = data['department'] as String? ?? 'غير محدد';
        departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;

        // Level counting
        final level = data['level'] as String? ?? 'غير محدد';
        levelCounts[level] = (levelCounts[level] ?? 0) + 1;

        // Gender counting
        final gender = data['gender'] as String? ?? 'ذكر';
        final normalizedGender = _normalizeGender(gender);
        genderCounts[normalizedGender] =
            (genderCounts[normalizedGender] ?? 0) + 1;

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
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'newUsersThisWeek': newUsersThisWeek,
        'newUsersThisMonth': newUsersThisMonth,
        'roleCounts': roleCounts,
        'departmentCounts': departmentCounts,
        'levelCounts': levelCounts,
        'genderCounts': genderCounts,
      };
    } catch (e) {
      throw Exception('Failed to fetch user statistics: $e');
    }
  }

  // Get system statistics
  Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      // Get collections counts
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

      return {
        'usersCount': usersCount,
        'subjectsCount': subjectsCount,
        'announcementsCount': announcementsCount,
        'tasksCount': tasksCount,
        'feedbackCount': feedbackCount,
      };
    } catch (e) {
      throw Exception('Failed to fetch system statistics: $e');
    }
  }

  // Get top departments
  Future<List<Map<String, dynamic>>> getTopDepartments({int limit = 5}) async {
    try {
      final stats = await getUserStatistics();
      final departmentCounts = Map<String, int>.from(stats['departmentCounts']);
      final totalUsers = stats['totalUsers'] as int;

      final sorted =
          departmentCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(limit)
          .map(
            (entry) => {
              'name': entry.key,
              'count': entry.value,
              'percentage':
                  totalUsers > 0
                      ? ((entry.value / totalUsers) * 100).round()
                      : 0,
            },
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch top departments: $e');
    }
  }

  // Get top levels
  Future<List<Map<String, dynamic>>> getTopLevels({int limit = 10}) async {
    try {
      final stats = await getUserStatistics();
      final levelCounts = Map<String, int>.from(stats['levelCounts']);
      final totalUsers = stats['totalUsers'] as int;

      final sorted =
          levelCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(limit)
          .map(
            (entry) => {
              'name': entry.key,
              'count': entry.value,
              'percentage':
                  totalUsers > 0
                      ? ((entry.value / totalUsers) * 100).round()
                      : 0,
            },
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch top levels: $e');
    }
  }

  // Get available departments
  Future<List<String>> getAvailableDepartments() async {
    try {
      final stats = await getUserStatistics();
      final departmentCounts = Map<String, int>.from(stats['departmentCounts']);
      return departmentCounts.keys.where((dept) => dept != 'غير محدد').toList();
    } catch (e) {
      return ['CS', 'IS', 'AI', 'SC', 'General']; // Default departments
    }
  }

  // Get available levels
  Future<List<String>> getAvailableLevels() async {
    try {
      final stats = await getUserStatistics();
      final levelCounts = Map<String, int>.from(stats['levelCounts']);
      return levelCounts.keys.where((level) => level != 'غير محدد').toList();
    } catch (e) {
      return ['الأول', 'الثاني', 'الثالث', 'الرابع']; // Default levels
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
}
