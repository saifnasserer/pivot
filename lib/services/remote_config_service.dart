import 'package:firebase_remote_config/firebase_remote_config.dart';

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
    'show_team_formation_button': false, // Controlled by admin
  };

  // Getters for remote config values
  String get welcomeMessage => _remoteConfig.getString('welcome_message');
  bool get isFeatureEnabled => _remoteConfig.getBool('feature_enabled');

  Future<void> initialize() async {
    _remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 12),
        ),
      );
    } catch (e) {}

    try {
      await _remoteConfig.setDefaults(_defaultConfig);
    } catch (e) {}

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {}
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
      return false;
    }
  }

  // Force refresh and ensure values are read from local defaults
  Future<bool> forceRefreshAndActivate() async {
    try {
      // Force activation to ensure local defaults are used
      await _remoteConfig.activate();

      // Try to fetch from server but don't fail if it doesn't work
      try {
        await _remoteConfig.fetchAndActivate();
      } catch (e) {
        // Still activate to ensure local defaults are used
        await _remoteConfig.activate();
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
