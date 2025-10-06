import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'local_auth_service.dart';

class BiometricSettingsService {
  static final BiometricSettingsService _instance =
      BiometricSettingsService._internal();
  factory BiometricSettingsService() => _instance;
  BiometricSettingsService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthService _localAuthService = LocalAuthService();

  // Storage keys
  static const String _biometricEnabledKey = 'isBiometricEnabled';
  static const String _biometricEmailKey = 'biometric_email';
  static const String _biometricPasswordKey = 'biometric_password';
  static const String _biometricSetupDateKey = 'biometric_setup_date';
  static const String _biometricLastUsedKey = 'biometric_last_used';
  static const String _biometricAttemptsKey = 'biometric_attempts';
  static const String _biometricSuccessCountKey = 'biometric_success_count';
  static const String _biometricFailureCountKey = 'biometric_failure_count';

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
      
      if (kDebugMode) {
        print('🔐 [BiometricSettings] Checking if biometric is enabled: $isEnabled');
      }
      
      return isEnabled;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking biometric enabled status: $e');
      }
      return false;
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric(String email, String password) async {
    try {
      if (kDebugMode) {
        print('🔐 [BiometricSettings] Enabling biometric authentication...');
      }
      
      // Check if biometrics are available
      final stats = await _localAuthService.getBiometricStats();
      if (!stats['canAuthenticate']) {
        if (kDebugMode) {
          print('🔐 [BiometricSettings] Biometric not available for authentication');
        }
        return false;
      }

      if (kDebugMode) {
        print('🔐 [BiometricSettings] Storing credentials securely...');
      }

      // Store credentials securely
      await _secureStorage.write(key: _biometricEmailKey, value: email);
      await _secureStorage.write(key: _biometricPasswordKey, value: password);

      if (kDebugMode) {
        print('🔐 [BiometricSettings] Updating settings...');
      }

      // Update settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);
      await prefs.setString(
        _biometricSetupDateKey,
        DateTime.now().toIso8601String(),
      );
      await prefs.setInt(_biometricAttemptsKey, 0);
      await prefs.setInt(_biometricSuccessCountKey, 0);
      await prefs.setInt(_biometricFailureCountKey, 0);

      if (kDebugMode) {
        print('🔐 [BiometricSettings] Biometric authentication enabled successfully!');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error enabling biometric: $e');
      }
      return false;
    }
  }

  /// Disable biometric authentication
  Future<bool> disableBiometric() async {
    try {
      // Remove stored credentials
      await _secureStorage.delete(key: _biometricEmailKey);
      await _secureStorage.delete(key: _biometricPasswordKey);

      // Update settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, false);
      await prefs.remove(_biometricSetupDateKey);
      await prefs.remove(_biometricLastUsedKey);
      await prefs.remove(_biometricAttemptsKey);
      await prefs.remove(_biometricSuccessCountKey);
      await prefs.remove(_biometricFailureCountKey);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error disabling biometric: $e');
      }
      return false;
    }
  }

  /// Get stored biometric credentials
  Future<Map<String, String?>> getBiometricCredentials() async {
    try {
      final email = await _secureStorage.read(key: _biometricEmailKey);
      final password = await _secureStorage.read(key: _biometricPasswordKey);
      return {'email': email, 'password': password};
    } catch (e) {
      if (kDebugMode) {
        print('Error getting biometric credentials: $e');
      }
      return {'email': null, 'password': null};
    }
  }

  /// Update biometric credentials
  Future<bool> updateBiometricCredentials(String email, String password) async {
    try {
      await _secureStorage.write(key: _biometricEmailKey, value: email);
      await _secureStorage.write(key: _biometricPasswordKey, value: password);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating biometric credentials: $e');
      }
      return false;
    }
  }

  /// Record biometric authentication attempt
  Future<void> recordBiometricAttempt(bool success) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update attempt count
      final attempts = prefs.getInt(_biometricAttemptsKey) ?? 0;
      await prefs.setInt(_biometricAttemptsKey, attempts + 1);

      // Update success/failure count
      if (success) {
        final successCount = prefs.getInt(_biometricSuccessCountKey) ?? 0;
        await prefs.setInt(_biometricSuccessCountKey, successCount + 1);
      } else {
        final failureCount = prefs.getInt(_biometricFailureCountKey) ?? 0;
        await prefs.setInt(_biometricFailureCountKey, failureCount + 1);
      }

      // Update last used timestamp
      await prefs.setString(
        _biometricLastUsedKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error recording biometric attempt: $e');
      }
    }
  }

  /// Get biometric usage statistics
  Future<Map<String, dynamic>> getBiometricStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceStats = await _localAuthService.getBiometricStats();

      final attempts = prefs.getInt(_biometricAttemptsKey) ?? 0;
      final successCount = prefs.getInt(_biometricSuccessCountKey) ?? 0;
      final failureCount = prefs.getInt(_biometricFailureCountKey) ?? 0;
      final setupDate = prefs.getString(_biometricSetupDateKey);
      final lastUsed = prefs.getString(_biometricLastUsedKey);

      final successRate = attempts > 0 ? (successCount / attempts) * 100 : 0.0;

      return {
        'isEnabled': await isBiometricEnabled(),
        'deviceStats': deviceStats,
        'attempts': attempts,
        'successCount': successCount,
        'failureCount': failureCount,
        'successRate': successRate,
        'setupDate': setupDate,
        'lastUsed': lastUsed,
        'hasCredentials': (await getBiometricCredentials())['email'] != null,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting biometric stats: $e');
      }
      return {
        'isEnabled': false,
        'deviceStats': {},
        'attempts': 0,
        'successCount': 0,
        'failureCount': 0,
        'successRate': 0.0,
        'setupDate': null,
        'lastUsed': null,
        'hasCredentials': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if biometric authentication should be available
  Future<bool> canUseBiometric() async {
    try {
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) return false;

      final credentials = await getBiometricCredentials();
      if (credentials['email'] == null || credentials['password'] == null) {
        return false;
      }

      final deviceStats = await _localAuthService.getBiometricStats();
      return deviceStats['canAuthenticate'] ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking biometric availability: $e');
      }
      return false;
    }
  }

  /// Get biometric setup information
  Future<Map<String, dynamic>> getBiometricSetupInfo() async {
    try {
      final stats = await getBiometricStats();
      final deviceStats = stats['deviceStats'] as Map<String, dynamic>;

      return {
        'isEnabled': stats['isEnabled'],
        'canUse': await canUseBiometric(),
        'deviceSupported': deviceStats['isSupported'] ?? false,
        'deviceEnrolled': deviceStats['isEnrolled'] ?? false,
        'primaryType': deviceStats['primaryTypeName'] ?? 'غير معروف',
        'setupDate': stats['setupDate'],
        'lastUsed': stats['lastUsed'],
        'successRate': stats['successRate'],
        'totalAttempts': stats['attempts'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting biometric setup info: $e');
      }
      return {
        'isEnabled': false,
        'canUse': false,
        'deviceSupported': false,
        'deviceEnrolled': false,
        'primaryType': 'غير معروف',
        'setupDate': null,
        'lastUsed': null,
        'successRate': 0.0,
        'totalAttempts': 0,
        'error': e.toString(),
      };
    }
  }

  /// Clear all biometric data (for account deletion)
  Future<void> clearAllBiometricData() async {
    try {
      await disableBiometric();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing biometric data: $e');
      }
    }
  }
}
