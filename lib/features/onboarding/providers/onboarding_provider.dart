import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/onboarding/repositories/onboarding_repository.dart';
import 'package:pivot/features/onboarding/services/onboarding_service.dart';

final onboardingServiceProvider = Provider<OnboardingService>(
  (ref) => OnboardingService(),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final service = ref.watch(onboardingServiceProvider);
  return OnboardingRepository(service);
});

class OnboardingState {
  final bool isFirstRun;
  final bool isIntroShown;
  final String? pendingDeepLink;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.isFirstRun = true,
    this.isIntroShown = false,
    this.pendingDeepLink,
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    bool? isFirstRun,
    bool? isIntroShown,
    String? pendingDeepLink,
    bool? isLoading,
    String? error,
  }) => OnboardingState(
    isFirstRun: isFirstRun ?? this.isFirstRun,
    isIntroShown: isIntroShown ?? this.isIntroShown,
    pendingDeepLink: pendingDeepLink ?? this.pendingDeepLink,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );
}

final onboardingProvider =
    StateNotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>(
      (ref) => OnboardingNotifier(ref),
    );

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._ref) : super(const OnboardingState());

  final Ref _ref;
  late final OnboardingRepository _repo = _ref.read(
    onboardingRepositoryProvider,
  );

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final isFirstRun = await _repo.isFirstRun();
      final isIntroShown = await _repo.isIntroShown();
      final pendingDeepLink = await _repo.getPendingDeepLink();

      state = state.copyWith(
        isLoading: false,
        isFirstRun: isFirstRun,
        isIntroShown: isIntroShown,
        pendingDeepLink: pendingDeepLink,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markFirstRunCompleted() async {
    await _repo.markFirstRunCompleted();
    state = state.copyWith(isFirstRun: false);
  }

  Future<void> markIntroShown() async {
    await _repo.markIntroShown();
    state = state.copyWith(isIntroShown: true);
  }

  Future<void> setPendingDeepLink(String? link) async {
    await _repo.setPendingDeepLink(link);
    state = state.copyWith(pendingDeepLink: link);
  }

  Future<void> clearPendingDeepLink() async {
    await _repo.clearPendingDeepLink();
    state = state.copyWith(pendingDeepLink: null);
  }
}
