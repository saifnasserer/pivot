import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/services/local_auth_service.dart';

class ProfileService {
  final AuthService _authService = AuthService();
  final LocalAuthService _localAuthService = LocalAuthService();

  Future<UserProfile?> getCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await _authService.getUserProfile(user.uid);
    }
    return null;
  }

  Future<bool> updateUserProfile(UserProfile userProfile) async {
    try {
      await _authService.createUserProfile(userProfile);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          ),
        );
        await user.updatePassword(newPassword);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfileImage(String imageUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePhotoURL(imageUrl);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> enableBiometricAuth() async {
    return await _localAuthService.isBiometricSupported();
  }

  Future<bool> disableBiometricAuth() async {
    // Biometric auth is controlled by system settings
    return true;
  }

  Future<bool> isBiometricEnabled() async {
    return await _localAuthService.isBiometricEnrolled();
  }

  Future<bool> updateNotificationSettings(Map<String, dynamic> settings) async {
    // Notification settings would be handled by a notification service
    // For now, return true as placeholder
    return true;
  }

  Future<Map<String, dynamic>?> getNotificationSettings() async {
    // Return default notification settings
    return {
      'notifications_enabled': true,
      'sound_enabled': true,
      'vibration_enabled': true,
    };
  }

  Future<void> clearCache() async {
    await CacheService.instance.clearAllCache();
  }

  Future<void> logout() async {
    await _authService.signOut();
    await clearCache();
  }
}
