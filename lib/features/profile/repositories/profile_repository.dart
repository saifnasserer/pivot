import 'package:pivot/features/profile/services/profile_service.dart';
import 'package:pivot/models/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._service);

  final ProfileService _service;

  Future<UserProfile?> getCurrentUserProfile() =>
      _service.getCurrentUserProfile();

  Future<bool> updateUserProfile(UserProfile userProfile) =>
      _service.updateUserProfile(userProfile);

  Future<bool> changePassword(String currentPassword, String newPassword) =>
      _service.changePassword(currentPassword, newPassword);

  Future<bool> updateProfileImage(String imageUrl) =>
      _service.updateProfileImage(imageUrl);

  Future<bool> enableBiometricAuth() => _service.enableBiometricAuth();

  Future<bool> disableBiometricAuth() => _service.disableBiometricAuth();

  Future<bool> isBiometricEnabled() => _service.isBiometricEnabled();

  Future<bool> updateNotificationSettings(Map<String, dynamic> settings) =>
      _service.updateNotificationSettings(settings);

  Future<Map<String, dynamic>?> getNotificationSettings() =>
      _service.getNotificationSettings();

  Future<void> clearCache() => _service.clearCache();

  Future<void> logout() => _service.logout();
}
