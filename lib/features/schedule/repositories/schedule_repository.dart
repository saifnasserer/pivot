import 'package:pivot/features/schedule/services/schedule_service.dart';
import 'package:pivot/screens/models/schedule_item.dart';

class ScheduleRepository {
  final ScheduleService _scheduleService;

  ScheduleRepository(this._scheduleService);

  // Get user's schedule
  Future<Map<String, List<ScheduleItem>>> getUserSchedule() async {
    return await _scheduleService.getUserSchedule();
  }

  // Get schedule for specific day
  Future<List<ScheduleItem>> getScheduleForDay(String day) async {
    return await _scheduleService.getScheduleForDay(day);
  }

  // Add schedule item
  Future<bool> addScheduleItem(ScheduleItem item) async {
    return await _scheduleService.addScheduleItem(item);
  }

  // Update schedule item
  Future<bool> updateScheduleItem(ScheduleItem item) async {
    return await _scheduleService.updateScheduleItem(item);
  }

  // Remove schedule item
  Future<bool> removeScheduleItem(String itemId) async {
    return await _scheduleService.removeScheduleItem(itemId);
  }

  // Toggle notification for schedule item
  Future<bool> toggleNotificationForItem(String itemId, bool enabled) async {
    return await _scheduleService.toggleNotificationForItem(itemId, enabled);
  }

  // Get schedule items by type
  Future<List<ScheduleItem>> getScheduleItemsByType(
    ScheduleItemType type,
  ) async {
    return await _scheduleService.getScheduleItemsByType(type);
  }

  // Search schedule items
  Future<List<ScheduleItem>> searchScheduleItems(String query) async {
    return await _scheduleService.searchScheduleItems(query);
  }

  // Get schedule statistics
  Future<Map<String, dynamic>> getScheduleStatistics() async {
    return await _scheduleService.getScheduleStatistics();
  }

  // Get upcoming schedule items
  Future<List<ScheduleItem>> getUpcomingItems({int limit = 5}) async {
    return await _scheduleService.getUpcomingItems(limit: limit);
  }

  // Get schedule items for date range
  Future<List<ScheduleItem>> getScheduleForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _scheduleService.getScheduleForDateRange(startDate, endDate);
  }

  // Export schedule
  Future<Map<String, dynamic>> exportSchedule() async {
    return await _scheduleService.exportSchedule();
  }

  // Import schedule
  Future<bool> importSchedule(Map<String, dynamic> scheduleData) async {
    return await _scheduleService.importSchedule(scheduleData);
  }

  // Clear all schedule
  Future<bool> clearAllSchedule() async {
    return await _scheduleService.clearAllSchedule();
  }
}
