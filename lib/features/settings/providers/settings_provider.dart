import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/settings/repositories/settings_repository.dart';
import 'package:pivot/features/settings/services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsRepository(service);
});

class SettingsState {
  final Map<String, int> sectionCounts;
  final bool isLoading;
  final String? error;
  final bool showTeamFormationButton;

  const SettingsState({
    this.sectionCounts = const {},
    this.isLoading = false,
    this.error,
    this.showTeamFormationButton = false,
  });

  SettingsState copyWith({
    Map<String, int>? sectionCounts,
    bool? isLoading,
    String? error,
    bool? showTeamFormationButton,
  }) => SettingsState(
    sectionCounts: sectionCounts ?? this.sectionCounts,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    showTeamFormationButton:
        showTeamFormationButton ?? this.showTeamFormationButton,
  );
}

final settingsProvider =
    StateNotifierProvider.autoDispose<SettingsNotifier, SettingsState>(
      (ref) => SettingsNotifier(ref),
    );

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._ref) : super(const SettingsState());

  final Ref _ref;
  late final SettingsRepository _repo = _ref.read(settingsRepositoryProvider);

  Future<void> fetchSectionCounts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sectionCounts = await _repo.fetchSectionCounts();
      state = state.copyWith(isLoading: false, sectionCounts: sectionCounts);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchTeamFormationButtonVisibility() async {
    try {
      final showButton = await _repo.fetchTeamFormationButtonVisibility();
      state = state.copyWith(showTeamFormationButton: showButton);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateSectionCount(String section, int count) async {
    try {
      await _repo.updateSectionCount(section, count);
      // Refresh section counts
      await fetchSectionCounts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateTeamFormationButtonVisibility(bool show) async {
    try {
      await _repo.updateTeamFormationButtonVisibility(show);
      state = state.copyWith(showTeamFormationButton: show);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
