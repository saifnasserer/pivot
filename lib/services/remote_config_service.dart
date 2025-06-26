import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:convert';

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
    'project_link_validation': {
      'required': true,
      'min_length': 5,
      'max_length': 200,
      'allowed_domains': ['github.com', 'gitlab.com', 'bitbucket.org'],
      'error_messages': {
        'required': 'رابط المشروع مطلوب',
        'invalid_url': 'الرجاء إدخال رابط صحيح',
        'invalid_domain': 'الرجاء إدخال رابط من المواقع المسموح بها',
        'too_short': 'الرابط قصير جداً',
        'too_long': 'الرابط طويل جداً',
      },
    },
  };

  // Getters for remote config values
  String get welcomeMessage => _remoteConfig.getString('welcome_message');
  bool get isFeatureEnabled => _remoteConfig.getBool('feature_enabled');

  // Project link validation getters
  bool get isProjectLinkRequired => _getProjectLinkConfig()['required'] ?? true;

  int get projectLinkMinLength => _getProjectLinkConfig()['min_length'] ?? 5;

  int get projectLinkMaxLength => _getProjectLinkConfig()['max_length'] ?? 200;

  List<String> get allowedProjectDomains => List<String>.from(
    _getProjectLinkConfig()['allowed_domains'] ?? ['github.com'],
  );

  Map<String, String> get projectLinkErrorMessages => Map<String, String>.from(
    _getProjectLinkConfig()['error_messages'] ??
        {
          'required': 'رابط المشروع مطلوب',
          'invalid_url': 'الرجاء إدخال رابط صحيح',
          'invalid_domain': 'الرجاء إدخال رابط من المواقع المسموح بها',
          'too_short': 'الرابط قصير جداً',
          'too_long': 'الرابط طويل جداً',
        },
  );

  Map<String, dynamic> _getProjectLinkConfig() {
    try {
      final jsonStr = _remoteConfig.getString('project_link_validation');
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing project link config: $e');
      return _defaultConfig['project_link_validation'] as Map<String, dynamic>;
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
}
