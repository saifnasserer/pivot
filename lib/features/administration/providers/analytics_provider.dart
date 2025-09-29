import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/administration/services/analytics_service.dart';
import 'package:pivot/features/administration/repositories/analytics_repository.dart';

// Services
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// Repositories
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  return AnalyticsRepository(service);
});

// State classes
class AnalyticsState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? userAnalytics;
  final Map<String, dynamic>? contentAnalytics;
  final Map<String, dynamic>? engagementAnalytics;
  final Map<String, dynamic>? growthAnalytics;
  final Map<String, dynamic>? systemHealthAnalytics;

  const AnalyticsState({
    this.isLoading = false,
    this.error,
    this.userAnalytics,
    this.contentAnalytics,
    this.engagementAnalytics,
    this.growthAnalytics,
    this.systemHealthAnalytics,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? userAnalytics,
    Map<String, dynamic>? contentAnalytics,
    Map<String, dynamic>? engagementAnalytics,
    Map<String, dynamic>? growthAnalytics,
    Map<String, dynamic>? systemHealthAnalytics,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      userAnalytics: userAnalytics ?? this.userAnalytics,
      contentAnalytics: contentAnalytics ?? this.contentAnalytics,
      engagementAnalytics: engagementAnalytics ?? this.engagementAnalytics,
      growthAnalytics: growthAnalytics ?? this.growthAnalytics,
      systemHealthAnalytics:
          systemHealthAnalytics ?? this.systemHealthAnalytics,
    );
  }
}

// Notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsNotifier(this._repository) : super(const AnalyticsState());

  // Get user analytics
  Future<void> getUserAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userAnalytics = await _repository.getUserAnalytics();
      state = state.copyWith(isLoading: false, userAnalytics: userAnalytics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get content analytics
  Future<void> getContentAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final contentAnalytics = await _repository.getContentAnalytics();
      state = state.copyWith(
        isLoading: false,
        contentAnalytics: contentAnalytics,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get engagement analytics
  Future<void> getEngagementAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final engagementAnalytics = await _repository.getEngagementAnalytics();
      state = state.copyWith(
        isLoading: false,
        engagementAnalytics: engagementAnalytics,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get growth analytics
  Future<void> getGrowthAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final growthAnalytics = await _repository.getGrowthAnalytics();
      state = state.copyWith(
        isLoading: false,
        growthAnalytics: growthAnalytics,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get system health analytics
  Future<void> getSystemHealthAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final systemHealthAnalytics =
          await _repository.getSystemHealthAnalytics();
      state = state.copyWith(
        isLoading: false,
        systemHealthAnalytics: systemHealthAnalytics,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load all analytics data
  Future<void> loadAllAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repository.getUserAnalytics(),
        _repository.getContentAnalytics(),
        _repository.getEngagementAnalytics(),
        _repository.getGrowthAnalytics(),
        _repository.getSystemHealthAnalytics(),
      ]);

      state = state.copyWith(
        isLoading: false,
        userAnalytics: results[0],
        contentAnalytics: results[1],
        engagementAnalytics: results[2],
        growthAnalytics: results[3],
        systemHealthAnalytics: results[4],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Providers
final analyticsProvider =
    AutoDisposeStateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
      final repository = ref.watch(analyticsRepositoryProvider);
      return AnalyticsNotifier(repository);
    });

// Convenience providers for specific data
final userAnalyticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((ref) {
  final state = ref.watch(analyticsProvider);
  return state.userAnalytics;
});

final contentAnalyticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(analyticsProvider);
  return state.contentAnalytics;
});

final engagementAnalyticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(analyticsProvider);
  return state.engagementAnalytics;
});

final growthAnalyticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(analyticsProvider);
  return state.growthAnalytics;
});

final systemHealthAnalyticsProvider =
    AutoDisposeProvider<Map<String, dynamic>?>((ref) {
      final state = ref.watch(analyticsProvider);
      return state.systemHealthAnalytics;
    });
