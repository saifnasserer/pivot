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
    'app_update_required': false,
    'app_update_force': false,
    'app_update_message': 'تحديث جديد متاح للتطبيق',
    'app_update_title': 'تحديث التطبيق',
    'app_update_download_url': '',
    'app_update_version': '1.0.0',
    'app_update_changelog': 'تحسينات عامة وإصلاحات للأخطاء',
    'maintenance_mode': false,
    'maintenance_message': 'التطبيق في وضع الصيانة',
  };

  // Getters for remote config values
  String get welcomeMessage => _remoteConfig.getString('welcome_message');
  bool get isFeatureEnabled => _remoteConfig.getBool('feature_enabled');

  // Update management getters
  bool get isUpdateRequired => _remoteConfig.getBool('app_update_required');
  bool get isUpdateForce => _remoteConfig.getBool('app_update_force');
  String get updateMessage => _remoteConfig.getString('app_update_message');
  String get updateTitle => _remoteConfig.getString('app_update_title');
  String get updateDownloadUrl =>
      _remoteConfig.getString('app_update_download_url');
  String get updateVersion => _remoteConfig.getString('app_update_version');
  String get updateChangelog => _remoteConfig.getString('app_update_changelog');
  bool get isMaintenanceMode => _remoteConfig.getBool('maintenance_mode');
  String get maintenanceMessage =>
      _remoteConfig.getString('maintenance_message');

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

  // Check if app update is needed
  Future<bool> isAppUpdateNeeded() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final requiredVersion = updateVersion;

      return _compareVersions(currentVersion, requiredVersion) < 0;
    } catch (e) {
      print('Error checking app update: $e');
      return false;
    }
  }

  // Compare version strings (returns -1 if current < required, 0 if equal, 1 if current > required)
  int _compareVersions(String current, String required) {
    final currentParts = current.split('.').map(int.parse).toList();
    final requiredParts = required.split('.').map(int.parse).toList();

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

  // Check if app is in maintenance mode
  bool isAppInMaintenance() {
    return isMaintenanceMode;
  }
}
