import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _totalUsers = 0;
  Map<String, int> _userRolesCount = {};
  Map<String, int> _departmentStats = {};
  Map<String, int> _levelStats = {};
  Map<String, int> _sectionStats = {};
  Map<String, int> _genderStats = {};
  int _newUsersThisMonth = 0;
  bool _isLoading = false;

  int get totalUsers => _totalUsers;
  Map<String, int> get userRolesCount => _userRolesCount;
  Map<String, int> get departmentStats => _departmentStats;
  Map<String, int> get levelStats => _levelStats;
  Map<String, int> get sectionStats => _sectionStats;
  Map<String, int> get genderStats => _genderStats;
  int get newUsersThisMonth => _newUsersThisMonth;
  bool get isLoading => _isLoading;

  SuperAdminProvider() {
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    await _fetchUserStats();

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
      _sectionStats = {};
      _genderStats = {'ذكر': 0, 'أنثى': 0};

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

        // Section stats
        final section = data['section'] as String? ?? 'غير محدد';
        _sectionStats[section] = (_sectionStats[section] ?? 0) + 1;

        // Gender stats
        final gender = data['gender'] as String? ?? 'ذكر';
        if (_genderStats.containsKey(gender)) {
          _genderStats[gender] = _genderStats[gender]! + 1;
        }

        // New users this month (assuming there's a createdAt field)
        // If there's no createdAt field, we'll use a different approach
        final createdAt = data['createdAt'];
        if (createdAt != null) {
          final userCreatedAt =
              createdAt is Timestamp
                  ? createdAt.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(createdAt);
          if (userCreatedAt.isAfter(firstDayOfMonth)) {
            _newUsersThisMonth++;
          }
        }
      }
    } catch (e) {
      print('Error fetching user stats: $e');
    }
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

  List<Map<String, dynamic>> getTopSections() {
    final sorted =
        _sectionStats.entries.toList()
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

  // Get available departments from actual user data
  List<String> getAvailableDepartments() {
    return _departmentStats.keys.where((dept) => dept != 'غير محدد').toList();
  }

  // Get available levels from actual user data
  List<String> getAvailableLevels() {
    return _levelStats.keys.where((level) => level != 'غير محدد').toList();
  }

  // Get available sections from actual user data
  List<String> getAvailableSections() {
    return _sectionStats.keys
        .where((section) => section != 'غير محدد')
        .toList();
  }

  // Get default departments if no data exists yet
  List<String> getDefaultDepartments() {
    return ['CS', 'IS', 'AI', 'SC', 'General'];
  }

  // Get default levels if no data exists yet
  List<String> getDefaultLevels() {
    return ['الأول', 'الثاني', 'الثالث', 'الرابع'];
  }

  // Get default sections if no data exists yet
  List<String> getDefaultSections() {
    return ['A', 'B', 'C', 'D'];
  }

  //   Future<void> clearImageCache() async {
  //     await DefaultCacheManager().emptyCache();
  //     // Optionally, show a snackbar or some feedback to the user
  //   }
  //
}
