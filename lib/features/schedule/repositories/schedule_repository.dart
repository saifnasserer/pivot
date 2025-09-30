import 'package:pivot/features/schedule/services/schedule_service.dart';
import 'package:pivot/screens/models/schedule_item.dart';

class ScheduleRepository {
  ScheduleRepository(this._service);

  final ScheduleService _service;

  Future<Map<String, List<ScheduleItem>>> fetchSchedule() =>
      _service.fetchSchedule();

  Future<void> addScheduleItem(ScheduleItem item) =>
      _service.addScheduleItem(item);

  Future<void> updateScheduleItem(String id, ScheduleItem item) =>
      _service.updateScheduleItem(id, item);

  Future<void> deleteScheduleItem(String id) => _service.deleteScheduleItem(id);

  Future<void> reorderScheduleItems(String day, List<ScheduleItem> items) =>
      _service.reorderScheduleItems(day, items);

  Future<void> scheduleNotifications() => _service.scheduleNotifications();

  Future<void> cancelNotifications() => _service.cancelNotifications();
}
