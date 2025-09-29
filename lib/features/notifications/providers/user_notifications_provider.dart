import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/notifications/services/user_notifications_service.dart';
import 'package:pivot/features/notifications/repositories/user_notifications_repository.dart';
import 'package:pivot/models/scheduled_notification.dart';

// Services
final userNotificationsServiceProvider = Provider<UserNotificationsService>((
  ref,
) {
  return UserNotificationsService();
});

// Repositories
final userNotificationsRepositoryProvider =
    Provider<UserNotificationsRepository>((ref) {
      final service = ref.watch(userNotificationsServiceProvider);
      return UserNotificationsRepository(service);
    });

// State classes
class UserNotificationsState {
  final bool isLoading;
  final String? error;
  final List<ScheduledNotification> notifications;
  final List<ScheduledNotification> filteredNotifications;
  final Map<String, dynamic>? statistics;
  final String searchQuery;
  final String? selectedType;
  final DateTime? selectedDateRange;
  final bool hasNotifications;
  final bool hasUnreadNotifications;

  const UserNotificationsState({
    this.isLoading = false,
    this.error,
    this.notifications = const [],
    this.filteredNotifications = const [],
    this.statistics,
    this.searchQuery = '',
    this.selectedType,
    this.selectedDateRange,
    this.hasNotifications = false,
    this.hasUnreadNotifications = false,
  });

  UserNotificationsState copyWith({
    bool? isLoading,
    String? error,
    List<ScheduledNotification>? notifications,
    List<ScheduledNotification>? filteredNotifications,
    Map<String, dynamic>? statistics,
    String? searchQuery,
    String? selectedType,
    DateTime? selectedDateRange,
    bool? hasNotifications,
    bool? hasUnreadNotifications,
  }) {
    return UserNotificationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      notifications: notifications ?? this.notifications,
      filteredNotifications:
          filteredNotifications ?? this.filteredNotifications,
      statistics: statistics ?? this.statistics,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      hasNotifications: hasNotifications ?? this.hasNotifications,
      hasUnreadNotifications:
          hasUnreadNotifications ?? this.hasUnreadNotifications,
    );
  }
}

// Notifier
class UserNotificationsNotifier extends StateNotifier<UserNotificationsState> {
  final UserNotificationsRepository _repository;

  UserNotificationsNotifier(this._repository)
    : super(const UserNotificationsState());

  // Get user notifications
  Future<void> getUserNotifications({int limit = 50}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _repository.getUserNotifications(
        limit: limit,
      );
      state = state.copyWith(
        isLoading: false,
        notifications: notifications,
        hasNotifications: notifications.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get unread notifications
  Future<void> getUnreadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _repository.getUnreadNotifications();
      state = state.copyWith(
        isLoading: false,
        filteredNotifications: notifications,
        hasUnreadNotifications: notifications.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.markNotificationAsRead(notificationId);
      if (success) {
        await getUserNotifications(); // Refresh notifications
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Mark multiple notifications as read
  Future<bool> markMultipleNotificationsAsRead(
    List<String> notificationIds,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.markMultipleNotificationsAsRead(
        notificationIds,
      );
      if (success) {
        await getUserNotifications(); // Refresh notifications
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.markAllNotificationsAsRead();
      if (success) {
        await getUserNotifications(); // Refresh notifications
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.deleteNotification(notificationId);
      if (success) {
        await getUserNotifications(); // Refresh notifications
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Delete multiple notifications
  Future<bool> deleteMultipleNotifications(List<String> notificationIds) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.deleteMultipleNotifications(
        notificationIds,
      );
      if (success) {
        await getUserNotifications(); // Refresh notifications
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Get notification by ID
  Future<ScheduledNotification?> getNotificationById(
    String notificationId,
  ) async {
    try {
      return await _repository.getNotificationById(notificationId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Search notifications
  Future<void> searchNotifications(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final notifications = await _repository.searchNotifications(query);
      state = state.copyWith(
        isLoading: false,
        filteredNotifications: notifications,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get notifications by type
  Future<void> getNotificationsByType(String type) async {
    state = state.copyWith(isLoading: true, error: null, selectedType: type);
    try {
      final notifications = await _repository.getNotificationsByType(type);
      state = state.copyWith(
        isLoading: false,
        filteredNotifications: notifications,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get notifications by date range
  Future<void> getNotificationsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedDateRange: startDate,
    );
    try {
      final notifications = await _repository.getNotificationsByDateRange(
        startDate,
        endDate,
      );
      state = state.copyWith(
        isLoading: false,
        filteredNotifications: notifications,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get notification statistics
  Future<void> getNotificationStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statistics = await _repository.getNotificationStatistics();
      state = state.copyWith(isLoading: false, statistics: statistics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get recent notifications
  Future<List<ScheduledNotification>> getRecentNotifications({
    int limit = 10,
  }) async {
    try {
      return await _repository.getRecentNotifications(limit: limit);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Create notification (for testing/admin purposes)
  Future<bool> createNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required List<String> targetUserIds,
    bool sendToAllUsers = false,
    String? department,
    String? level,
    Map<String, dynamic>? additionalData,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.createNotification(
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        targetUserIds: targetUserIds,
        sendToAllUsers: sendToAllUsers,
        department: department,
        level: level,
        additionalData: additionalData,
      );
      if (success) {
        await getUserNotifications(); // Refresh notifications
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update notification preferences
  Future<bool> updateNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.updateNotificationPreferences(
        preferences,
      );
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Get notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      return await _repository.getNotificationPreferences();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {};
    }
  }

  // Filter notifications locally
  void filterNotifications({String? query, String? type, DateTime? dateRange}) {
    List<ScheduledNotification> filtered = state.notifications;

    // Filter by search query
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      filtered =
          filtered.where((notification) {
            return notification.title.toLowerCase().contains(lowercaseQuery) ||
                notification.body.toLowerCase().contains(lowercaseQuery);
          }).toList();
    }

    // Filter by type
    if (type != null && type.isNotEmpty) {
      filtered =
          filtered.where((notification) {
            return notification.additionalData?['type'] == type;
          }).toList();
    }

    // Filter by date range
    if (dateRange != null) {
      final startOfDay = DateTime(
        dateRange.year,
        dateRange.month,
        dateRange.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));
      filtered =
          filtered.where((notification) {
            return notification.scheduledTime.isAfter(startOfDay) &&
                notification.scheduledTime.isBefore(endOfDay);
          }).toList();
    }

    state = state.copyWith(
      filteredNotifications: filtered,
      searchQuery: query ?? state.searchQuery,
      selectedType: type ?? state.selectedType,
      selectedDateRange: dateRange ?? state.selectedDateRange,
    );
  }

  // Clear filters
  void clearFilters() {
    state = state.copyWith(
      filteredNotifications: state.notifications,
      searchQuery: '',
      selectedType: null,
      selectedDateRange: null,
    );
  }
}

// Providers
final userNotificationsProvider = AutoDisposeStateNotifierProvider<
  UserNotificationsNotifier,
  UserNotificationsState
>((ref) {
  final repository = ref.watch(userNotificationsRepositoryProvider);
  return UserNotificationsNotifier(repository);
});

// Convenience providers for specific data
final notificationsListProvider =
    AutoDisposeProvider<List<ScheduledNotification>>((ref) {
      final state = ref.watch(userNotificationsProvider);
      return state.notifications;
    });

final filteredNotificationsProvider =
    AutoDisposeProvider<List<ScheduledNotification>>((ref) {
      final state = ref.watch(userNotificationsProvider);
      return state.filteredNotifications;
    });

final notificationStatisticsProvider =
    AutoDisposeProvider<Map<String, dynamic>?>((ref) {
      final state = ref.watch(userNotificationsProvider);
      return state.statistics;
    });

final notificationsSearchQueryProvider = AutoDisposeProvider<String>((ref) {
  final state = ref.watch(userNotificationsProvider);
  return state.searchQuery;
});

final notificationsSelectedTypeProvider = AutoDisposeProvider<String?>((ref) {
  final state = ref.watch(userNotificationsProvider);
  return state.selectedType;
});

final notificationsSelectedDateRangeProvider = AutoDisposeProvider<DateTime?>((
  ref,
) {
  final state = ref.watch(userNotificationsProvider);
  return state.selectedDateRange;
});

final notificationsHasNotificationsProvider = AutoDisposeProvider<bool>((ref) {
  final state = ref.watch(userNotificationsProvider);
  return state.hasNotifications;
});

final notificationsHasUnreadProvider = AutoDisposeProvider<bool>((ref) {
  final state = ref.watch(userNotificationsProvider);
  return state.hasUnreadNotifications;
});
