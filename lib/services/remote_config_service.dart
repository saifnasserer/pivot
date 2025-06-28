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
}
