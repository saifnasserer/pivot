import 'package:pivot/features/settings/services/settings_service.dart';
import 'package:pivot/models/user_profile.dart';

class SettingsRepository {
  final SettingsService _settingsService;

  SettingsRepository(this._settingsService);

  // Get user settings from Firestore
  Future<Map<String, dynamic>> getUserSettings() async {
    return await _settingsService.getUserSettings();
  }

  // Update notification preferences
  Future<bool> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    return await _settingsService.updateNotificationPreferences(preferences);
  }

  // Update app settings
  Future<bool> updateAppSettings(Map<String, dynamic> settings) async {
    return await _settingsService.updateAppSettings(settings);
  }

  // Update privacy settings
  Future<bool> updatePrivacySettings(Map<String, dynamic> settings) async {
    return await _settingsService.updatePrivacySettings(settings);
  }

  // Update display settings
  Future<bool> updateDisplaySettings(Map<String, dynamic> settings) async {
    return await _settingsService.updateDisplaySettings(settings);
  }

  // Get local app preferences
  Future<Map<String, dynamic>> getLocalPreferences() async {
    return await _settingsService.getLocalPreferences();
  }

  // Update local app preferences
  Future<bool> updateLocalPreferences(Map<String, dynamic> preferences) async {
    return await _settingsService.updateLocalPreferences(preferences);
  }

  // Reset all settings to default
  Future<bool> resetToDefaults() async {
    return await _settingsService.resetToDefaults();
  }

  // Export settings
  Future<Map<String, dynamic>> exportSettings() async {
    return await _settingsService.exportSettings();
  }

  // Import settings
  Future<bool> importSettings(Map<String, dynamic> settingsData) async {
    return await _settingsService.importSettings(settingsData);
  }

  // Get settings statistics
  Future<Map<String, dynamic>> getSettingsStatistics() async {
    return await _settingsService.getSettingsStatistics();
  }

  // Validate settings
  bool validateSettings(Map<String, dynamic> settings) {
    return _settingsService.validateSettings(settings);
  }
}
