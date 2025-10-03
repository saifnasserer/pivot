import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/home/repositories/home_repository.dart';
import 'package:pivot/features/home/services/home_service.dart';

final homeServiceProvider = Provider<HomeService>((ref) => HomeService());

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final service = ref.watch(homeServiceProvider);
  return HomeRepository(service);
});

class HomeState {
  final List<String> categories;
  final int currentCategoryIndex;
  final String? userDepartment;
  final String? userLevel;
  final bool isInitialized;
  final bool isTeamFormationEnabled;
  final bool hasUpdates;
  final Map<String, dynamic>? updateInfo;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.categories = const [],
    this.currentCategoryIndex = 0,
    this.userDepartment,
    this.userLevel,
    this.isInitialized = false,
    this.isTeamFormationEnabled = false,
    this.hasUpdates = false,
    this.updateInfo,
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<String>? categories,
    int? currentCategoryIndex,
    String? userDepartment,
    String? userLevel,
    bool? isInitialized,
    bool? isTeamFormationEnabled,
    bool? hasUpdates,
    Map<String, dynamic>? updateInfo,
    bool? isLoading,
    String? error,
  }) => HomeState(
    categories: categories ?? this.categories,
    currentCategoryIndex: currentCategoryIndex ?? this.currentCategoryIndex,
    userDepartment: userDepartment ?? this.userDepartment,
    userLevel: userLevel ?? this.userLevel,
    isInitialized: isInitialized ?? this.isInitialized,
    isTeamFormationEnabled:
        isTeamFormationEnabled ?? this.isTeamFormationEnabled,
    hasUpdates: hasUpdates ?? this.hasUpdates,
    updateInfo: updateInfo ?? this.updateInfo,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );
}

final homeProvider = StateNotifierProvider.autoDispose<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(ref),
);

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this._ref) : super(const HomeState());

  final Ref _ref;
  late final HomeRepository _repo = _ref.read(homeRepositoryProvider);

  Future<void> initialize(String? userDepartment, {String? userLevel}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = _repo.getCategories(
        userDepartment,
        userLevel: userLevel,
      );

      state = state.copyWith(
        isLoading: false,
        categories: categories,
        userDepartment: userDepartment,
        userLevel: userLevel,
        isInitialized: true,
        currentCategoryIndex:
            categories.isNotEmpty
                ? categories.length - 1
                : 0, // Start from rightmost tab (اخبار النهاردة)
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> changeCategory(int index) async {
    if (index >= 0 && index < state.categories.length) {
      state = state.copyWith(currentCategoryIndex: index);
    }
  }

  String? getDepartmentCode(String category) {
    return _repo.getDepartmentCode(category, state.userDepartment);
  }

  String? getTimeFilter(String category) {
    return _repo.getTimeFilter(category);
  }
}
