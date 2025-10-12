import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/services/offline_queue_service.dart';
import 'package:pivot/services/schedule_service.dart';
import 'package:pivot/services/section_service.dart';
import 'package:pivot/features/tasks/services/tasks_service.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/screens/models/task.dart';

/// Manages automatic syncing of queued operations when connectivity is restored
class OfflineSyncManager {
  final OfflineService _offlineService;
  final OfflineQueueService _queueService;

  // Services for executing operations
  final ScheduleService _scheduleService;
  final SectionService _sectionService;
  final TasksService _tasksService;

  bool _isSyncing = false;
  bool _wasOffline = false;

  // Notifiers for UI updates
  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);
  final ValueNotifier<int> syncedCount = ValueNotifier<int>(0);
  final ValueNotifier<int> totalCount = ValueNotifier<int>(0);
  final ValueNotifier<String?> syncError = ValueNotifier<String?>(null);

  OfflineSyncManager({
    OfflineService? offlineService,
    OfflineQueueService? queueService,
    ScheduleService? scheduleService,
    SectionService? sectionService,
    TasksService? tasksService,
  }) : _offlineService = offlineService ?? OfflineService(),
       _queueService = queueService ?? OfflineQueueService(),
       _scheduleService = scheduleService ?? ScheduleService(),
       _sectionService = sectionService ?? SectionService(),
       _tasksService = tasksService ?? TasksService();

  /// Start listening to connectivity changes and sync when back online
  void startListening() {
    print('🎧 OfflineSyncManager: Started listening to connectivity');

    // Listen to connectivity changes
    _offlineService.isOnline.addListener(_onConnectivityChanged);

    // Initialize state
    _wasOffline = _offlineService.isOffline;
  }

  /// Stop listening to connectivity changes
  void stopListening() {
    _offlineService.isOnline.removeListener(_onConnectivityChanged);
    print('🔇 OfflineSyncManager: Stopped listening');
  }

  /// Handle connectivity changes
  void _onConnectivityChanged() {
    final isOnline = _offlineService.hasConnection;
    final wasOffline = _wasOffline;

    print(
      '📡 Connectivity changed: isOnline=$isOnline, wasOffline=$wasOffline',
    );

    // Only sync when transitioning from offline to online
    if (isOnline && wasOffline) {
      print('✅ Back online - triggering sync');
      _triggerSync();
    }

    _wasOffline = !isOnline;
  }

  /// Trigger sync of all queued operations
  Future<void> _triggerSync() async {
    if (_isSyncing) {
      print('⚠️ Already syncing, skipping...');
      return;
    }

    final queueCount = _queueService.getQueueCount();
    if (queueCount == 0) {
      print('ℹ️ Queue is empty, nothing to sync');
      return;
    }

    print('🔄 Starting sync of $queueCount operations...');
    _isSyncing = true;
    isSyncing.value = true;
    syncedCount.value = 0;
    totalCount.value = queueCount;
    syncError.value = null;

    try {
      final successCount = await _queueService.processQueue(
        processor: _processOperation,
        onProgress: (completed, total) {
          syncedCount.value = completed;
          totalCount.value = total;
          print('📊 Sync progress: $completed/$total');
        },
      );

      print('✅ Sync completed: $successCount operations synced');
    } catch (e) {
      print('❌ Sync error: $e');
      syncError.value = e.toString();
    } finally {
      _isSyncing = false;
      isSyncing.value = false;
    }
  }

  /// Process a single queued operation
  Future<void> _processOperation(QueuedOperation operation) async {
    print('⚙️ Processing operation: ${operation.type}');

    try {
      switch (operation.type) {
        // Schedule operations
        case OperationType.createScheduleItem:
          final item = ScheduleItem.fromJson(operation.data);
          await _scheduleService.addScheduleItem(item);
          break;

        case OperationType.updateScheduleItem:
          // Schedule service doesn't have update - use remove then add
          final item = ScheduleItem.fromJson(operation.data);
          await _scheduleService.removeScheduleItem(item.id);
          await _scheduleService.addScheduleItem(item);
          break;

        case OperationType.deleteScheduleItem:
          final itemId = operation.data['id'] as String;
          await _scheduleService.removeScheduleItem(itemId);
          break;

        case OperationType.toggleScheduleNotification:
          // Use remove then add for updates
          final item = ScheduleItem.fromJson(operation.data['item']);
          await _scheduleService.removeScheduleItem(item.id);
          await _scheduleService.addScheduleItem(item);
          break;

        case OperationType.reorderScheduleItems:
          final day = operation.data['day'] as String;
          final itemsJson = operation.data['items'] as List;
          final items =
              itemsJson.map((json) => ScheduleItem.fromJson(json)).toList();
          await _scheduleService.reorderScheduleItems(day, items);
          break;

        // Section operations
        case OperationType.createSection:
          final data = operation.data;
          final section = Section(
            id: data['id'] ?? '',
            name: data['name'] ?? '',
            assistantId: data['assistantId'] ?? '',
            subjectId: data['subjectId'] ?? '',
            days: data['days'] ?? '',
            time: data['time'] ?? '',
            location: data['location'] ?? '',
          );
          await _sectionService.addSection(section);
          break;

        case OperationType.updateSection:
          final data = operation.data;
          final section = Section(
            id: data['id'] ?? '',
            name: data['name'] ?? '',
            assistantId: data['assistantId'] ?? '',
            subjectId: data['subjectId'] ?? '',
            days: data['days'] ?? '',
            time: data['time'] ?? '',
            location: data['location'] ?? '',
          );
          await _sectionService.updateSection(section);
          break;

        case OperationType.deleteSection:
          final sectionId = operation.data['id'] as String;
          await _sectionService.deleteSection(sectionId);
          break;

        // Material operations - TODO: Implement when MaterialsService is ready
        case OperationType.addMaterial:
          print('⚠️ Material add operation not yet implemented');
          break;

        case OperationType.deleteMaterial:
          print('⚠️ Material delete operation not yet implemented');
          break;

        case OperationType.rateMaterial:
          print('⚠️ Material rating operation not yet implemented');
          break;

        // Lecture operations - TODO: Implement when needed
        case OperationType.addLecture:
        case OperationType.deleteLecture:
        case OperationType.updateLecture:
          print('⚠️ Lecture operations not yet implemented');
          break;

        // Bookmark operations - TODO: Implement when needed
        case OperationType.addBookmark:
        case OperationType.removeBookmark:
          print('⚠️ Bookmark operations not yet implemented');
          break;

        // Profile operations - TODO: Implement when needed
        case OperationType.updateProfile:
        case OperationType.updateTeachingSubjects:
          print('⚠️ Profile operations not yet implemented');
          break;

        // Task operations
        case OperationType.createTask:
          print('🔄 [Sync] Creating task from queue...');
          final task = Task.fromJsonMap(
            operation.data,
          ); // Use JSON deserializer!
          print('   Task ID: ${task.id}');
          print('   Task Title: ${task.title}');
          await _tasksService.addTask(task);
          print('✅ [Sync] Task created successfully - ${task.title}');
          print('   ⚠️  Note: UI will refresh in 2 seconds');
          break;

        case OperationType.updateTask:
          print('🔄 [Sync] Updating task from queue...');
          final task = Task.fromJsonMap(
            operation.data,
          ); // Use JSON deserializer!
          print('   Task ID: ${task.id}');
          await _tasksService.updateTask(task);
          print('✅ [Sync] Task updated successfully - ${task.title}');
          break;

        case OperationType.deleteTask:
          print('🔄 [Sync] Deleting task from queue...');
          final taskId = operation.data['id'] as String;
          print('   Task ID: $taskId');
          await _tasksService.deleteTask(taskId);
          print('✅ [Sync] Task deleted successfully - $taskId');
          break;

        case OperationType.addTaskNote:
        case OperationType.deleteTaskNote:
          print('⚠️ Task note operations not yet implemented');
          break;
      }

      print('✅ Operation processed successfully: ${operation.type}');
    } catch (e) {
      print('❌ Error processing operation ${operation.type}: $e');
      rethrow; // Let queue service handle retry logic
    }
  }

  /// Manually trigger sync (for testing or user-initiated sync)
  Future<void> manualSync() async {
    print('🔄 Manual sync triggered');
    if (!_offlineService.hasConnection) {
      print('❌ Cannot sync: offline');
      syncError.value = 'Cannot sync while offline';
      return;
    }

    await _triggerSync();
  }

  /// Get current sync status
  Map<String, dynamic> get syncStatus => {
    'isSyncing': isSyncing.value,
    'syncedCount': syncedCount.value,
    'totalCount': totalCount.value,
    'error': syncError.value,
    'queueCount': _queueService.getQueueCount(),
  };

  /// Dispose resources
  void dispose() {
    stopListening();
    isSyncing.dispose();
    syncedCount.dispose();
    totalCount.dispose();
    syncError.dispose();
    print('🗑️ OfflineSyncManager disposed');
  }
}

/// Singleton instance for global access
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  OfflineSyncManager? _manager;

  /// Initialize the sync manager (call once in main.dart)
  static Future<void> initialize() async {
    if (_instance._manager != null) {
      print('⚠️ SyncManager already initialized');
      return;
    }

    print('🚀 Initializing SyncManager...');
    _instance._manager = OfflineSyncManager();
    _instance._manager!.startListening();
    print('✅ SyncManager initialized and listening');
  }

  /// Get the singleton manager instance
  static OfflineSyncManager? get instance => _instance._manager;

  /// Manually trigger sync
  static Future<void> manualSync() async {
    if (_instance._manager == null) {
      print('❌ SyncManager not initialized');
      return;
    }
    await _instance._manager!.manualSync();
  }

  /// Dispose the manager
  static void dispose() {
    _instance._manager?.dispose();
    _instance._manager = null;
    print('🗑️ SyncManager disposed');
  }
}
