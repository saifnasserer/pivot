import 'package:pivot/features/administration/services/super_admin_service.dart';

class SuperAdminRepository {
  final SuperAdminService _superAdminService;

  SuperAdminRepository(this._superAdminService);

  // Fetch dashboard data
  Future<Map<String, dynamic>> fetchDashboardData() async {
    return await _superAdminService.fetchDashboardData();
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    return await _superAdminService.getUserStatistics();
  }

  // Get system statistics
  Future<Map<String, dynamic>> getSystemStatistics() async {
    return await _superAdminService.getSystemStatistics();
  }

  // Get top departments
  Future<List<Map<String, dynamic>>> getTopDepartments({int limit = 5}) async {
    return await _superAdminService.getTopDepartments(limit: limit);
  }

  // Get top levels
  Future<List<Map<String, dynamic>>> getTopLevels({int limit = 10}) async {
    return await _superAdminService.getTopLevels(limit: limit);
  }

  // Get available departments
  Future<List<String>> getAvailableDepartments() async {
    return await _superAdminService.getAvailableDepartments();
  }

  // Get available levels
  Future<List<String>> getAvailableLevels() async {
    return await _superAdminService.getAvailableLevels();
  }
}
