import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Service to monitor internet connectivity and manage offline state
class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();

  // Notifiers for connectivity state
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  final ValueNotifier<List<ConnectivityResult>> connectivityStatus =
      ValueNotifier<List<ConnectivityResult>>([ConnectivityResult.none]);

  bool _initialized = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Initialize the offline service and start monitoring connectivity
  Future<void> initialize() async {
    if (_initialized) {
      print('⚠️ OfflineService already initialized');
      return;
    }

    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      connectivityStatus.value = result;
      isOnline.value = _hasConnection(result);

      print(
        '📡 OfflineService initialized - Connection: ${isOnline.value ? "✅ Online" : "❌ Offline"}',
      );

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> result) {
          final previousStatus = isOnline.value;
          connectivityStatus.value = result;
          isOnline.value = _hasConnection(result);

          // Log connectivity changes
          if (previousStatus != isOnline.value) {
            print(
              '📡 Connectivity changed: ${isOnline.value ? "✅ Back Online" : "❌ Went Offline"}',
            );
          }
        },
        onError: (error) {
          print('❌ OfflineService connectivity error: $error');
        },
      );

      _initialized = true;
    } catch (e) {
      print('❌ OfflineService initialization error: $e');
      // Default to online if initialization fails
      isOnline.value = true;
      _initialized = false;
    }
  }

  /// Check if device has internet connection
  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;

    // Check if any connection type is available
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }

  /// Get current connection status
  bool get hasConnection => isOnline.value;

  /// Check if currently offline
  bool get isOffline => !isOnline.value;

  /// Get connectivity type as string for debugging
  String get connectionType {
    if (connectivityStatus.value.isEmpty) return 'None';
    return connectivityStatus.value.map((e) => e.name).join(', ');
  }

  /// Manually check connectivity (for testing or manual refresh)
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      connectivityStatus.value = result;
      isOnline.value = _hasConnection(result);
      return isOnline.value;
    } catch (e) {
      print('❌ Error checking connectivity: $e');
      return isOnline.value; // Return last known state
    }
  }

  /// Dispose and cleanup
  void dispose() {
    _connectivitySubscription?.cancel();
    isOnline.dispose();
    connectivityStatus.dispose();
    _initialized = false;
    print('🔌 OfflineService disposed');
  }
}

// ===== Riverpod Providers =====

/// Provider for OfflineService singleton
final offlineServiceProvider = Provider<OfflineService>((ref) {
  final service = OfflineService();

  // Cleanup when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// StreamProvider that emits connectivity status changes
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged;
});

/// Provider that returns current online/offline state
final isOnlineProvider = Provider<bool>((ref) {
  final service = ref.watch(offlineServiceProvider);
  return service.hasConnection;
});

/// Provider that watches connectivity changes and returns online status
final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(offlineServiceProvider);

  // Emit initial status
  yield service.hasConnection;

  // Listen to connectivity changes
  await for (final _ in Connectivity().onConnectivityChanged) {
    final isOnline = await service.checkConnectivity();
    yield isOnline;
  }
});
