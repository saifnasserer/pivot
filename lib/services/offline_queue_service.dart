import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

/// Types of operations that can be queued for offline sync
enum OperationType {
  // Task operations
  createTask,
  updateTask,
  deleteTask,
  addTaskNote,
  deleteTaskNote,

  // Profile operations
  updateProfile,
  updateTeachingSubjects,

  // Schedule operations
  createScheduleItem,
  updateScheduleItem,
  deleteScheduleItem,
  reorderScheduleItems,
  toggleScheduleNotification,

  // Material operations
  addMaterial,
  deleteMaterial,
  rateMaterial,

  // Section operations
  createSection,
  updateSection,
  deleteSection,

  // Bookmark operations
  addBookmark,
  removeBookmark,

  // Lecture operations
  addLecture,
  deleteLecture,
  updateLecture,
}

/// Represents a queued operation to be synced when online
class QueuedOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final String? errorMessage;

  QueuedOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
    'errorMessage': errorMessage,
  };

  factory QueuedOperation.fromJson(Map<String, dynamic> json) {
    return QueuedOperation(
      id: json['id'],
      type: OperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
      errorMessage: json['errorMessage'],
    );
  }

  QueuedOperation copyWith({int? retryCount, String? errorMessage}) {
    return QueuedOperation(
      id: id,
      type: type,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Service to manage offline operations queue and sync when online
class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  static const String _queueBoxName = 'offlineQueueBox';
  static const int _maxRetries = 3;

  bool _initialized = false;
  bool _syncing = false;

  /// Initialize the queue service
  Future<void> init() async {
    if (_initialized) {
      print('⚠️ OfflineQueueService already initialized');
      return;
    }

    try {
      if (!Hive.isBoxOpen(_queueBoxName)) {
        await Hive.openBox(_queueBoxName);
      }
      _initialized = true;
      print('✅ OfflineQueueService initialized');
    } catch (e) {
      print('❌ OfflineQueueService initialization error: $e');
      _initialized = false;
    }
  }

  /// Add operation to queue
  Future<void> queueOperation(QueuedOperation operation) async {
    print('🎯 [OfflineQueueService.queueOperation] Starting...');
    print('   Operation ID: ${operation.id}');
    print('   Operation Type: ${operation.type}');
    print('   Data keys: ${operation.data.keys.toList()}');

    try {
      print('   Checking initialization: $_initialized');
      if (!_initialized) {
        print('   Not initialized, calling init()...');
        await init();
        print('   Init completed');
      }

      print('   Opening box: $_queueBoxName');
      final box = Hive.box(_queueBoxName);
      print('   Box opened successfully');
      print('   Box length before: ${box.length}');

      final jsonData = jsonEncode(operation.toJson());
      print('   JSON encoded, length: ${jsonData.length}');

      await box.put(operation.id, jsonData);
      print('   Data written to box');
      print('   Box length after: ${box.length}');

      // Verify it was saved
      final saved = box.get(operation.id);
      print('   Verification: ${saved != null ? "FOUND" : "NOT FOUND"}');

      print(
        '✅ [OfflineQueueService] Queued operation: ${operation.type} (ID: ${operation.id})',
      );
    } catch (e, stackTrace) {
      print('❌ [OfflineQueueService] Error queuing operation: $e');
      print('   Stack trace: $stackTrace');
      rethrow; // Re-throw so caller knows it failed
    }
  }

  /// Get all queued operations
  List<QueuedOperation> getQueuedOperations() {
    try {
      if (!_initialized) return [];

      final box = Hive.box(_queueBoxName);
      final operations = <QueuedOperation>[];

      for (var value in box.values) {
        try {
          final operation = QueuedOperation.fromJson(jsonDecode(value));
          operations.add(operation);
        } catch (e) {
          print('⚠️ Error parsing queued operation: $e');
        }
      }

      // Sort by timestamp (oldest first)
      operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return operations;
    } catch (e) {
      print('❌ Error getting queued operations: $e');
      return [];
    }
  }

  /// Remove operation from queue
  Future<void> removeOperation(String operationId) async {
    try {
      if (!_initialized) return;

      final box = Hive.box(_queueBoxName);
      await box.delete(operationId);
      print('✅ Removed operation from queue: $operationId');
    } catch (e) {
      print('❌ Error removing operation: $e');
    }
  }

  /// Update operation (for retry count or error messages)
  Future<void> updateOperation(QueuedOperation operation) async {
    try {
      if (!_initialized) return;

      final box = Hive.box(_queueBoxName);
      await box.put(operation.id, jsonEncode(operation.toJson()));
    } catch (e) {
      print('❌ Error updating operation: $e');
    }
  }

  /// Clear all queued operations
  Future<void> clearQueue() async {
    try {
      if (!_initialized) return;

      final box = Hive.box(_queueBoxName);
      await box.clear();
      print('🗑️ Cleared all queued operations');
    } catch (e) {
      print('❌ Error clearing queue: $e');
    }
  }

  /// Get queue count
  int getQueueCount() {
    try {
      if (!_initialized) {
        print('⚠️ [getQueueCount] Not initialized, returning 0');
        return 0;
      }

      final box = Hive.box(_queueBoxName);
      final count = box.length;
      print('📊 [getQueueCount] Queue count: $count');

      // Log queue contents for debugging
      if (count > 0) {
        print('   Queue contents:');
        for (var key in box.keys) {
          print('      - $key');
        }
      }

      return count;
    } catch (e) {
      print('❌ Error getting queue count: $e');
      return 0;
    }
  }

  /// Check if queue is empty
  bool isQueueEmpty() {
    return getQueueCount() == 0;
  }

  /// Check if currently syncing
  bool get isSyncing => _syncing;

  /// Process queue when online
  /// Pass a processor function that handles each operation type
  Future<int> processQueue({
    required Future<void> Function(QueuedOperation) processor,
    void Function(int completed, int total)? onProgress,
  }) async {
    if (_syncing) {
      print('⚠️ Already syncing queue');
      return 0;
    }

    _syncing = true;
    print('🔄 Starting queue sync...');

    try {
      final operations = getQueuedOperations();

      if (operations.isEmpty) {
        print('✅ Queue is empty, nothing to sync');
        return 0;
      }

      print('📦 Processing ${operations.length} queued operations');

      int successCount = 0;
      int failedCount = 0;

      for (int i = 0; i < operations.length; i++) {
        final operation = operations[i];

        try {
          // Process the operation
          await processor(operation);

          // Success - remove from queue
          await removeOperation(operation.id);
          successCount++;

          print(
            '✅ Synced operation ${i + 1}/${operations.length}: ${operation.type}',
          );

          // Report progress
          onProgress?.call(i + 1, operations.length);
        } catch (e) {
          print('❌ Failed to sync operation ${operation.type}: $e');

          // Increment retry count
          final updatedOperation = operation.copyWith(
            retryCount: operation.retryCount + 1,
            errorMessage: e.toString(),
          );

          // Remove if max retries reached, otherwise update
          if (updatedOperation.retryCount >= _maxRetries) {
            print(
              '⚠️ Max retries reached for ${operation.type}, removing from queue',
            );
            await removeOperation(operation.id);
            failedCount++;
          } else {
            await updateOperation(updatedOperation);
          }
        }
      }

      print(
        '🎯 Queue sync complete: $successCount succeeded, $failedCount failed',
      );

      return successCount;
    } catch (e) {
      print('❌ Error processing queue: $e');
      return 0;
    } finally {
      _syncing = false;
    }
  }

  /// Get queue statistics
  Map<String, dynamic> getQueueStats() {
    try {
      final operations = getQueuedOperations();

      // Count by operation type
      final typeCounts = <OperationType, int>{};
      for (var op in operations) {
        typeCounts[op.type] = (typeCounts[op.type] ?? 0) + 1;
      }

      // Find oldest operation
      DateTime? oldestTimestamp;
      if (operations.isNotEmpty) {
        oldestTimestamp = operations.first.timestamp;
      }

      return {
        'totalCount': operations.length,
        'byType': typeCounts.map((k, v) => MapEntry(k.toString(), v)),
        'oldestTimestamp': oldestTimestamp?.toIso8601String(),
        'isSyncing': _syncing,
      };
    } catch (e) {
      print('❌ Error getting queue stats: $e');
      return {'totalCount': 0, 'error': e.toString()};
    }
  }

  /// Clear operations older than specified days
  Future<void> clearOldOperations(int days) async {
    try {
      final operations = getQueuedOperations();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      int removedCount = 0;
      for (var operation in operations) {
        if (operation.timestamp.isBefore(cutoffDate)) {
          await removeOperation(operation.id);
          removedCount++;
        }
      }

      if (removedCount > 0) {
        print('🗑️ Removed $removedCount old operations (>$days days)');
      }
    } catch (e) {
      print('❌ Error clearing old operations: $e');
    }
  }
}
