import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../screens/models/schedule_item.dart';

class ScheduleProvider with ChangeNotifier {
  final Map<String, List<ScheduleItem>> _schedule = {};

  final Uuid _uuid = Uuid();

  // Initialize days if needed, or fetch from a source
  final List<String> _days = [
    'السبت',
    'الاحد',
    'الاثنين',
    'الثلاثاء',
    'الاربعاء',
    'الخميس',
  ];

  List<String> get days => _days;

  List<ScheduleItem> getScheduleForDay(String day) {
    return _schedule.putIfAbsent(day, () => []);
  }

  void addScheduleItem({
    required String title,
    required String time,
    required String location,
    required String day,
    required ScheduleItemType type,
  }) {
    final newItem = ScheduleItem(
      id: _uuid.v4(),
      title: title,
      time: time,
      location: location,
      day: day,
      type: type,
    );
    _schedule.putIfAbsent(day, () => []).add(newItem);
    notifyListeners();
  }

  // Optional: Add methods for update/delete later
  void removeScheduleItem(String day, String itemId) {
    _schedule[day]?.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }
}
