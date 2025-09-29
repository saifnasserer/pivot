import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/settings/services/settings_service.dart';
import 'package:pivot/features/settings/repositories/settings_repository.dart';
import 'package:pivot/models/user_profile.dart';

// Services
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

// Repositories
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsRepository(service);
});

// State classes
class SettingsState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> userSettings;
  final Map<String, dynamic> localPreferences;
  final Map<String, dynamic>? statistics;
  final bool hasChanges;
  final DateTime? lastUpdated;

  const SettingsState({
    this.isLoading = false,
    this.error,
    this.userSettings = const {},
    this.localPreferences = const {},
    this.statistics,
    this.hasChanges = false,
    this.lastUpdated,
  });

  SettingsState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? userSettings,
    Map<String, dynamic>? localPreferences,
    Map<String, dynamic>? statistics,
    bool? hasChanges,
    DateTime? lastUpdated,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      userSettings: userSettings ?? this.userSettings,
      localPreferences: localPreferences ?? this.localPreferences,
      statistics: statistics ?? this.statistics,
      hasChanges: hasChanges ?? this.hasChanges,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const SettingsState());

  // Get user settings
  Future<void> getUserSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _repository.getUserSettings();
      state = state.copyWith(
        isLoading: false,
        userSettings: settings,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get local preferences
  Future<void> getLocalPreferences() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final preferences = await _repository.getLocalPreferences();
      state = state.copyWith(isLoading: false, localPreferences: preferences);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Update notification preferences
  Future<bool> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.updateNotificationPreferences(
        preferences,
      );
      if (success) {
        await getUserSettings(); // Refresh settings
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update app settings
  Future<bool> updateAppSettings(Map<String, dynamic> settings) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.updateAppSettings(settings);
      if (success) {
        await getUserSettings(); // Refresh settings
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update privacy settings
  Future<bool> updatePrivacySettings(Map<String, dynamic> settings) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.updatePrivacySettings(settings);
      if (success) {
        await getUserSettings(); // Refresh settings
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update display settings
  Future<bool> updateDisplaySettings(Map<String, dynamic> settings) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.updateDisplaySettings(settings);
      if (success) {
        await getUserSettings(); // Refresh settings
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update local preferences
  Future<bool> updateLocalPreferences(Map<String, dynamic> preferences) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.updateLocalPreferences(preferences);
      if (success) {
        await getLocalPreferences(); // Refresh preferences
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Reset to defaults
  Future<bool> resetToDefaults() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.resetToDefaults();
      if (success) {
        await getUserSettings(); // Refresh settings
        await getLocalPreferences(); // Refresh preferences
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Export settings
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      return await _repository.exportSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {};
    }
  }

  // Import settings
  Future<bool> importSettings(Map<String, dynamic> settingsData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.importSettings(settingsData);
      if (success) {
        await getUserSettings(); // Refresh settings
        await getLocalPreferences(); // Refresh preferences
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Get settings statistics
  Future<void> getSettingsStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statistics = await _repository.getSettingsStatistics();
      state = state.copyWith(isLoading: false, statistics: statistics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Validate settings
  bool validateSettings(Map<String, dynamic> settings) {
    return _repository.validateSettings(settings);
  }

  // Mark as having changes
  void markAsChanged() {
    state = state.copyWith(hasChanges: true);
  }

  // Clear changes flag
  void clearChanges() {
    state = state.copyWith(hasChanges: false);
  }
}

// Providers
final settingsProvider =
    AutoDisposeStateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
      final repository = ref.watch(settingsRepositoryProvider);
      return SettingsNotifier(repository);
    });

// Convenience providers for specific data
final userSettingsProvider = AutoDisposeProvider<Map<String, dynamic>>((ref) {
  final state = ref.watch(settingsProvider);
  return state.userSettings;
});

final localPreferencesProvider = AutoDisposeProvider<Map<String, dynamic>>((
  ref,
) {
  final state = ref.watch(settingsProvider);
  return state.localPreferences;
});

final settingsStatisticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(settingsProvider);
  return state.statistics;
});

final settingsHasChangesProvider = AutoDisposeProvider<bool>((ref) {
  final state = ref.watch(settingsProvider);
  return state.hasChanges;
});

final settingsLastUpdatedProvider = AutoDisposeProvider<DateTime?>((ref) {
  final state = ref.watch(settingsProvider);
  return state.lastUpdated;
});
