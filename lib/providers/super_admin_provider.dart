import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SuperAdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _totalUsers = 0;
  Map<String, int> _userRolesCount = {};
  Map<String, int> _departmentStats = {};
  Map<String, int> _levelStats = {};
  Map<String, int> _genderStats = {};
  int _newUsersThisMonth = 0;
  bool _isLoading = false;

  int get totalUsers => _totalUsers;
  Map<String, int> get userRolesCount => _userRolesCount;
  Map<String, int> get departmentStats => _departmentStats;
  Map<String, int> get levelStats => _levelStats;
  Map<String, int> get genderStats => _genderStats;
  int get newUsersThisMonth => _newUsersThisMonth;
  bool get isLoading => _isLoading;

  SuperAdminProvider() {
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchUserStats();
    } catch (e) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchUserStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;

      // Reset all stats
      _userRolesCount = {
        'Super Admin': 0,
        'Admin': 0,
        'Professor': 0,
        'miniProfessor': 0,
        'Student': 0,
      };

      _departmentStats = {};
      _levelStats = {};
      _genderStats = {'ذكر': 0, 'أنثى': 0, 'غير محدد': 0};

      _newUsersThisMonth = 0;

      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();

        // Role stats
        final role = data['role'] as String? ?? 'Student';
        if (_userRolesCount.containsKey(role)) {
          _userRolesCount[role] = _userRolesCount[role]! + 1;
        }

        // Department stats
        final department = data['department'] as String? ?? 'غير محدد';
        _departmentStats[department] = (_departmentStats[department] ?? 0) + 1;

        // Level stats
        final level = data['level'] as String? ?? 'غير محدد';
        _levelStats[level] = (_levelStats[level] ?? 0) + 1;

        // Gender stats
        final gender = data['gender'] as String? ?? 'ذكر';

        // Normalize gender values to handle different Arabic spellings
        String normalizedGender = gender;
        if (gender == 'انثى' || gender == 'أنثى') {
          normalizedGender = 'أنثى'; // Use the standard spelling with hamza
        } else if (gender == 'ذكر' || gender == 'male') {
          normalizedGender = 'ذكر';
        } else {
          normalizedGender = 'غير محدد';
        }

        // Initialize gender in stats if it doesn't exist
        if (!_genderStats.containsKey(normalizedGender)) {
          _genderStats[normalizedGender] = 0;
        }
        _genderStats[normalizedGender] = _genderStats[normalizedGender]! + 1;

        // New users this month
        final createdAt = data['createdAt'];

        if (createdAt != null) {
          DateTime? userCreatedAt;

          try {
            if (createdAt is Timestamp) {
              userCreatedAt = createdAt.toDate();
            } else if (createdAt is int) {
              userCreatedAt = DateTime.fromMillisecondsSinceEpoch(createdAt);
            } else if (createdAt is String) {
              userCreatedAt = DateTime.parse(createdAt);
            } else {}

            if (userCreatedAt != null) {
              if (userCreatedAt.isAfter(firstDayOfMonth)) {
                _newUsersThisMonth++;
              }
            }
          } catch (e) {}
        } else {}
      }
    } catch (e) {}
  }

  double getGrowthRate() {
    if (_totalUsers == 0) return 0.0;
    return (_newUsersThisMonth / _totalUsers) * 100;
  }

  List<Map<String, dynamic>> getTopDepartments() {
    final sorted =
        _departmentStats.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(5)
        .map(
          (e) => {
            'name': e.key,
            'count': e.value,
            'percentage':
                _totalUsers > 0 ? ((e.value / _totalUsers) * 100).round() : 0,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> getTopLevels() {
    final sorted =
        _levelStats.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .map(
          (e) => {
            'name': e.key,
            'count': e.value,
            'percentage':
                _totalUsers > 0 ? ((e.value / _totalUsers) * 100).round() : 0,
          },
        )
        .toList();
  }

  // Get available departments from actual user data
  List<String> getAvailableDepartments() {
    return _departmentStats.keys.where((dept) => dept != 'غير محدد').toList();
  }

  // Get available levels from actual user data
  List<String> getAvailableLevels() {
    return _levelStats.keys.where((level) => level != 'غير محدد').toList();
  }

  // Get default departments if no data exists yet
  List<String> getDefaultDepartments() {
    return ['CS', 'IS', 'AI', 'SC', 'General'];
  }

  // Get default levels if no data exists yet
  List<String> getDefaultLevels() {
    return ['الأول', 'الثاني', 'الثالث', 'الرابع'];
  }

  //   Future<void> clearImageCache() async {
  //     await DefaultCacheManager().emptyCache();
  //     // Optionally, show a snackbar or some feedback to the user
  //   }
  //
}
