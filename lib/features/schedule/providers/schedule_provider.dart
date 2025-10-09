import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/schedule/repositories/schedule_repository.dart';
import 'package:pivot/features/schedule/services/schedule_service.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/services/cache_service.dart';

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

// Removed autoDispose to persist state across app lifecycle
final scheduleProvider = StateNotifierProvider<ScheduleNotifier, ScheduleState>(
  (ref) => ScheduleNotifier(ref),
);

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  ScheduleNotifier(this._ref) : super(const ScheduleState()) {
    // Load from cache on startup (completely local-first)
    _loadFromCacheOnly();
  }

  final Ref _ref;
  late final ScheduleRepository _repo = _ref.read(scheduleRepositoryProvider);

  // Load ONLY from cache (no server fetch) - private method for initialization
  void _loadFromCacheOnly() {
    try {
      final cachedItems = CacheService.instance.getCachedSchedule();
      if (cachedItems.isEmpty) {
        print('📦 ScheduleProvider: No cached schedule found');
        state = state.copyWith(isLoading: false, schedule: {});
        return;
      }

      // Convert cached items to schedule map
      final cachedSchedule = <String, List<ScheduleItem>>{};
      for (var item in cachedItems) {
        cachedSchedule.putIfAbsent(item.day, () => []).add(item);
      }

      // Sort each day's items by order
      for (var entry in cachedSchedule.entries) {
        entry.value.sort((a, b) {
          final aOrder = a.order ?? 0;
          final bOrder = b.order ?? 0;
          return aOrder.compareTo(bOrder);
        });
      }

      print(
        '✅ ScheduleProvider: Loaded ${cachedItems.length} items from cache - Zero server reads',
      );
      state = state.copyWith(isLoading: false, schedule: cachedSchedule);
    } catch (e) {
      print('❌ ScheduleProvider: Error loading from cache - $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Reload from cache (useful when app resumes or data might have changed locally)
  void reloadFromCache() {
    _loadFromCacheOnly();
  }

  // Fetch from server and update cache (called only when needed)
  Future<void> fetchSchedule() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔄 ScheduleProvider: Fetching from server...');
      final schedule = await _repo.fetchSchedule();

      // Cache the fetched schedule
      final allItems = schedule.values.expand((items) => items).toList();
      await CacheService.instance.cacheSchedule(allItems);
      print('💾 ScheduleProvider: Cached ${allItems.length} schedule items');

      if (mounted) {
        state = state.copyWith(isLoading: false, schedule: schedule);
      }
    } catch (e) {
      print('❌ ScheduleProvider: Error fetching schedule - $e');
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> addScheduleItem(ScheduleItem item) async {
    try {
      await _repo.addScheduleItem(item);
      // Force refresh from server and update cache
      await forceRefresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateScheduleItem(String id, ScheduleItem item) async {
    try {
      await _repo.updateScheduleItem(id, item);
      // Force refresh from server and update cache
      await forceRefresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteScheduleItem(String id) async {
    try {
      await _repo.deleteScheduleItem(id);
      // Force refresh from server and update cache
      await forceRefresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Force refresh from server (bypasses cache)
  Future<void> forceRefresh() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔄 ScheduleProvider: Force refreshing from server...');
      final schedule = await _repo.fetchSchedule();

      // Update cache with fresh data
      final allItems = schedule.values.expand((items) => items).toList();
      await CacheService.instance.cacheSchedule(allItems);
      print('💾 ScheduleProvider: Updated cache with ${allItems.length} items');

      if (mounted) {
        state = state.copyWith(isLoading: false, schedule: schedule);
      }
    } catch (e) {
      print('❌ ScheduleProvider: Error force refreshing - $e');
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
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
