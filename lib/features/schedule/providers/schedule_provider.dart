import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/schedule/repositories/schedule_repository.dart';
import 'package:pivot/features/schedule/services/schedule_service.dart';
import 'package:pivot/screens/models/schedule_item.dart';

final scheduleServiceProvider = Provider<ScheduleService>(
  (ref) => ScheduleService(),
);

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final service = ref.watch(scheduleServiceProvider);
  return ScheduleRepository(service);
});

class ScheduleState {
  final Map<String, List<ScheduleItem>> schedule;
  final bool isLoading;
  final String? error;
  final List<String> days;

  const ScheduleState({
    this.schedule = const {},
    this.isLoading = false,
    this.error,
    this.days = const [
      'السبت',
      'الاحد',
      'الاثنين',
      'الثلاثاء',
      'الاربعاء',
      'الخميس',
    ],
  });

  ScheduleState copyWith({
    Map<String, List<ScheduleItem>>? schedule,
    bool? isLoading,
    String? error,
    List<String>? days,
  }) => ScheduleState(
    schedule: schedule ?? this.schedule,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    days: days ?? this.days,
  );
}

final scheduleProvider =
    StateNotifierProvider.autoDispose<ScheduleNotifier, ScheduleState>(
      (ref) => ScheduleNotifier(ref),
    );

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  ScheduleNotifier(this._ref) : super(const ScheduleState()) {
    // Automatically load schedule on startup
    fetchSchedule();
  }

  final Ref _ref;
  late final ScheduleRepository _repo = _ref.read(scheduleRepositoryProvider);

  Future<void> fetchSchedule() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schedule = await _repo.fetchSchedule();
      state = state.copyWith(isLoading: false, schedule: schedule);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addScheduleItem(ScheduleItem item) async {
    try {
      await _repo.addScheduleItem(item);
      // Refresh the schedule
      await fetchSchedule();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateScheduleItem(String id, ScheduleItem item) async {
    try {
      await _repo.updateScheduleItem(id, item);
      // Refresh the schedule
      await fetchSchedule();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteScheduleItem(String id) async {
    try {
      await _repo.deleteScheduleItem(id);
      // Refresh the schedule
      await fetchSchedule();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reorderScheduleItems(
    String day,
    List<ScheduleItem> items,
  ) async {
    try {
      await _repo.reorderScheduleItems(day, items);
      // Update local state
      final updatedSchedule = Map<String, List<ScheduleItem>>.from(
        state.schedule,
      );
      updatedSchedule[day] = items;
      state = state.copyWith(schedule: updatedSchedule);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<ScheduleItem> getScheduleForDay(String day) {
    return state.schedule[day] ?? [];
  }

  Future<void> scheduleNotifications() async {
    try {
      await _repo.scheduleNotifications();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cancelNotifications() async {
    try {
      await _repo.cancelNotifications();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleNotification(String itemId) async {
    try {
      // Find the item in the schedule
      ScheduleItem? targetItem;
      String? targetDay;

      for (final day in state.schedule.keys) {
        final items = state.schedule[day] ?? [];
        final item = items.firstWhere(
          (item) => item.id == itemId,
          orElse: () => ScheduleItem.empty(),
        );
        if (item.id.isNotEmpty) {
          targetItem = item;
          targetDay = day;
          break;
        }
      }

      if (targetItem != null && targetDay != null) {
        // Create updated item with toggled notification
        final updatedItem = targetItem.copyWith(
          notificationEnabled: !targetItem.notificationEnabled,
        );

        // Update the item in the repository
        await _repo.updateScheduleItem(itemId, updatedItem);

        // Update local state
        final updatedSchedule = Map<String, List<ScheduleItem>>.from(
          state.schedule,
        );
        final dayItems = List<ScheduleItem>.from(
          updatedSchedule[targetDay] ?? [],
        );
        final itemIndex = dayItems.indexWhere((item) => item.id == itemId);
        if (itemIndex != -1) {
          dayItems[itemIndex] = updatedItem;
          updatedSchedule[targetDay] = dayItems;
          state = state.copyWith(schedule: updatedSchedule);
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
