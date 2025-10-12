import 'package:pivot/services/offline_service.dart';
import 'package:pivot/services/offline_queue_service.dart';

/// Custom exception for offline operations
class OfflineException implements Exception {
  final String message;
  OfflineException(this.message);

  @override
  String toString() => 'OfflineException: $message';
}

/// Wrapper around repositories to add offline queueing capability
/// without modifying existing repository code
class OfflineAwareRepository {
  final OfflineService _offlineService;
  final OfflineQueueService _queueService;

  OfflineAwareRepository({
    OfflineService? offlineService,
    OfflineQueueService? queueService,
  }) : _offlineService = offlineService ?? OfflineService(),
       _queueService = queueService ?? OfflineQueueService();

  /// Execute an operation with offline awareness
  ///
  /// If online: executes the operation immediately
  /// If offline: queues the operation and optionally returns optimistic result
  ///
  /// Example usage:
  /// ```dart
  /// await offlineRepo.executeOperation(
  ///   type: OperationType.createScheduleItem,
  ///   data: item.toJson(),
  ///   onlineOperation: () => scheduleService.addScheduleItem(item),
  ///   optimisticResult: item, // Optional: return immediately for UI
  /// );
  /// ```
  Future<T> executeOperation<T>({
    required OperationType type,
    required Map<String, dynamic> data,
    required Future<T> Function() onlineOperation,
    T? optimisticResult,
    String? operationId,
  }) async {
    // Check if offline
    if (_offlineService.isOffline) {
      print('📴 Offline detected - queueing operation: ${type.toString()}');

      // Generate operation ID if not provided
      final opId =
          operationId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Queue the operation
      await _queueService.queueOperation(
        QueuedOperation(
          id: opId,
          type: type,
          data: data,
          timestamp: DateTime.now(),
        ),
      );

      print('✅ Operation queued: $opId');

      // If optimistic result provided, return it
      // This allows UI to update immediately even though we're offline
      if (optimisticResult != null) {
        return optimisticResult;
      }

      // Otherwise throw exception to signal operation was queued
      throw OfflineException(
        'Operation queued for sync when online. Queue ID: $opId',
      );
    }

    // Online - execute immediately
    print('🌐 Online - executing operation: ${type.toString()}');
    try {
      final result = await onlineOperation();
      print('✅ Operation completed successfully');
      return result;
    } catch (e) {
      print('❌ Operation failed: $e');
      rethrow;
    }
  }

  /// Execute an operation with optimistic UI update
  ///
  /// Always returns the optimistic result immediately,
  /// queues for sync if offline, or executes if online
  Future<T> executeWithOptimisticUpdate<T>({
    required OperationType type,
    required Map<String, dynamic> data,
    required Future<T> Function() onlineOperation,
    required T optimisticResult,
    String? operationId,
  }) async {
    if (_offlineService.isOffline) {
      print('📴 Offline - using optimistic update for: ${type.toString()}');

      final opId =
          operationId ?? DateTime.now().millisecondsSinceEpoch.toString();

      await _queueService.queueOperation(
        QueuedOperation(
          id: opId,
          type: type,
          data: data,
          timestamp: DateTime.now(),
        ),
      );

      print('✅ Operation queued with optimistic result: $opId');
      return optimisticResult;
    }

    // Online - execute and return actual result
    return await onlineOperation();
  }

  /// Check if currently offline
  bool get isOffline => _offlineService.isOffline;

  /// Check if currently online
  bool get isOnline => _offlineService.hasConnection;

  /// Get pending operations count
  int get pendingOperationsCount => _queueService.getQueueCount();

  /// Get queue statistics
  Map<String, dynamic> get queueStats => _queueService.getQueueStats();

  /// Check if queue is empty
  bool get isQueueEmpty => _queueService.isQueueEmpty();

  /// Manually clear all queued operations (use with caution!)
  Future<void> clearQueue() async {
    await _queueService.clearQueue();
  }

  /// Clear operations older than specified days
  Future<void> clearOldOperations(int days) async {
    await _queueService.clearOldOperations(days);
  }
}

/// Singleton instance for global access
/// Can be used across the app without passing through constructors
class OfflineRepository {
  static final OfflineRepository _instance = OfflineRepository._internal();
  factory OfflineRepository() => _instance;
  OfflineRepository._internal();

  late final OfflineAwareRepository _repo = OfflineAwareRepository();

  /// Get the singleton repository instance
  static OfflineAwareRepository get instance => _instance._repo;

  /// Execute operation using singleton
  static Future<T> execute<T>({
    required OperationType type,
    required Map<String, dynamic> data,
    required Future<T> Function() onlineOperation,
    T? optimisticResult,
    String? operationId,
  }) async {
    return await instance.executeOperation(
      type: type,
      data: data,
      onlineOperation: onlineOperation,
      optimisticResult: optimisticResult,
      operationId: operationId,
    );
  }

  /// Execute with optimistic update using singleton
  static Future<T> executeOptimistic<T>({
    required OperationType type,
    required Map<String, dynamic> data,
    required Future<T> Function() onlineOperation,
    required T optimisticResult,
    String? operationId,
  }) async {
    return await instance.executeWithOptimisticUpdate(
      type: type,
      data: data,
      onlineOperation: onlineOperation,
      optimisticResult: optimisticResult,
      operationId: operationId,
    );
  }
}
