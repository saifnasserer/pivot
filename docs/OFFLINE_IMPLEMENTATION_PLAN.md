# Offline Support Implementation Plan

## Executive Summary

This document outlines a comprehensive plan to integrate offline support across the application using the existing `OfflineService` and `OfflineQueueService` without affecting current functionality.

## Current State Analysis

### ✅ What We Have

1. **OfflineService** (`lib/services/offline_service.dart`)

   - Monitors connectivity status
   - Provides `isOnline` ValueNotifier
   - Has Riverpod providers ready to use

2. **OfflineQueueService** (`lib/services/offline_queue_service.dart`)

   - Manages queued operations
   - Supports retry logic (max 3 retries)
   - Uses Hive for persistent storage
   - Handles operation types: createTask, updateTask, deleteTask, addTaskNote, deleteTaskNote, updateProfile

3. **CacheService** (already in use)
   - Caches users, sections, subjects, schedule, announcements
   - Uses Hive for persistent storage

### ❌ What's Missing

- Offline awareness in most screens
- Queue operations when offline
- Sync operations when back online
- User feedback for offline actions
- Conflict resolution strategy

### 🐛 Critical Bug: Schedule Tab Content Not Displaying

**Problem:** When opening the schedule tab with cached data, the day selection works but content doesn't display until manually tapping the tab.

**Root Cause:**

- Provider loads cache in constructor (`_loadFromCacheOnly()`)
- State updates but doesn't trigger proper rebuild of content area
- Timing issue between state notification and widget build cycle

**Fix:** Ensure proper state notification and rebuild trigger when loading from cache

---

## Implementation Plan

### Phase 1: Fix Schedule Tab Bug (IMMEDIATE - HIGH PRIORITY)

#### 1.1 Schedule Provider Fix

**File:** `lib/features/schedule/providers/schedule_provider.dart`

**Changes:**

```dart
// In _loadFromCacheOnly() method, after line 91
// Add explicit state notification to ensure rebuild
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {
    // Trigger a state update to ensure widgets rebuild
    state = state.copyWith(schedule: cachedSchedule);
  }
});
```

#### 1.2 Schedule Tab Fix

**File:** `lib/features/profile/screens/profile/schedule_tab.dart`

**Changes:**

```dart
// Line 36-42: Modify initialization to ensure content displays
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {
    final scheduleState = ref.read(scheduleProvider);
    if (scheduleState.schedule.isNotEmpty) {
      _ensureCorrectDaySelected();
      // Force rebuild to ensure content displays
      setState(() {});
    }
  }
});
```

**Expected Result:** Schedule content displays immediately on tab open, even with cached data.

---

### Phase 2: Add Offline Awareness UI (LOW IMPACT - VISUAL ONLY)

#### 2.1 Create Offline Banner Widget

**New File:** `lib/widgets/offline_banner.dart`

**Purpose:** Reusable banner to show offline status at top of screens

**Features:**

- Shows when offline
- Dismissible but reappears if still offline
- Green banner when back online (auto-dismiss after 2s)
- Displays pending operations count if any

#### 2.2 Add Offline Indicators to Screens

**Screens to Update:**

1. `assistant_profile.dart` - Add offline banner at top
2. `doctor_profile.dart` - Add offline banner at top
3. `material_links_screen.dart` - Already has indicator (line 305), keep it
4. `schedule_tab.dart` - Add offline banner
5. `sections_tab.dart` - Add offline banner
6. `subjects_tab.dart` - Add offline banner
7. `bookmark_card.dart` - Add subtle offline indicator in card

**Implementation Approach:**

```dart
// Wrap existing body with Column
Column(
  children: [
    // Add offline banner
    Consumer(
      builder: (context, ref, _) {
        final isOnline = ref.watch(connectivityStatusProvider);
        return isOnline.when(
          data: (online) => online ? SizedBox.shrink() : OfflineBanner(),
          loading: () => SizedBox.shrink(),
          error: (_, __) => SizedBox.shrink(),
        );
      },
    ),
    // Existing body
    Expanded(child: existingBody),
  ],
)
```

**Impact:** Visual only, no functional changes

---

### Phase 3: Queue Operations When Offline (CORE FUNCTIONALITY)

#### 3.1 Extend Operation Types

**File:** `lib/services/offline_queue_service.dart`

**Add New Operation Types:**

```dart
enum OperationType {
  // Existing
  createTask,
  updateTask,
  deleteTask,
  addTaskNote,
  deleteTaskNote,
  updateProfile,

  // New additions
  createScheduleItem,
  updateScheduleItem,
  deleteScheduleItem,
  addMaterial,
  deleteMaterial,
  rateMaterial,
  createSection,
  updateSection,
  deleteSection,
  addBookmark,
  removeBookmark,
  updateTeachingSubjects,
}
```

#### 3.2 Create Offline-Aware Repository Wrapper

**New File:** `lib/services/offline_aware_repository.dart`

**Purpose:** Wrapper around existing repositories to add offline queueing

**Key Features:**

- Checks connectivity before operations
- Queues operations when offline
- Executes immediately when online
- Shows appropriate user feedback
- Returns optimistic updates

**Example Implementation:**

```dart
class OfflineAwareRepository {
  final OfflineService _offlineService;
  final OfflineQueueService _queueService;

  Future<T> executeOperation<T>({
    required OperationType type,
    required Map<String, dynamic> data,
    required Future<T> Function() onlineOperation,
    T? optimisticResult,
  }) async {
    if (_offlineService.isOffline) {
      // Queue operation
      await _queueService.queueOperation(
        QueuedOperation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          data: data,
          timestamp: DateTime.now(),
        ),
      );

      // Return optimistic result if provided
      if (optimisticResult != null) {
        return optimisticResult;
      }

      throw OfflineException('Operation queued for sync when online');
    }

    // Execute immediately when online
    return await onlineOperation();
  }
}
```

#### 3.3 Update Existing Services to Use Wrapper

**Services to Update:**

1. **ScheduleService** - Wrap add/update/delete operations
2. **SectionService** - Wrap create/update/delete operations
3. **MaterialsProvider** - Wrap add/delete/rate operations
4. **BookmarksProvider** - Wrap add/remove operations

**Implementation Strategy:**

- Keep existing service methods unchanged
- Add new `*Offline` methods that use the wrapper
- Update UI calls to use offline-aware methods
- Fallback to original methods if wrapper fails

**Example for ScheduleService:**

```dart
class ScheduleService {
  final OfflineAwareRepository? _offlineRepo;

  // Original method (unchanged)
  Future<void> addScheduleItem(ScheduleItem item) async {
    await _getScheduleCollection().doc(item.id).set(item);
  }

  // New offline-aware method
  Future<void> addScheduleItemOffline(ScheduleItem item) async {
    if (_offlineRepo == null) {
      // Fallback to original method
      return addScheduleItem(item);
    }

    try {
      await _offlineRepo.executeOperation(
        type: OperationType.createScheduleItem,
        data: item.toJson(),
        onlineOperation: () => addScheduleItem(item),
        optimisticResult: null,
      );
    } catch (e) {
      if (e is OfflineException) {
        // Operation queued successfully
        print('✅ Schedule item queued for sync');
      } else {
        rethrow;
      }
    }
  }
}
```

---

### Phase 4: Auto-Sync When Back Online (BACKGROUND PROCESS)

#### 4.1 Create Sync Manager

**New File:** `lib/services/offline_sync_manager.dart`

**Purpose:** Coordinates syncing queued operations when connectivity returns

**Features:**

- Listens to connectivity changes
- Triggers sync when back online
- Processes queue using operation processors
- Shows sync progress in UI
- Handles errors gracefully

**Implementation:**

```dart
class OfflineSyncManager {
  final OfflineService _offlineService;
  final OfflineQueueService _queueService;
  StreamSubscription? _connectivitySubscription;

  void startListening() {
    _connectivitySubscription = _offlineService.isOnline.addListener(() {
      if (_offlineService.isOnline.value) {
        _syncQueuedOperations();
      }
    });
  }

  Future<void> _syncQueuedOperations() async {
    if (_queueService.isQueueEmpty()) return;

    print('🔄 Starting offline sync...');

    await _queueService.processQueue(
      processor: _processOperation,
      onProgress: (completed, total) {
        print('📊 Sync progress: $completed/$total');
      },
    );
  }

  Future<void> _processOperation(QueuedOperation operation) async {
    switch (operation.type) {
      case OperationType.createScheduleItem:
        // Execute the queued operation
        final item = ScheduleItem.fromJson(operation.data);
        await ScheduleService().addScheduleItem(item);
        break;

      case OperationType.deleteScheduleItem:
        // Execute delete
        await ScheduleService().deleteScheduleItem(operation.data['id']);
        break;

      // Add cases for all operation types
      default:
        print('⚠️ Unknown operation type: ${operation.type}');
    }
  }
}
```

#### 4.2 Initialize Sync Manager in App Startup

**File:** `lib/main.dart`

**Add to initialization:**

```dart
// After initializing OfflineService and OfflineQueueService
final syncManager = OfflineSyncManager(
  offlineService: OfflineService(),
  queueService: OfflineQueueService(),
);
syncManager.startListening();
```

---

### Phase 5: User Feedback & UI Enhancements

#### 5.1 Add Pending Operations Badge

**Location:** App bar or bottom navigation

**Shows:**

- Number of pending operations
- Tappable to show pending operations list
- Syncing indicator when syncing

#### 5.2 Create Pending Operations Screen

**New File:** `lib/features/offline/screens/pending_operations_screen.dart`

**Features:**

- List of all pending operations
- Operation type and timestamp
- Retry count
- Manual retry button
- Delete from queue option
- Sync all button

#### 5.3 Add Snackbar Feedback

**Update existing screens to show:**

- "✅ Added to queue, will sync when online" (offline)
- "🔄 Syncing..." (when back online)
- "✅ Synced successfully" (after sync)
- "❌ Sync failed, will retry" (on error)

---

## Testing Strategy

### Unit Tests

1. Test `OfflineQueueService` queueing operations
2. Test `OfflineAwareRepository` offline/online detection
3. Test `OfflineSyncManager` processing operations
4. Test operation retry logic

### Integration Tests

1. Test schedule operations offline → online sync
2. Test material operations offline → online sync
3. Test conflict resolution
4. Test queue clearing after max retries

### Manual Testing Checklist

- [ ] Schedule tab displays content immediately on load
- [ ] Add schedule item while offline
- [ ] Delete schedule item while offline
- [ ] Go back online and verify sync
- [ ] Add material while offline
- [ ] Rate material while offline
- [ ] Add bookmark while offline
- [ ] Verify pending operations badge shows count
- [ ] Verify all operations sync when online
- [ ] Test max retry logic (force 3 failures)
- [ ] Test offline banner appears/disappears correctly

---

## Migration Path (Rollout Strategy)

### Week 1: Critical Bug Fix + Foundation

- ✅ Fix schedule tab bug
- ✅ Test schedule tab fix thoroughly
- ✅ Add offline banner widget
- ✅ Add offline indicators to all screens (visual only)

### Week 2: Queue Infrastructure

- ✅ Extend operation types
- ✅ Create offline-aware repository wrapper
- ✅ Update schedule service with offline support
- ✅ Test schedule offline queueing

### Week 3: Expand to Other Services

- ✅ Update materials provider with offline support
- ✅ Update sections provider with offline support
- ✅ Update bookmarks with offline support
- ✅ Test all offline operations

### Week 4: Auto-Sync & Polish

- ✅ Implement sync manager
- ✅ Add pending operations UI
- ✅ Add sync progress indicators
- ✅ Comprehensive testing
- ✅ Deploy to beta testers

---

## Risk Mitigation

### Risk 1: Breaking Existing Functionality

**Mitigation:**

- Keep all existing methods unchanged
- Add new `*Offline` methods alongside
- Gradual rollout per feature
- Easy rollback by reverting to original methods

### Risk 2: Sync Conflicts

**Mitigation:**

- Always use "last write wins" strategy
- Queue operations with timestamps
- Process operations in chronological order
- Log conflicts for manual resolution

### Risk 3: Queue Growing Too Large

**Mitigation:**

- Implement max queue size (e.g., 100 operations)
- Clear old operations after 7 days
- Allow manual queue clearing
- Warn users if queue is too large

### Risk 4: Battery Drain from Sync

**Mitigation:**

- Sync only when back online (not periodic)
- Batch operations for efficiency
- Limit concurrent operations
- Add user setting to disable auto-sync

---

## Success Metrics

### Technical Metrics

- 0 breaking changes to existing functionality
- < 100ms added latency for online operations
- > 95% success rate for offline syncing
- < 5% retry rate for operations

### User Experience Metrics

- Users can perform all actions while offline
- Clear feedback for offline actions
- Smooth sync experience when back online
- No data loss due to offline usage

---

## Appendix A: Schedule Tab Bug Fix Details

### Root Cause Analysis

1. `ScheduleProvider` constructor calls `_loadFromCacheOnly()`
2. This synchronously loads cache and updates state
3. `ScheduleTab.didChangeDependencies()` runs AFTER constructor
4. State is already set, but widget tree hasn't fully built
5. `_ensureCorrectDaySelected()` sets `_selectedDayIndex` correctly
6. BUT `build()` uses `getScheduleForDay(currentDay)` which may not trigger rebuild
7. Manual tab tap forces rebuild, showing content

### Solution Details

**Option 1: Force Rebuild in Tab (Preferred)**

```dart
// In schedule_tab.dart, line 36-42
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {
    final scheduleState = ref.read(scheduleProvider);
    if (scheduleState.schedule.isNotEmpty) {
      _ensureCorrectDaySelected();
      // Force rebuild
      setState(() {});
    }
  }
});
```

**Option 2: Delay Cache Load in Provider**

```dart
// In schedule_provider.dart constructor
ScheduleNotifier(this._ref) : super(const ScheduleState()) {
  // Delay cache load to next frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadFromCacheOnly();
  });
}
```

**Option 3: Use AsyncValue in Provider**

```dart
// More complex but cleaner - refactor to use AsyncValue
final scheduleProvider = FutureProvider<ScheduleState>((ref) async {
  // Load cache asynchronously
  return await loadScheduleFromCache();
});
```

**Recommended:** Option 1 (simplest, least disruptive)

---

## Appendix B: Code Examples

### Example: Offline-Aware Add Schedule Item

```dart
// In schedule_tab.dart
void _showAddScheduleDialog(BuildContext context, String selectedDay) async {
  final result = await showDialog(...);

  if (result != null) {
    try {
      // Check if online
      final isOnline = ref.read(connectivityStatusProvider).value ?? true;

      if (isOnline) {
        // Normal flow
        await ref.read(scheduleProvider.notifier).addScheduleItem(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم إضافة المحاضرة')),
        );
      } else {
        // Offline flow - queue operation
        await ref.read(offlineQueueService).queueOperation(
          QueuedOperation(
            id: result.id,
            type: OperationType.createScheduleItem,
            data: result.toJson(),
            timestamp: DateTime.now(),
          ),
        );

        // Optimistically update UI
        ref.read(scheduleProvider.notifier).addScheduleItemOptimistic(result);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📝 تم الحفظ، سيتم المزامنة عند الاتصال'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ: $e')),
      );
    }
  }
}
```

---

## Conclusion

This implementation plan provides a comprehensive approach to adding offline support while:

1. ✅ Fixing the critical schedule tab bug
2. ✅ Not affecting current functionality
3. ✅ Adding robust offline queueing
4. ✅ Providing clear user feedback
5. ✅ Supporting auto-sync when back online

The phased approach allows for incremental rollout and easy rollback if issues arise.
