import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SuperAdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _totalUsers = 0;
  Map<String, int> _userRolesCount = {};
  bool _isMaintenanceMode = false;
  bool _isLoading = false;

  int get totalUsers => _totalUsers;
  Map<String, int> get userRolesCount => _userRolesCount;
  bool get isMaintenanceMode => _isMaintenanceMode;
  bool get isLoading => _isLoading;

  SuperAdminProvider() {
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _fetchUserStats(),
      _fetchMaintenanceMode(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchUserStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;

      _userRolesCount = {
        'Super Admin': 0,
        'Admin': 0,
        'Professor': 0,
        'miniProfessor': 0,
        'Student': 0,
      };

      for (var doc in usersSnapshot.docs) {
        final role = doc.data()['role'] as String? ?? 'Student';
        if (_userRolesCount.containsKey(role)) {
          _userRolesCount[role] = _userRolesCount[role]! + 1;
        }
      }
    } catch (e) {
      // Handle error
      print('Error fetching user stats: $e');
    }
  }

  Future<void> _fetchMaintenanceMode() async {
    try {
      final doc = await _firestore.collection('settings').doc('app').get();
      if (doc.exists) {
        _isMaintenanceMode = doc.data()?['isMaintenanceMode'] ?? false;
      }
    } catch (e) {
      // Handle error
      print('Error fetching maintenance mode: $e');
    }
  }

  Future<void> setMaintenanceMode(bool value) async {
    _isMaintenanceMode = value;
    notifyListeners();
    try {
      await _firestore.collection('settings').doc('app').set({'isMaintenanceMode': value});
    } catch (e) {
      // Handle error
      print('Error setting maintenance mode: $e');
    }
  }

  Future<void> clearImageCache() async {
    await DefaultCacheManager().emptyCache();
    // Optionally, show a snackbar or some feedback to the user
  }
}
