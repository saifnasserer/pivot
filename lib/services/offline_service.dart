import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Service to monitor internet connectivity and manage offline state
class OfflineService with WidgetsBindingObserver {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();

  // Notifiers for connectivity state
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  final ValueNotifier<List<ConnectivityResult>> connectivityStatus =
      ValueNotifier<List<ConnectivityResult>>([ConnectivityResult.none]);

  bool _initialized = false;
  bool _isAppInForeground = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _connectivityCheckTimer;

  /// Initialize the offline service and start monitoring connectivity
  Future<void> initialize() async {
    if (_initialized) {
      print('⚠️ OfflineService already initialized');
      return;
    }

    try {
      // Add app lifecycle observer
      WidgetsBinding.instance.addObserver(this);

      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      connectivityStatus.value = result;
      isOnline.value = _hasConnection(result);

      print(
        '📡 OfflineService initialized - Connection: ${isOnline.value ? "✅ Online" : "❌ Offline"}',
      );

      // Start connectivity monitoring
      _startConnectivityMonitoring();

      // Start periodic connectivity check (every 30 seconds when app is in foreground)
      _startPeriodicConnectivityCheck();

      _initialized = true;
    } catch (e) {
      print('❌ OfflineService initialization error: $e');
      // Default to online if initialization fails
      isOnline.value = true;
      _initialized = false;
    }
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
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
        // Restart monitoring after error
        Future.delayed(Duration(seconds: 5), () {
          if (_initialized) {
            _startConnectivityMonitoring();
          }
        });
      },
    );
  }

  /// Start periodic connectivity check
  void _startPeriodicConnectivityCheck() {
    _connectivityCheckTimer?.cancel();
    _connectivityCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isAppInForeground && _initialized) {
        _performConnectivityCheck();
      }
    });
  }

  /// Perform a manual connectivity check
  Future<void> _performConnectivityCheck() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = _hasConnection(result);
      
      if (connectivityStatus.value != result || isOnline.value != hasConnection) {
        connectivityStatus.value = result;
        isOnline.value = hasConnection;
        print(
          '📡 Periodic check - Connection: ${isOnline.value ? "✅ Online" : "❌ Offline"}',
        );
      }
    } catch (e) {
      print('❌ Error during periodic connectivity check: $e');
    }
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        print('📱 App resumed - checking connectivity...');
        // Immediately check connectivity when app resumes
        _performConnectivityCheck();
        // Restart connectivity monitoring in case it was interrupted
        if (_initialized) {
          _startConnectivityMonitoring();
        }
        break;
      case AppLifecycleState.paused:
        _isAppInForeground = false;
        print('📱 App paused');
        break;
      case AppLifecycleState.inactive:
        // App is transitioning between foreground and background
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        _isAppInForeground = false;
        break;
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        break;
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
      final hasConnection = _hasConnection(result);
      connectivityStatus.value = result;
      isOnline.value = hasConnection;
      print('📡 Manual connectivity check: ${hasConnection ? "✅ Online" : "❌ Offline"}');
      return hasConnection;
    } catch (e) {
      print('❌ Error checking connectivity: $e');
      return isOnline.value; // Return last known state
    }
  }

  /// Force refresh connectivity status (useful when app resumes)
  Future<void> forceRefreshConnectivity() async {
    print('🔄 Force refreshing connectivity...');
    await _performConnectivityCheck();
  }

  /// Dispose and cleanup
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _connectivityCheckTimer?.cancel();
    isOnline.dispose();
    connectivityStatus.dispose();
    _initialized = false;
    _isAppInForeground = false;
    print('🔌 OfflineService disposed');
  }
}

// ===== Riverpod Providers =====

/// Provider for OfflineService singleton
final offlineServiceProvider = Provider<OfflineService>((ref) {
  final service = OfflineService();

  // Initialize the service if not already initialized
  if (!service._initialized) {
    service.initialize();
  }

  // Cleanup when provider is disposed
  ref.onDispose(() {
    // Don't dispose the singleton service here as it might be used elsewhere
    // The service will be disposed when the app is terminated
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

/// Provider that provides a method to force refresh connectivity
final connectivityRefreshProvider = Provider<Future<void> Function()>((ref) {
  final service = ref.watch(offlineServiceProvider);
  return () => service.forceRefreshConnectivity();
});
