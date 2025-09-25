import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/services/remote_config_service.dart';
import 'package:pivot/widgets/update_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final RemoteConfigService _remoteConfig = RemoteConfigService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for Firestore values
  bool _cachedShowUpdateButton = false;
  DateTime _lastCacheUpdate = DateTime.now().subtract(
    const Duration(minutes: 5),
  );
  static const Duration _cacheExpiry = Duration(minutes: 1);

  // Check if update button should be shown - now reads directly from Firestore
  Future<bool> shouldShowUpdateButton() async {
    try {
      print('🔍 [UpdateService] Reading show_update_button from Firestore...');

      final docSnapshot =
          await _firestore
              .collection('settings')
              .doc('update_management')
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final showUpdateButton = data['show_update_button'] as bool? ?? false;

        print(
          '🔍 [UpdateService] Firestore show_update_button: $showUpdateButton',
        );
        return showUpdateButton;
      } else {
        print(
          '🔍 [UpdateService] Firestore document does not exist, using default: false',
        );
        return false;
      }
    } catch (e) {
      print('❌ [UpdateService] Error reading from Firestore: $e');
      // Fallback to Remote Config if Firestore fails
      final shouldShow = _remoteConfig.showUpdateButton;
      print('🔍 [UpdateService] Fallback to Remote Config: $shouldShow');
      return shouldShow;
    }
  }

  // Synchronous version that uses cached values
  bool shouldShowUpdateButtonSync() {
    // Check if cache is expired
    if (DateTime.now().difference(_lastCacheUpdate) > _cacheExpiry) {
      // Update cache in background
      _updateCacheInBackground();
    }

    print(
      '🔍 [UpdateService] shouldShowUpdateButtonSync() called, returning cached value: $_cachedShowUpdateButton',
    );
    return _cachedShowUpdateButton;
  }

  // Update cache in background
  Future<void> _updateCacheInBackground() async {
    try {
      final docSnapshot =
          await _firestore
              .collection('settings')
              .doc('update_management')
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final showUpdateButton = data['show_update_button'] as bool? ?? false;

        _cachedShowUpdateButton = showUpdateButton;
        _lastCacheUpdate = DateTime.now();

        print(
          '🔍 [UpdateService] Cache updated: show_update_button = $showUpdateButton',
        );
      }
    } catch (e) {
      print('❌ [UpdateService] Error updating cache: $e');
    }
  }

  // Force refresh cache
  Future<void> forceRefreshCache() async {
    await _updateCacheInBackground();
  }

  // Force refresh Remote Config values
  Future<void> forceRefreshRemoteConfig() async {
    try {
      print('🔄 [UpdateService] Force refreshing Remote Config...');
      final success = await _remoteConfig.forceFetch();
      if (success) {
        print('🔄 [UpdateService] ✅ Remote Config refreshed successfully');
        print(
          '🔄 [UpdateService] showUpdateButton is now: ${_remoteConfig.showUpdateButton}',
        );
      } else {
        print('🔄 [UpdateService] ❌ Failed to refresh Remote Config');
      }
    } catch (e) {
      print('🔄 [UpdateService] ❌ Error refreshing Remote Config: $e');
    }
  }

  // Check if updates are available (for the speed dial button)
  Future<bool> areUpdatesAvailable() async {
    try {
      print('🔍 [UpdateService] Checking if updates are available...');

      // Check if update button should be shown from Firestore (consistent with button visibility)
      final showUpdateButton = await shouldShowUpdateButton();
      print('🔍 [UpdateService] Show update button: $showUpdateButton');

      if (showUpdateButton) {
        // Read version from Firestore for accurate comparison
        final isUpdateNeeded = await _isAppUpdateNeededFromFirestore();
        print('🔍 [UpdateService] Update needed: $isUpdateNeeded');
        return isUpdateNeeded;
      }

      print('🔍 [UpdateService] No updates available');
      return false;
    } catch (e) {
      print('❌ [UpdateService] Error checking if updates are available: $e');
      return false;
    }
  }

  // Check if app update is needed by reading from Firestore
  Future<bool> _isAppUpdateNeededFromFirestore() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Read required version from Firestore
      final docSnapshot =
          await _firestore
              .collection('settings')
              .doc('update_management')
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final requiredVersion =
            data['app_update_version'] as String? ?? '1.0.0';

        print('🔍 [UpdateService] Current app version: $currentVersion');
        print(
          '🔍 [UpdateService] Required version from Firestore: $requiredVersion',
        );

        // Check if versions are different (not just if current < required)
        final comparison = _compareVersions(currentVersion, requiredVersion);
        print('🔍 [UpdateService] Version comparison result: $comparison');

        return comparison != 0; // Update needed if versions are different
      } else {
        print(
          '🔍 [UpdateService] Firestore document does not exist, no update needed',
        );
        return false;
      }
    } catch (e) {
      print('❌ [UpdateService] Error checking app update from Firestore: $e');
      return false;
    }
  }

  // Compare version strings (same logic as Remote Config)
  int _compareVersions(String current, String required) {
    try {
      // Clean version strings by removing any prefixes and extra spaces
      final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '').trim();
      final cleanRequired = required.replaceAll(RegExp(r'[^0-9.]'), '').trim();

      print(
        '🔍 [UpdateService] Cleaned versions - current: "$cleanCurrent", required: "$cleanRequired"',
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
      print('❌ [UpdateService] Error comparing versions: $e');
      print(
        '❌ [UpdateService] Original versions - current: "$current", required: "$required"',
      );
      return 0; // Return 0 (equal) if there's an error
    }
  }

  // Show update bottom sheet
  void showUpdateBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UpdateBottomSheet(),
    );
  }

  // Download update
  Future<void> _downloadUpdate(BuildContext context) async {
    final downloadUrl = _remoteConfig.updateDownloadUrl;

    if (downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رابط التحميل غير متاح حالياً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح رابط التحميل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في فتح رابط التحميل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Recheck for updates (used in maintenance dialog)
  Future<void> _checkForUpdates(BuildContext context) async {
    try {
      final success = await _remoteConfig.forceFetch();
      if (success) {
        await areUpdatesAvailable(); // Check again
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في التحقق من التحديثات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التحقق من التحديثات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
