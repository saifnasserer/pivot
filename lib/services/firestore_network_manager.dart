import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:flutter/foundation.dart';

/// Manages Firestore network state to reduce connection attempts when offline
class FirestoreNetworkManager {
  static final FirestoreNetworkManager _instance =
      FirestoreNetworkManager._internal();
  factory FirestoreNetworkManager() => _instance;
  FirestoreNetworkManager._internal();

  bool _isNetworkEnabled = true;
  bool _isListening = false;

  /// Start listening to connectivity and manage Firestore network state
  void startManagingNetwork() {
    if (_isListening) {
      print('⚠️ FirestoreNetworkManager already listening');
      return;
    }

    print('🌐 FirestoreNetworkManager: Starting network management');

    final offlineService = OfflineService();

    // Listen to connectivity changes
    offlineService.isOnline.addListener(() {
      _handleConnectivityChange(offlineService.hasConnection);
    });

    // Set initial state
    _handleConnectivityChange(offlineService.hasConnection);

    _isListening = true;
  }

  /// Handle connectivity changes and toggle Firestore network
  void _handleConnectivityChange(bool isOnline) {
    if (isOnline && !_isNetworkEnabled) {
      // Coming back online - enable Firestore network
      _enableFirestoreNetwork();
    } else if (!isOnline && _isNetworkEnabled) {
      // Going offline - disable Firestore network to prevent reconnection attempts
      _disableFirestoreNetwork();
    }
  }

  /// Enable Firestore network
  void _enableFirestoreNetwork() {
    try {
      FirebaseFirestore.instance.enableNetwork();
      _isNetworkEnabled = true;
      if (kDebugMode) {
        print('✅ Firestore network enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error enabling Firestore network: $e');
      }
    }
  }

  /// Disable Firestore network to stop reconnection attempts
  void _disableFirestoreNetwork() {
    try {
      FirebaseFirestore.instance.disableNetwork();
      _isNetworkEnabled = false;
      if (kDebugMode) {
        print('📴 Firestore network disabled (offline mode)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disabling Firestore network: $e');
      }
    }
  }

  /// Manually enable network
  Future<void> enableNetwork() async {
    await FirebaseFirestore.instance.enableNetwork();
    _isNetworkEnabled = true;
    print('✅ Firestore network manually enabled');
  }

  /// Manually disable network
  Future<void> disableNetwork() async {
    await FirebaseFirestore.instance.disableNetwork();
    _isNetworkEnabled = false;
    print('📴 Firestore network manually disabled');
  }

  /// Check if network is currently enabled
  bool get isNetworkEnabled => _isNetworkEnabled;

  /// Stop managing network
  void stopManaging() {
    final offlineService = OfflineService();
    offlineService.isOnline.removeListener(() {});
    _isListening = false;
    print('🔇 FirestoreNetworkManager stopped');
  }
}
