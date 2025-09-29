import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/profile/repositories/profile_repository.dart';
import 'package:pivot/features/profile/services/profile_service.dart';
import 'package:pivot/models/user_profile.dart';

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(),
);

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final service = ref.watch(profileServiceProvider);
  return ProfileRepository(service);
});

class ProfileState {
  final UserProfile? userProfile;
  final bool isBiometricEnabled;
  final Map<String, dynamic>? notificationSettings;
  final bool isLoading;
  final String? error;
  final bool isUpdating;

  const ProfileState({
    this.userProfile,
    this.isBiometricEnabled = false,
    this.notificationSettings,
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
  });

  ProfileState copyWith({
    UserProfile? userProfile,
    bool? isBiometricEnabled,
    Map<String, dynamic>? notificationSettings,
    bool? isLoading,
    String? error,
    bool? isUpdating,
  }) => ProfileState(
    userProfile: userProfile ?? this.userProfile,
    isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    notificationSettings: notificationSettings ?? this.notificationSettings,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    isUpdating: isUpdating ?? this.isUpdating,
  );
}

final profileProvider =
    StateNotifierProvider.autoDispose<ProfileNotifier, ProfileState>(
      (ref) => ProfileNotifier(ref),
    );

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._ref) : super(const ProfileState());

  final Ref _ref;
  late final ProfileRepository _repo = _ref.read(profileRepositoryProvider);

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userProfile = await _repo.getCurrentUserProfile();
      final isBiometricEnabled = await _repo.isBiometricEnabled();
      final notificationSettings = await _repo.getNotificationSettings();

      state = state.copyWith(
        isLoading: false,
        userProfile: userProfile,
        isBiometricEnabled: isBiometricEnabled,
        notificationSettings: notificationSettings,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile(UserProfile userProfile) async {
    state = state.copyWith(isUpdating: true, error: null);
    try {
      final success = await _repo.updateUserProfile(userProfile);
      if (success) {
        state = state.copyWith(isUpdating: false, userProfile: userProfile);
      }
      return success;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    state = state.copyWith(isUpdating: true, error: null);
    try {
      final success = await _repo.changePassword(currentPassword, newPassword);
      state = state.copyWith(isUpdating: false);
      return success;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateProfileImage(String imageUrl) async {
    state = state.copyWith(isUpdating: true, error: null);
    try {
      final success = await _repo.updateProfileImage(imageUrl);
      if (success && state.userProfile != null) {
        final updatedProfile = state.userProfile!.copyWith(
          profileImageUrl: imageUrl,
        );
        state = state.copyWith(isUpdating: false, userProfile: updatedProfile);
      }
      return success;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }

  Future<bool> toggleBiometricAuth() async {
    state = state.copyWith(isUpdating: true, error: null);
    try {
      final success =
          state.isBiometricEnabled
              ? await _repo.disableBiometricAuth()
              : await _repo.enableBiometricAuth();

      if (success) {
        state = state.copyWith(
          isUpdating: false,
          isBiometricEnabled: !state.isBiometricEnabled,
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateNotificationSettings(Map<String, dynamic> settings) async {
    state = state.copyWith(isUpdating: true, error: null);
    try {
      final success = await _repo.updateNotificationSettings(settings);
      if (success) {
        state = state.copyWith(
          isUpdating: false,
          notificationSettings: settings,
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.logout();
      state = const ProfileState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
