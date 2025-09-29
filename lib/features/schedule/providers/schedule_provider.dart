import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/schedule/services/schedule_service.dart';
import 'package:pivot/features/schedule/repositories/schedule_repository.dart';
import 'package:pivot/screens/models/schedule_item.dart';

// Services
final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});

// Repositories
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final service = ref.watch(scheduleServiceProvider);
  return ScheduleRepository(service);
});

// State classes
class ScheduleState {
  final bool isLoading;
  final String? error;
  final Map<String, List<ScheduleItem>> schedule;
  final List<ScheduleItem> filteredItems;
  final Map<String, dynamic>? statistics;
  final String searchQuery;
  final String? selectedDay;
  final ScheduleItemType? selectedType;
  final bool hasSchedule;

  const ScheduleState({
    this.isLoading = false,
    this.error,
    this.schedule = const {},
    this.filteredItems = const [],
    this.statistics,
    this.searchQuery = '',
    this.selectedDay,
    this.selectedType,
    this.hasSchedule = false,
  });

  ScheduleState copyWith({
    bool? isLoading,
    String? error,
    Map<String, List<ScheduleItem>>? schedule,
    List<ScheduleItem>? filteredItems,
    Map<String, dynamic>? statistics,
    String? searchQuery,
    String? selectedDay,
    ScheduleItemType? selectedType,
    bool? hasSchedule,
  }) {
    return ScheduleState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      schedule: schedule ?? this.schedule,
      filteredItems: filteredItems ?? this.filteredItems,
      statistics: statistics ?? this.statistics,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDay: selectedDay ?? this.selectedDay,
      selectedType: selectedType ?? this.selectedType,
      hasSchedule: hasSchedule ?? this.hasSchedule,
    );
  }
}

// Notifier
class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleNotifier(this._repository) : super(const ScheduleState());

  // Get user schedule
  Future<void> getUserSchedule() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schedule = await _repository.getUserSchedule();
      state = state.copyWith(
        isLoading: false,
        schedule: schedule,
        hasSchedule: schedule.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get schedule for specific day
  Future<void> getScheduleForDay(String day) async {
    state = state.copyWith(isLoading: true, error: null, selectedDay: day);
    try {
      final items = await _repository.getScheduleForDay(day);
      state = state.copyWith(isLoading: false, filteredItems: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Add schedule item
  Future<bool> addScheduleItem(ScheduleItem item) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.addScheduleItem(item);
      if (success) {
        await getUserSchedule(); // Refresh schedule
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update schedule item
  Future<bool> updateScheduleItem(ScheduleItem item) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.updateScheduleItem(item);
      if (success) {
        await getUserSchedule(); // Refresh schedule
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Remove schedule item
  Future<bool> removeScheduleItem(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.removeScheduleItem(itemId);
      if (success) {
        await getUserSchedule(); // Refresh schedule
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Toggle notification for schedule item
  Future<bool> toggleNotificationForItem(String itemId, bool enabled) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.toggleNotificationForItem(
        itemId,
        enabled,
      );
      if (success) {
        await getUserSchedule(); // Refresh schedule
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Get schedule items by type
  Future<void> getScheduleItemsByType(ScheduleItemType type) async {
    state = state.copyWith(isLoading: true, error: null, selectedType: type);
    try {
      final items = await _repository.getScheduleItemsByType(type);
      state = state.copyWith(isLoading: false, filteredItems: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Search schedule items
  Future<void> searchScheduleItems(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final items = await _repository.searchScheduleItems(query);
      state = state.copyWith(isLoading: false, filteredItems: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get schedule statistics
  Future<void> getScheduleStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statistics = await _repository.getScheduleStatistics();
      state = state.copyWith(isLoading: false, statistics: statistics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get upcoming schedule items
  Future<List<ScheduleItem>> getUpcomingItems({int limit = 5}) async {
    try {
      return await _repository.getUpcomingItems(limit: limit);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Get schedule items for date range
  Future<List<ScheduleItem>> getScheduleForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _repository.getScheduleForDateRange(startDate, endDate);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Export schedule
  Future<Map<String, dynamic>> exportSchedule() async {
    try {
      return await _repository.exportSchedule();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {};
    }
  }

  // Import schedule
  Future<bool> importSchedule(Map<String, dynamic> scheduleData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.importSchedule(scheduleData);
      if (success) {
        await getUserSchedule(); // Refresh schedule
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Clear all schedule
  Future<bool> clearAllSchedule() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.clearAllSchedule();
      if (success) {
        await getUserSchedule(); // Refresh schedule
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Filter schedule items locally
  void filterScheduleItems({
    String? query,
    String? day,
    ScheduleItemType? type,
  }) {
    List<ScheduleItem> filtered = [];

    // Get all items from schedule
    for (var dayItems in state.schedule.values) {
      filtered.addAll(dayItems);
    }

    // Filter by search query
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      filtered =
          filtered.where((item) {
            return item.title.toLowerCase().contains(lowercaseQuery) ||
                item.location.toLowerCase().contains(lowercaseQuery);
          }).toList();
    }

    // Filter by day
    if (day != null && day.isNotEmpty) {
      filtered = filtered.where((item) => item.day == day).toList();
    }

    // Filter by type
    if (type != null) {
      filtered = filtered.where((item) => item.type == type).toList();
    }

    state = state.copyWith(
      filteredItems: filtered,
      searchQuery: query ?? state.searchQuery,
      selectedDay: day ?? state.selectedDay,
      selectedType: type ?? state.selectedType,
    );
  }

  // Clear filters
  void clearFilters() {
    state = state.copyWith(
      filteredItems: [],
      searchQuery: '',
      selectedDay: null,
      selectedType: null,
    );
  }
}

// Providers
final scheduleProvider =
    AutoDisposeStateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
      final repository = ref.watch(scheduleRepositoryProvider);
      return ScheduleNotifier(repository);
    });

// Convenience providers for specific data
final scheduleMapProvider =
    AutoDisposeProvider<Map<String, List<ScheduleItem>>>((ref) {
      final state = ref.watch(scheduleProvider);
      return state.schedule;
    });

final filteredScheduleItemsProvider = AutoDisposeProvider<List<ScheduleItem>>((
  ref,
) {
  final state = ref.watch(scheduleProvider);
  return state.filteredItems;
});

final scheduleStatisticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(scheduleProvider);
  return state.statistics;
});

final scheduleSearchQueryProvider = AutoDisposeProvider<String>((ref) {
  final state = ref.watch(scheduleProvider);
  return state.searchQuery;
});

final scheduleSelectedDayProvider = AutoDisposeProvider<String?>((ref) {
  final state = ref.watch(scheduleProvider);
  return state.selectedDay;
});

final scheduleSelectedTypeProvider = AutoDisposeProvider<ScheduleItemType?>((
  ref,
) {
  final state = ref.watch(scheduleProvider);
  return state.selectedType;
});

final scheduleHasScheduleProvider = AutoDisposeProvider<bool>((ref) {
  final state = ref.watch(scheduleProvider);
  return state.hasSchedule;
});
