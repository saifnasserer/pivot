import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/administration/services/super_admin_service.dart';
import 'package:pivot/features/administration/repositories/super_admin_repository.dart';

// Services
final superAdminServiceProvider = Provider<SuperAdminService>((ref) {
  return SuperAdminService();
});

// Repositories
final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  final service = ref.watch(superAdminServiceProvider);
  return SuperAdminRepository(service);
});

// State classes
class SuperAdminState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? dashboardData;
  final Map<String, dynamic>? userStatistics;
  final Map<String, dynamic>? systemStatistics;
  final List<Map<String, dynamic>>? topDepartments;
  final List<Map<String, dynamic>>? topLevels;
  final List<String>? availableDepartments;
  final List<String>? availableLevels;

  const SuperAdminState({
    this.isLoading = false,
    this.error,
    this.dashboardData,
    this.userStatistics,
    this.systemStatistics,
    this.topDepartments,
    this.topLevels,
    this.availableDepartments,
    this.availableLevels,
  });

  SuperAdminState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? dashboardData,
    Map<String, dynamic>? userStatistics,
    Map<String, dynamic>? systemStatistics,
    List<Map<String, dynamic>>? topDepartments,
    List<Map<String, dynamic>>? topLevels,
    List<String>? availableDepartments,
    List<String>? availableLevels,
  }) {
    return SuperAdminState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      dashboardData: dashboardData ?? this.dashboardData,
      userStatistics: userStatistics ?? this.userStatistics,
      systemStatistics: systemStatistics ?? this.systemStatistics,
      topDepartments: topDepartments ?? this.topDepartments,
      topLevels: topLevels ?? this.topLevels,
      availableDepartments: availableDepartments ?? this.availableDepartments,
      availableLevels: availableLevels ?? this.availableLevels,
    );
  }
}

// Notifier
class SuperAdminNotifier extends StateNotifier<SuperAdminState> {
  final SuperAdminRepository _repository;

  SuperAdminNotifier(this._repository) : super(const SuperAdminState());

  // Fetch dashboard data
  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dashboardData = await _repository.fetchDashboardData();
      state = state.copyWith(isLoading: false, dashboardData: dashboardData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get user statistics
  Future<void> getUserStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userStatistics = await _repository.getUserStatistics();
      state = state.copyWith(isLoading: false, userStatistics: userStatistics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get system statistics
  Future<void> getSystemStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final systemStatistics = await _repository.getSystemStatistics();
      state = state.copyWith(
        isLoading: false,
        systemStatistics: systemStatistics,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get top departments
  Future<void> getTopDepartments({int limit = 5}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final topDepartments = await _repository.getTopDepartments(limit: limit);
      state = state.copyWith(isLoading: false, topDepartments: topDepartments);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get top levels
  Future<void> getTopLevels({int limit = 10}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final topLevels = await _repository.getTopLevels(limit: limit);
      state = state.copyWith(isLoading: false, topLevels: topLevels);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get available departments
  Future<void> getAvailableDepartments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final availableDepartments = await _repository.getAvailableDepartments();
      state = state.copyWith(
        isLoading: false,
        availableDepartments: availableDepartments,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get available levels
  Future<void> getAvailableLevels() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final availableLevels = await _repository.getAvailableLevels();
      state = state.copyWith(
        isLoading: false,
        availableLevels: availableLevels,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Calculate growth rate
  double getGrowthRate() {
    final dashboardData = state.dashboardData;
    if (dashboardData == null) return 0.0;

    final totalUsers = dashboardData['totalUsers'] as int? ?? 0;
    final newUsersThisMonth = dashboardData['newUsersThisMonth'] as int? ?? 0;

    if (totalUsers == 0) return 0.0;
    return (newUsersThisMonth / totalUsers) * 100;
  }

  // Get top departments list
  List<Map<String, dynamic>> getTopDepartmentsList() {
    return state.topDepartments ?? [];
  }

  // Get top levels list
  List<Map<String, dynamic>> getTopLevelsList() {
    return state.topLevels ?? [];
  }
}

// Providers
final superAdminProvider =
    AutoDisposeStateNotifierProvider<SuperAdminNotifier, SuperAdminState>((
      ref,
    ) {
      final repository = ref.watch(superAdminRepositoryProvider);
      return SuperAdminNotifier(repository);
    });

// Convenience providers for specific data
final dashboardDataProvider = AutoDisposeProvider<Map<String, dynamic>?>((ref) {
  final state = ref.watch(superAdminProvider);
  return state.dashboardData;
});

final userStatisticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(superAdminProvider);
  return state.userStatistics;
});

final systemStatisticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(superAdminProvider);
  return state.systemStatistics;
});

final topDepartmentsProvider = AutoDisposeProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final state = ref.watch(superAdminProvider);
  return state.topDepartments ?? [];
});

final topLevelsProvider = AutoDisposeProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final state = ref.watch(superAdminProvider);
  return state.topLevels ?? [];
});

final availableDepartmentsProvider = AutoDisposeProvider<List<String>>((ref) {
  final state = ref.watch(superAdminProvider);
  return state.availableDepartments ?? [];
});

final availableLevelsProvider = AutoDisposeProvider<List<String>>((ref) {
  final state = ref.watch(superAdminProvider);
  return state.availableLevels ?? [];
});
