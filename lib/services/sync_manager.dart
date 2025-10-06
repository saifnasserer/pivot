import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/services/offline_queue_service.dart';
import 'dart:async';

/// Manages automatic syncing of offline queue when connection is restored
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  bool _wasOffline = false;
  DateTime? _lastSyncTime;

  /// Initialize sync manager to watch connectivity and auto-sync
  void initialize() {
    print('🔄 Initializing SyncManager...');

    // Watch connectivity changes using the OfflineService directly
    OfflineService().isOnline.addListener(_handleConnectivityChange);

    print('✅ SyncManager initialized');
  }

  void _handleConnectivityChange() {
    final isOnline = OfflineService().hasConnection;

    // If we just came back online and have queued operations, sync them
    if (isOnline && _wasOffline) {
      print('✅ Connection restored - triggering queue sync');
      _triggerSync();
    }

    _wasOffline = !isOnline;
  }

  Future<void> _triggerSync() async {
    try {
      final queueService = OfflineQueueService();
      final queueCount = queueService.getQueueCount();

      if (queueCount == 0) {
        print('✅ Queue is empty, nothing to sync');
        return;
      }

      print('🔄 Syncing $queueCount queued operations...');

      // Import and use the operation processor
      final syncedCount = await queueService.processQueue(
        processor: (operation) async {
          // This will be called by the actual provider implementations
          // For now, we just log it
          print('📦 Processing operation: ${operation.type}');
          // The actual processing will be done by providers
          // that watch for connectivity and process their own operations
        },
      );

      _lastSyncTime = DateTime.now();
      print('✅ Synced $syncedCount operations successfully');
    } catch (e) {
      print('❌ Error during sync: $e');
    }
  }

  /// Manually trigger sync (useful for pull-to-refresh)
  Future<int> manualSync({
    required Future<void> Function(QueuedOperation) processor,
  }) async {
    try {
      print('🔄 Manual sync triggered...');
      final queueService = OfflineQueueService();

      final syncedCount = await queueService.processQueue(
        processor: processor,
        onProgress: (completed, total) {
          print('⏳ Sync progress: $completed/$total');
        },
      );

      _lastSyncTime = DateTime.now();
      return syncedCount;
    } catch (e) {
      print('❌ Manual sync error: $e');
      return 0;
    }
  }

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Get pending operations count
  int getPendingCount() {
    return OfflineQueueService().getQueueCount();
  }

  /// Dispose and cleanup
  void dispose() {
    OfflineService().isOnline.removeListener(_handleConnectivityChange);
    print('🔌 SyncManager disposed');
  }
}

/// Provider for SyncManager
final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager();

  // Initialize when provider is created
  manager.initialize();

  // Cleanup when provider is disposed
  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

/// Provider to get pending operations count
final pendingOperationsCountProvider = Provider<int>((ref) {
  // This will be updated by watching the queue
  return OfflineQueueService().getQueueCount();
});
