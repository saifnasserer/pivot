import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivot/models/user_profile.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user settings from Firestore
  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) throw Exception('User document not found');

      final data = doc.data()!;
      return {
        'notificationPreferences': data['notificationPreferences'] ?? {},
        'appSettings': data['appSettings'] ?? {},
        'privacySettings': data['privacySettings'] ?? {},
        'displaySettings': data['displaySettings'] ?? {},
        'lastUpdated': data['lastUpdated'],
      };
    } catch (e) {
      throw Exception('Failed to fetch user settings: $e');
    }
  }

  // Update notification preferences
  Future<bool> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'notificationPreferences': {
          'taskReminders': preferences.taskReminders,
          'classReminders': preferences.classReminders,
          'announcements': preferences.announcements,
          'departmentNotifications': preferences.departmentNotifications,
          'levelNotifications': preferences.levelNotifications,
          'maxNotificationsPerHour': preferences.maxNotificationsPerHour,
          'welcomeNotification': preferences.welcomeNotification,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  // Update app settings
  Future<bool> updateAppSettings(Map<String, dynamic> settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'appSettings': settings,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to update app settings: $e');
    }
  }

  // Update privacy settings
  Future<bool> updatePrivacySettings(Map<String, dynamic> settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'privacySettings': settings,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to update privacy settings: $e');
    }
  }

  // Update display settings
  Future<bool> updateDisplaySettings(Map<String, dynamic> settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'displaySettings': settings,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to update display settings: $e');
    }
  }

  // Get local app preferences
  Future<Map<String, dynamic>> getLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'theme': prefs.getString('theme') ?? 'system',
        'language': prefs.getString('language') ?? 'ar',
        'fontSize': prefs.getDouble('fontSize') ?? 1.0,
        'autoSync': prefs.getBool('autoSync') ?? true,
        'offlineMode': prefs.getBool('offlineMode') ?? false,
        'cacheSize': prefs.getInt('cacheSize') ?? 100,
        'lastSync': prefs.getString('lastSync'),
      };
    } catch (e) {
      throw Exception('Failed to fetch local preferences: $e');
    }
  }

  // Update local app preferences
  Future<bool> updateLocalPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (var entry in preferences.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        }
      }

      return true;
    } catch (e) {
      throw Exception('Failed to update local preferences: $e');
    }
  }

  // Reset all settings to default
  Future<bool> resetToDefaults() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Reset Firestore settings
      await _firestore.collection('users').doc(user.uid).update({
        'notificationPreferences': {
          'taskReminders': true,
          'classReminders': true,
          'announcements': true,
          'departmentNotifications': true,
          'levelNotifications': true,
          'maxNotificationsPerHour': 10,
          'welcomeNotification': true,
        },
        'appSettings': {},
        'privacySettings': {},
        'displaySettings': {},
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Reset local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      return true;
    } catch (e) {
      throw Exception('Failed to reset settings: $e');
    }
  }

  // Export settings
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final userSettings = await getUserSettings();
      final localPreferences = await getLocalPreferences();

      return {
        'userSettings': userSettings,
        'localPreferences': localPreferences,
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
    } catch (e) {
      throw Exception('Failed to export settings: $e');
    }
  }

  // Import settings
  Future<bool> importSettings(Map<String, dynamic> settingsData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Import user settings
      if (settingsData.containsKey('userSettings')) {
        final userSettings =
            settingsData['userSettings'] as Map<String, dynamic>;
        await _firestore.collection('users').doc(user.uid).update(userSettings);
      }

      // Import local preferences
      if (settingsData.containsKey('localPreferences')) {
        final localPreferences =
            settingsData['localPreferences'] as Map<String, dynamic>;
        await updateLocalPreferences(localPreferences);
      }

      return true;
    } catch (e) {
      throw Exception('Failed to import settings: $e');
    }
  }

  // Get settings statistics
  Future<Map<String, dynamic>> getSettingsStatistics() async {
    try {
      final userSettings = await getUserSettings();
      final localPreferences = await getLocalPreferences();

      return {
        'totalSettings': userSettings.length + localPreferences.length,
        'userSettingsCount': userSettings.length,
        'localPreferencesCount': localPreferences.length,
        'lastUpdated': userSettings['lastUpdated'],
        'hasCustomSettings':
            userSettings.isNotEmpty || localPreferences.isNotEmpty,
      };
    } catch (e) {
      throw Exception('Failed to fetch settings statistics: $e');
    }
  }

  // Validate settings
  bool validateSettings(Map<String, dynamic> settings) {
    try {
      // Check required fields
      if (settings.containsKey('notificationPreferences')) {
        final prefs =
            settings['notificationPreferences'] as Map<String, dynamic>;
        if (prefs.containsKey('maxNotificationsPerHour')) {
          final max = prefs['maxNotificationsPerHour'] as int;
          if (max < 1 || max > 100) return false;
        }
      }

      if (settings.containsKey('displaySettings')) {
        final display = settings['displaySettings'] as Map<String, dynamic>;
        if (display.containsKey('fontSize')) {
          final fontSize = display['fontSize'] as double;
          if (fontSize < 0.5 || fontSize > 2.0) return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
