import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to persist user authentication session for offline access
/// Uses FlutterSecureStorage for secure credential storage
class SessionPersistenceService {
  static final SessionPersistenceService _instance =
      SessionPersistenceService._internal();
  factory SessionPersistenceService() => _instance;
  SessionPersistenceService._internal() {
    // Initialize secure storage with fallback options
    try {
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );
    } catch (e) {
      // Fallback to basic secure storage if initialization fails
      _secureStorage = const FlutterSecureStorage();
    }
  }

  // Using secure storage for sensitive data with fallback options
  late final FlutterSecureStorage _secureStorage;

  // Storage keys
  static const String _userIdKey = 'cached_user_id';
  static const String _userEmailKey = 'cached_user_email';
  static const String _userDisplayNameKey = 'cached_user_display_name';
  static const String _authTokenKey = 'cached_auth_token';
  static const String _lastLoginKey = 'last_login_timestamp';
  static const String _offlineAuthEnabledKey = 'offline_auth_enabled';
  static const String _sessionVersionKey = 'session_version';

  // Session version for cache invalidation if needed
  static const String _currentVersion = '1.0.0';

  /// Save user session for offline access
  /// Call this after successful Firebase authentication
  Future<void> saveUserSession(User user) async {
    try {
      print('💾 Saving user session for offline access: ${user.email}');

      // Get fresh ID token
      final token = await user.getIdToken();

      // Save all user data
      await Future.wait([
        _secureStorage.write(key: _userIdKey, value: user.uid),
        _secureStorage.write(key: _userEmailKey, value: user.email ?? ''),
        _secureStorage.write(
          key: _userDisplayNameKey,
          value: user.displayName ?? '',
        ),
        _secureStorage.write(key: _authTokenKey, value: token ?? ''),
        _secureStorage.write(
          key: _lastLoginKey,
          value: DateTime.now().toIso8601String(),
        ),
        _secureStorage.write(key: _offlineAuthEnabledKey, value: 'true'),
        _secureStorage.write(key: _sessionVersionKey, value: _currentVersion),
      ]);

      print('✅ User session saved successfully');
    } catch (e) {
      print('❌ Error saving session: $e');
      // Don't rethrow - offline mode is optional
    }
  }

  /// Save user session with additional user data
  Future<void> saveUserSessionWithData({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    try {
      print('💾 Saving user session data: $email');

      await Future.wait([
        _secureStorage.write(key: _userIdKey, value: userId),
        _secureStorage.write(key: _userEmailKey, value: email),
        _secureStorage.write(
          key: _userDisplayNameKey,
          value: displayName ?? '',
        ),
        _secureStorage.write(
          key: _lastLoginKey,
          value: DateTime.now().toIso8601String(),
        ),
        _secureStorage.write(key: _offlineAuthEnabledKey, value: 'true'),
        _secureStorage.write(key: _sessionVersionKey, value: _currentVersion),
      ]);

      print('✅ User session data saved successfully');
    } catch (e) {
      print('❌ Error saving session data: $e');
    }
  }

  /// Check if there's a valid cached session
  Future<bool> hasCachedSession() async {
    try {
      final userId = await _secureStorage.read(key: _userIdKey);
      final offlineEnabled = await _secureStorage.read(
        key: _offlineAuthEnabledKey,
      );
      final sessionVersion = await _secureStorage.read(key: _sessionVersionKey);

      // Validate session
      final hasValidSession =
          userId != null &&
          userId.isNotEmpty &&
          offlineEnabled == 'true' &&
          sessionVersion == _currentVersion;

      if (hasValidSession) {
        // Check if session is not expired
        final isExpired = await isSessionExpired();
        return !isExpired;
      }

      return false;
    } catch (e) {
      print('❌ Error checking cached session: $e');
      // If there's an encryption error, the storage might be corrupted
      // Return false to indicate no valid session
      return false;
    }
  }

  /// Get cached user ID for offline access
  Future<String?> getCachedUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (e) {
      print('❌ Error getting cached user ID: $e');
      return null;
    }
  }

  /// Get cached user email
  Future<String?> getCachedUserEmail() async {
    try {
      return await _secureStorage.read(key: _userEmailKey);
    } catch (e) {
      print('❌ Error getting cached user email: $e');
      return null;
    }
  }

  /// Get cached user display name
  Future<String?> getCachedUserDisplayName() async {
    try {
      return await _secureStorage.read(key: _userDisplayNameKey);
    } catch (e) {
      print('❌ Error getting cached user display name: $e');
      return null;
    }
  }

  /// Get cached auth token
  Future<String?> getCachedAuthToken() async {
    try {
      return await _secureStorage.read(key: _authTokenKey);
    } catch (e) {
      print('❌ Error getting cached auth token: $e');
      return null;
    }
  }

  /// Get last login timestamp
  Future<DateTime?> getLastLoginTime() async {
    try {
      final lastLoginStr = await _secureStorage.read(key: _lastLoginKey);
      if (lastLoginStr == null) return null;
      return DateTime.parse(lastLoginStr);
    } catch (e) {
      print('❌ Error getting last login time: $e');
      return null;
    }
  }

  /// Clear session (logout)
  Future<void> clearSession() async {
    try {
      print('🗑️ Clearing user session');
      await _secureStorage.deleteAll();
      print('✅ Session cleared successfully');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }

  /// Check if session is expired (older than 30 days)
  Future<bool> isSessionExpired() async {
    try {
      final lastLoginStr = await _secureStorage.read(key: _lastLoginKey);
      if (lastLoginStr == null) return true;

      final lastLogin = DateTime.parse(lastLoginStr);
      final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;

      // Session expires after 30 days
      final isExpired = daysSinceLogin > 30;

      if (isExpired) {
        print('⏰ Session expired ($daysSinceLogin days old)');
      }

      return isExpired;
    } catch (e) {
      print('❌ Error checking session expiry: $e');
      // If there's an encryption error, assume session is expired/invalid
      return true;
    }
  }

  /// Update last login timestamp (call on app resume or periodic checks)
  Future<void> updateLastLoginTime() async {
    try {
      await _secureStorage.write(
        key: _lastLoginKey,
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('❌ Error updating last login time: $e');
    }
  }

  /// Enable or disable offline authentication
  Future<void> setOfflineAuthEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _offlineAuthEnabledKey,
        value: enabled ? 'true' : 'false',
      );
      print('🔒 Offline auth ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      print('❌ Error setting offline auth: $e');
    }
  }

  /// Get session info for debugging
  Future<Map<String, dynamic>> getSessionInfo() async {
    try {
      final userId = await getCachedUserId();
      final email = await getCachedUserEmail();
      final lastLogin = await getLastLoginTime();
      final hasCached = await hasCachedSession();
      final isExpired = await isSessionExpired();

      return {
        'hasSession': hasCached,
        'isExpired': isExpired,
        'userId': userId,
        'email': email,
        'lastLogin': lastLogin?.toIso8601String(),
        'daysSinceLogin':
            lastLogin != null
                ? DateTime.now().difference(lastLogin).inDays
                : null,
      };
    } catch (e) {
      print('❌ Error getting session info: $e');
      return {'error': e.toString()};
    }
  }

  /// Clear expired sessions
  Future<void> clearExpiredSession() async {
    try {
      final isExpired = await isSessionExpired();
      if (isExpired) {
        await clearSession();
        print('🗑️ Cleared expired session');
      }
    } catch (e) {
      print('❌ Error checking/clearing expired session: $e');
      // If there's an encryption error (like BadPaddingException),
      // it means the storage is corrupted or incompatible
      // Clear all data to start fresh
      try {
        await clearSession();
        print('🗑️ Cleared corrupted session data');
      } catch (clearError) {
        print('❌ Error clearing corrupted session: $clearError');
        // If we can't clear, we'll just continue - the app should still work
      }
    }
  }
}
