import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RemoteConfigService {
  // Private constructor
  RemoteConfigService._();

  // Static instance of the class
  static final RemoteConfigService _instance = RemoteConfigService._();

  // Getter to access the instance
  static RemoteConfigService get instance => _instance;

  late final FirebaseRemoteConfig _remoteConfig;

  // Default values
  final Map<String, dynamic> _defaultConfig = {
    'welcome_message': 'Welcome to our app!',
    'feature_enabled': false,
    // Update management defaults
    'app_update_force': false,
    'app_update_message': 'تحديث جديد متاح للتطبيق',
    'app_update_title': 'تحديث التطبيق',
    'app_update_download_url': '',
    'app_update_version': '1.0.0',
    'app_update_changelog': 'تحسينات عامة وإصلاحات للأخطاء',
    'show_update_button': false, // Default to false, controlled by admin
  };

  // Getters for remote config values
  String get welcomeMessage => _remoteConfig.getString('welcome_message');
  bool get isFeatureEnabled => _remoteConfig.getBool('feature_enabled');

  // Update management getters
  bool get isUpdateForce {
    final value = _remoteConfig.getBool('app_update_force');
    print('🔍 [RemoteConfig] Reading app_update_force: $value');
    return value;
  }

  String get updateMessage {
    final value = _remoteConfig.getString('app_update_message');
    print('🔍 [RemoteConfig] Reading app_update_message: $value');
    return value;
  }

  String get updateTitle {
    final value = _remoteConfig.getString('app_update_title');
    print('🔍 [RemoteConfig] Reading app_update_title: $value');
    return value;
  }

  String get updateDownloadUrl {
    final value = _remoteConfig.getString('app_update_download_url');
    print('🔍 [RemoteConfig] Reading app_update_download_url: $value');
    return value;
  }

  String get updateVersion {
    final value = _remoteConfig.getString('app_update_version');
    print('🔍 [RemoteConfig] Reading app_update_version: $value');
    return value;
  }

  String get updateChangelog {
    final value = _remoteConfig.getString('app_update_changelog');
    print('🔍 [RemoteConfig] Reading app_update_changelog: $value');
    return value;
  }

  bool get showUpdateButton {
    try {
      final value = _remoteConfig.getBool('show_update_button');
      print('🔍 [RemoteConfig] Reading show_update_button: $value');
      return value;
    } catch (e) {
      print(
        '🔍 [RemoteConfig] Error reading show_update_button, using default: false',
      );
      return false;
    }
  }

  Future<void> initialize() async {
    _remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 12),
        ),
      );
    } catch (e) {
      print('Error setting remote config settings: $e');
    }

    try {
      await _remoteConfig.setDefaults(_defaultConfig);
    } catch (e) {
      print('Error setting remote config defaults: $e');
    }

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Error fetching & activating remote config: $e');
    }
  }

  // Forces a fetch and activation of the remote config, bypassing the cache.
  Future<bool> forceFetch() async {
    try {
      // Temporarily set a zero fetch interval to force a fetch.
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: Duration.zero,
        ),
      );
      await _remoteConfig.fetchAndActivate();

      // IMPORTANT: Reset the fetch interval to the default to avoid throttling.
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 12),
        ),
      );
      return true;
    } catch (e) {
      print('Error forcing fetch of remote config: $e');
      return false;
    }
  }

  // Force refresh and ensure values are read from local defaults
  Future<bool> forceRefreshAndActivate() async {
    try {
      print('🔄 [RemoteConfig] Force refreshing and activating...');

      // Force activation to ensure local defaults are used
      await _remoteConfig.activate();

      // Try to fetch from server but don't fail if it doesn't work
      try {
        await _remoteConfig.fetchAndActivate();
        print('🔄 [RemoteConfig] ✅ Fetch and activate successful');
      } catch (e) {
        print('🔄 [RemoteConfig] ⚠️ Fetch failed, using local defaults: $e');
        // Still activate to ensure local defaults are used
        await _remoteConfig.activate();
      }

      return true;
    } catch (e) {
      print('❌ [RemoteConfig] Error in forceRefreshAndActivate: $e');
      return false;
    }
  }

  // Check if app update is needed
  Future<bool> isAppUpdateNeeded() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final requiredVersion = updateVersion;

      print('🔍 [RemoteConfig] Current app version: $currentVersion');
      print('🔍 [RemoteConfig] Required version: $requiredVersion');
      print(
        '🔍 [RemoteConfig] Version comparison result: ${_compareVersions(currentVersion, requiredVersion)}',
      );

      return _compareVersions(currentVersion, requiredVersion) < 0;
    } catch (e) {
      print('❌ [RemoteConfig] Error checking app update: $e');
      return false;
    }
  }

  // Compare version strings (returns -1 if current < required, 0 if equal, 1 if current > required)
  int _compareVersions(String current, String required) {
    try {
      // Clean version strings by removing any prefixes and extra spaces
      final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '').trim();
      final cleanRequired = required.replaceAll(RegExp(r'[^0-9.]'), '').trim();

      print(
        '🔍 [RemoteConfig] Cleaned versions - current: "$cleanCurrent", required: "$cleanRequired"',
      );

      final currentParts = cleanCurrent.split('.').map(int.parse).toList();
      final requiredParts = cleanRequired.split('.').map(int.parse).toList();

      // Pad with zeros if needed
      while (currentParts.length < requiredParts.length) {
        currentParts.add(0);
      }
      while (requiredParts.length < currentParts.length) {
        requiredParts.add(0);
      }

      for (int i = 0; i < currentParts.length; i++) {
        if (currentParts[i] < requiredParts[i]) return -1;
        if (currentParts[i] > requiredParts[i]) return 1;
      }
      return 0;
    } catch (e) {
      print('❌ [RemoteConfig] Error comparing versions: $e');
      print(
        '❌ [RemoteConfig] Original versions - current: "$current", required: "$required"',
      );
      return 0; // Return 0 (equal) if there's an error
    }
  }

  // Get current app version
  Future<String> getCurrentAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('Error getting app version: $e');
      return '1.0.0';
    }
  }
}
