import 'package:pivot/features/administration/services/analytics_service.dart';

class AnalyticsRepository {
  final AnalyticsService _analyticsService;

  AnalyticsRepository(this._analyticsService);

  // Get user analytics
  Future<Map<String, dynamic>> getUserAnalytics() async {
    return await _analyticsService.getUserAnalytics();
  }

  // Get content analytics
  Future<Map<String, dynamic>> getContentAnalytics() async {
    return await _analyticsService.getContentAnalytics();
  }

  // Get engagement analytics
  Future<Map<String, dynamic>> getEngagementAnalytics() async {
    return await _analyticsService.getEngagementAnalytics();
  }

  // Get growth analytics
  Future<Map<String, dynamic>> getGrowthAnalytics() async {
    return await _analyticsService.getGrowthAnalytics();
  }

  // Get system health analytics
  Future<Map<String, dynamic>> getSystemHealthAnalytics() async {
    return await _analyticsService.getSystemHealthAnalytics();
  }
}
