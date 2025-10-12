import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/services/offline_sync_manager.dart';
import 'package:pivot/services/offline_queue_service.dart';
import 'dart:async';

/// Legacy SyncManager - now wraps OfflineSyncManager
/// Kept for backward compatibility with existing code
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  late final OfflineSyncManager _syncManager = OfflineSyncManager();
  bool _initialized = false;

  /// Initialize sync manager to watch connectivity and auto-sync
  void initialize() {
    if (_initialized) {
      print('⚠️ SyncManager already initialized');
      return;
    }

    print('🔄 Initializing SyncManager (via OfflineSyncManager)...');
    _syncManager.startListening();
    _initialized = true;
    print('✅ SyncManager initialized');
  }

  /// Manually trigger sync (useful for pull-to-refresh)
  Future<int> manualSync({
    Future<void> Function(QueuedOperation)? processor,
  }) async {
    try {
      print('🔄 Manual sync triggered...');
      await _syncManager.manualSync();
      return _syncManager.syncedCount.value;
    } catch (e) {
      print('❌ Manual sync error: $e');
      return 0;
    }
  }

  /// Get pending operations count
  int getPendingCount() {
    return _syncManager.syncStatus['queueCount'] ?? 0;
  }

  /// Get sync status
  Map<String, dynamic> get syncStatus => _syncManager.syncStatus;

  /// Check if currently syncing
  bool get isSyncing => _syncManager.isSyncing.value;

  /// Dispose and cleanup
  void dispose() {
    _syncManager.dispose();
    _initialized = false;
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
