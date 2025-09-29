import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/notifications/services/notifications_service.dart';
import 'package:pivot/features/notifications/repositories/notifications_repository.dart';
import 'package:pivot/models/scheduled_notification.dart';
import 'package:pivot/models/user_notification.dart';

// Services
final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

// Repositories
final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  final service = ref.watch(notificationsServiceProvider);
  return NotificationsRepository(service);
});

// State classes
class NotificationsState {
  final bool isLoading;
  final String? error;
  final List<ScheduledNotification> scheduledNotifications;
  final List<UserNotification> userNotifications;
  final int unreadCount;
  final Map<String, dynamic>? statistics;
  final Map<String, dynamic>? testResults;

  const NotificationsState({
    this.isLoading = false,
    this.error,
    this.scheduledNotifications = const [],
    this.userNotifications = const [],
    this.unreadCount = 0,
    this.statistics,
    this.testResults,
  });

  NotificationsState copyWith({
    bool? isLoading,
    String? error,
    List<ScheduledNotification>? scheduledNotifications,
    List<UserNotification>? userNotifications,
    int? unreadCount,
    Map<String, dynamic>? statistics,
    Map<String, dynamic>? testResults,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      scheduledNotifications:
          scheduledNotifications ?? this.scheduledNotifications,
      userNotifications: userNotifications ?? this.userNotifications,
      unreadCount: unreadCount ?? this.unreadCount,
      statistics: statistics ?? this.statistics,
      testResults: testResults ?? this.testResults,
    );
  }
}

// Notifier
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsNotifier(this._repository) : super(const NotificationsState());

  // Initialize notifications
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.initialize();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Send immediate notification
  Future<bool> sendNotification({
    required String targetToken,
    required String title,
    required String body,
    String? userId,
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.sendNotification(
        targetToken: targetToken,
        title: title,
        body: body,
        userId: userId,
        data: data,
        icon: icon,
        color: color,
        sound: sound,
        imageUrl: imageUrl,
      );
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Send notification to multiple users
  Future<Map<String, dynamic>> sendMultipleNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.sendMultipleNotifications(
        userIds: userIds,
        title: title,
        body: body,
        data: data,
        icon: icon,
        color: color,
        sound: sound,
        imageUrl: imageUrl,
      );
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {
        'success': false,
        'sentCount': 0,
        'totalCount': userIds.length,
        'error': e.toString(),
      };
    }
  }

  // Send notification to all users
  Future<Map<String, dynamic>> sendNotificationToAllUsers({
    required String title,
    required String body,
    Map<String, String>? data,
    String? icon,
    String? color,
    String? sound,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.sendNotificationToAllUsers(
        title: title,
        body: body,
        data: data,
        icon: icon,
        color: color,
        sound: sound,
        imageUrl: imageUrl,
      );
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {
        'success': false,
        'sentCount': 0,
        'totalCount': 0,
        'error': e.toString(),
      };
    }
  }

  // Create scheduled notification
  Future<bool> createScheduledNotification(
    ScheduledNotification notification,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.createScheduledNotification(
        notification,
      );
      if (success) {
        await loadScheduledNotifications();
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Load scheduled notifications
  Future<void> loadScheduledNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _repository.getScheduledNotifications();
      state = state.copyWith(
        isLoading: false,
        scheduledNotifications: notifications,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load pending scheduled notifications
  Future<void> loadPendingScheduledNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications =
          await _repository.getPendingScheduledNotifications();
      state = state.copyWith(
        isLoading: false,
        scheduledNotifications: notifications,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Execute scheduled notification
  Future<bool> executeScheduledNotification(
    ScheduledNotification notification,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.executeScheduledNotification(
        notification,
      );
      if (success) {
        await loadScheduledNotifications();
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Delete scheduled notification
  Future<bool> deleteScheduledNotification(String notificationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.deleteScheduledNotification(
        notificationId,
      );
      if (success) {
        await loadScheduledNotifications();
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Load user notifications
  Future<void> loadUserNotifications(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _repository.getUserNotifications(userId);
      final unreadCount = await _repository.getUnreadNotificationCount(userId);
      state = state.copyWith(
        isLoading: false,
        userNotifications: notifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.markNotificationAsRead(
        userId,
        notificationId,
      );
      if (success) {
        await loadUserNotifications(userId);
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Test notification system
  Future<void> testNotificationSystem() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _repository.testNotificationSystem();
      state = state.copyWith(isLoading: false, testResults: results);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load token statistics
  Future<void> loadTokenStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statistics = await _repository.getTokenStatistics();
      state = state.copyWith(isLoading: false, statistics: statistics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Cleanup invalid tokens
  Future<Map<String, dynamic>> cleanupInvalidTokens() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.cleanupInvalidTokens();
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {
        'totalUsers': 0,
        'cleanedTokens': 0,
        'errors': [e.toString()],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.requestPermissions();
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      return await _repository.areNotificationsEnabled();
    } catch (e) {
      return false;
    }
  }

  // Get current user's FCM token
  Future<String?> getCurrentUserToken() async {
    try {
      return await _repository.getCurrentUserToken();
    } catch (e) {
      return null;
    }
  }

  // Save token to Firestore
  Future<void> saveTokenToFirestore(String token) async {
    try {
      await _repository.saveTokenToFirestore(token);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final notificationsProvider =
    AutoDisposeStateNotifierProvider<NotificationsNotifier, NotificationsState>(
      (ref) {
        final repository = ref.watch(notificationsRepositoryProvider);
        return NotificationsNotifier(repository);
      },
    );

// Convenience providers for specific data
final scheduledNotificationsProvider =
    AutoDisposeProvider<List<ScheduledNotification>>((ref) {
      final state = ref.watch(notificationsProvider);
      return state.scheduledNotifications;
    });

final userNotificationsProvider = AutoDisposeProvider<List<UserNotification>>((
  ref,
) {
  final state = ref.watch(notificationsProvider);
  return state.userNotifications;
});

final unreadNotificationCountProvider = AutoDisposeProvider<int>((ref) {
  final state = ref.watch(notificationsProvider);
  return state.unreadCount;
});

final notificationStatisticsProvider =
    AutoDisposeProvider<Map<String, dynamic>?>((ref) {
      final state = ref.watch(notificationsProvider);
      return state.statistics;
    });

final notificationTestResultsProvider =
    AutoDisposeProvider<Map<String, dynamic>?>((ref) {
      final state = ref.watch(notificationsProvider);
      return state.testResults;
    });
