import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../screens/models/schedule_item.dart';
import '../services/schedule_service.dart';
import 'package:pivot/services/cache_service.dart';

class ScheduleProvider with ChangeNotifier {
  final ScheduleService _scheduleService = ScheduleService();
  Map<String, List<ScheduleItem>> _schedule = {};
  bool _isLoading = false;
  String? _error;

  final Uuid _uuid = Uuid();

  final List<String> _days = [
    'السبت',
    'الاحد',
    'الاثنين',
    'الثلاثاء',
    'الاربعاء',
    'الخميس',
  ];

  List<String> get days => _days;
  Map<String, List<ScheduleItem>> get schedule => _schedule;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ScheduleItem> getScheduleForDay(String day) {
    return _schedule[day] ?? [];
  }

  Future<void> fetchSchedule() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Load from cache first
      final cachedSchedule = CacheService.instance.getCachedSchedule();
      if (cachedSchedule.isNotEmpty) {
        _schedule = {};
        for (var item in cachedSchedule) {
          _schedule.putIfAbsent(item.day, () => []).add(item);
        }
        notifyListeners();
      }

      // Step 2: Fetch from server in the background
      _schedule = await _scheduleService.getSchedule();
      // Flatten schedule to a list for caching
      final allItems = _schedule.values.expand((list) => list).toList();
      await CacheService.instance.cacheSchedule(allItems);
    } catch (e) {
      _error = 'Failed to fetch schedule: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addScheduleItem({
    required String title,
    required String time,
    required String location,
    required String day,
    required ScheduleItemType type,
  }) async {
    final newItem = ScheduleItem(
      id: _uuid.v4(),
      title: title,
      time: time,
      location: location,
      day: day,
      type: type,
    );

    try {
      await _scheduleService.addScheduleItem(newItem);
      _schedule.putIfAbsent(day, () => []).add(newItem);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add item: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> removeScheduleItem(String day, String itemId) async {
    try {
      await _scheduleService.removeScheduleItem(itemId);
      _schedule[day]?.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove item: ${e.toString()}';
      notifyListeners();
    }
  }
}
