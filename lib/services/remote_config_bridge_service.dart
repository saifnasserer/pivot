import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:pivot/services/remote_config_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RemoteConfigBridgeService {
  static final RemoteConfigBridgeService _instance =
      RemoteConfigBridgeService._internal();
  factory RemoteConfigBridgeService() => _instance;
  RemoteConfigBridgeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Remote Config parameter names
  static const Map<String, String> _parameterMapping = {
    'app_update_force': 'app_update_force',
    'app_update_message': 'app_update_message',
    'app_update_title': 'app_update_title',
    'app_update_download_url': 'app_update_download_url',
    'app_update_version': 'app_update_version',
    'app_update_changelog': 'app_update_changelog',
    'show_update_button': 'show_update_button',
  };

  // Initialize the bridge service
  Future<void> initialize() async {
    print('🔗 [RemoteConfigBridge] Initializing bridge service...');

    // Listen for changes in Firestore settings
    _firestore.collection('settings').doc('update_management').snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        print(
          '🔗 [RemoteConfigBridge] Firestore settings changed, syncing to Remote Config...',
        );
        _syncToRemoteConfig(snapshot.data()!);
      }
    });
  }

  // Sync Firestore settings to Remote Config
  Future<void> _syncToRemoteConfig(Map<String, dynamic> firestoreData) async {
    try {
      print('🔗 [RemoteConfigBridge] Starting sync to Remote Config...');

      // Create parameter values map
      final Map<String, dynamic> parameterValues = {};

      for (final entry in _parameterMapping.entries) {
        final firestoreKey = entry.key;
        final remoteConfigKey = entry.value;

        if (firestoreData.containsKey(firestoreKey)) {
          final value = firestoreData[firestoreKey];
          parameterValues[remoteConfigKey] = value;
          print(
            '🔗 [RemoteConfigBridge] Syncing $firestoreKey -> $remoteConfigKey = $value',
          );
        }
      }

      // Update Remote Config parameters
      await _updateRemoteConfigParameters(parameterValues);

      print('🔗 [RemoteConfigBridge] ✅ Sync completed successfully');
      
      // Force a refresh of the Remote Config service
      try {
        await RemoteConfigService.instance.forceRefreshAndActivate();
        print('🔗 [RemoteConfigBridge] ✅ Remote Config force refreshed and activated');
      } catch (e) {
        print('🔗 [RemoteConfigBridge] ⚠️ Error force refreshing Remote Config: $e');
      }
    } catch (e) {
      print('🔗 [RemoteConfigBridge] ❌ Error syncing to Remote Config: $e');
    }
  }

  // Update Remote Config parameters
  Future<void> _updateRemoteConfigParameters(
    Map<String, dynamic> parameters,
  ) async {
    try {
      print(
        '🔗 [RemoteConfigBridge] Updating Remote Config parameters: $parameters',
      );

      // Set the new defaults directly
      await _remoteConfig.setDefaults(parameters);

      // Force activation of the new defaults
      await _remoteConfig.activate();

      // Try to fetch and activate, but don't fail if network is down
      try {
        final success = await _remoteConfig.fetchAndActivate();

        if (success) {
          print(
            '🔗 [RemoteConfigBridge] ✅ Remote Config parameters updated and activated',
          );
        } else {
          print(
            '🔗 [RemoteConfigBridge] ⚠️ Remote Config fetch failed, but defaults are set locally',
          );
        }

        // Force activation again to ensure local defaults are used
        await _remoteConfig.activate();

        // Verify the values were updated (regardless of fetch success)
        for (final entry in parameters.entries) {
          final key = entry.key;
          final expectedValue = entry.value;
          final actualValue = _remoteConfig.getValue(key);

          print(
            '🔗 [RemoteConfigBridge] Verifying $key: expected=$expectedValue, actual=${_convertValue(actualValue)}',
          );
        }
      } catch (e) {
        print(
          '🔗 [RemoteConfigBridge] ⚠️ Remote Config fetch error: $e, but defaults are set locally',
        );

        // Still verify the values even if fetch failed
        for (final entry in parameters.entries) {
          final key = entry.key;
          final expectedValue = entry.value;
          final actualValue = _remoteConfig.getValue(key);

          print(
            '🔗 [RemoteConfigBridge] Verifying $key: expected=$expectedValue, actual=${_convertValue(actualValue)}',
          );
        }
      }
    } catch (e) {
      print(
        '🔗 [RemoteConfigBridge] ❌ Error updating Remote Config parameters: $e',
      );
    }
  }

  // Save settings to Firestore and trigger sync
  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      print('🔗 [RemoteConfigBridge] Saving settings to Firestore...');

      // Add metadata
      final settingsWithMetadata = {
        ...settings,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'synced_to_remote_config': false, // Will be updated by the listener
      };

      // Save to Firestore
      await _firestore
          .collection('settings')
          .doc('update_management')
          .set(settingsWithMetadata, SetOptions(merge: true));

      print('🔗 [RemoteConfigBridge] ✅ Settings saved to Firestore');
      return true;
    } catch (e) {
      print('🔗 [RemoteConfigBridge] ❌ Error saving settings: $e');
      return false;
    }
  }

  // Load settings from Firestore
  Future<Map<String, dynamic>?> loadSettings() async {
    try {
      print('🔗 [RemoteConfigBridge] Loading settings from Firestore...');

      final doc =
          await _firestore
              .collection('settings')
              .doc('update_management')
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        print('🔗 [RemoteConfigBridge] ✅ Settings loaded from Firestore');
        return data;
      } else {
        print('🔗 [RemoteConfigBridge] ⚠️ No settings found in Firestore');
        return null;
      }
    } catch (e) {
      print('🔗 [RemoteConfigBridge] ❌ Error loading settings: $e');
      return null;
    }
  }

  // Get current Remote Config values
  Map<String, dynamic> getCurrentRemoteConfigValues() {
    final values = <String, dynamic>{};

    for (final entry in _parameterMapping.entries) {
      final remoteConfigKey = entry.value;

      try {
        // Try to get the value from Remote Config
        final value = _remoteConfig.getValue(remoteConfigKey);

        // Get the value regardless of source
        values[remoteConfigKey] = _convertValue(value);
      } catch (e) {
        print(
          '🔗 [RemoteConfigBridge] Error getting value for $remoteConfigKey: $e',
        );
      }
    }

    return values;
  }

  // Convert Remote Config value to appropriate type
  dynamic _convertValue(RemoteConfigValue value) {
    try {
      if (value.asBool() != null) return value.asBool();
      if (value.asString().isNotEmpty) return value.asString();
      if (value.asInt() != null) return value.asInt();
      if (value.asDouble() != null) return value.asDouble();
      return value.asString();
    } catch (e) {
      return value.asString();
    }
  }

  // Force sync from Firestore to Remote Config
  Future<bool> forceSync() async {
    try {
      print('🔗 [RemoteConfigBridge] Force syncing from Firestore...');

      final settings = await loadSettings();
      if (settings != null) {
        await _syncToRemoteConfig(settings);
        
                  // Force activation after sync
          try {
            await RemoteConfigService.instance.forceRefreshAndActivate();
            print('🔗 [RemoteConfigBridge] ✅ Force sync completed and refreshed');
          } catch (e) {
            print('🔗 [RemoteConfigBridge] ⚠️ Error refreshing after force sync: $e');
          }
        
        return true;
      }
      return false;
    } catch (e) {
      print('🔗 [RemoteConfigBridge] ❌ Error in force sync: $e');
      return false;
    }
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final firestoreSettings = await loadSettings();
      final remoteConfigValues = getCurrentRemoteConfigValues();

      final status = {
        'firestore_has_data': firestoreSettings != null,
        'remote_config_values': remoteConfigValues,
        'last_firestore_update': firestoreSettings?['updated_at'],
        'synced': firestoreSettings?['synced_to_remote_config'] ?? false,
      };

      return status;
    } catch (e) {
      print('🔗 [RemoteConfigBridge] ❌ Error getting sync status: $e');
      return {'error': e.toString()};
    }
  }
}
