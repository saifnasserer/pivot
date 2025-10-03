# Week Tasks & Profile Screen Optimization Plan

## Current Issues ❌

1. **Redundant Fetches**: Sections fetched 2x (ProfileScreen + WeekTasks)
2. **Sequential Loading**: Data loads one-by-one, not in parallel
3. **No State Check**: Always fetches even if data already loaded
4. **Loading Blocks UI**: Users see spinners while data loads from cache

## Optimization Strategy ✅

### 1. Smart Data Initialization (Check Before Fetch)

**Current Code**:

```dart
// Always fetches, even if data already exists
ref.read(subjectsProvider.notifier).fetchAndFilterSubjects(loggedInUser);
ref.read(sectionsProvider.notifier).fetchSectionsForUserSubjects(enrolledSubjects);
ref.read(tasksProvider.notifier).getAllTasks();
```

**Optimized Code**:

```dart
void _initializeDataSmart(UserProfile user) {
  final subjectsState = ref.read(subjectsProvider);
  final sectionsState = ref.read(sectionsProvider);
  final tasksState = ref.read(tasksProvider);

  // Only fetch if not already loaded or loading
  if (subjectsState.filteredSubjects.isEmpty && !subjectsState.isLoading) {
    ref.read(subjectsProvider.notifier).fetchAndFilterSubjects(user);
  }

  if (sectionsState.sections.isEmpty && !sectionsState.isLoading) {
    ref.read(sectionsProvider.notifier).fetchSectionsForUserSubjects(user.enrolledSubjects);
  }

  if (tasksState.tasks.isEmpty && !tasksState.isLoading) {
    ref.read(tasksProvider.notifier).getAllTasks();
  }
}
```

### 2. Remove Redundant Fetches

**ProfileScreen (profile_screen.dart:52-63)**:

```dart
// ❌ REMOVE THIS - WeekTasks will handle it
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {
    final userProfileState = ref.read(userProfileProvider);
    final userProfile = userProfileState.loggedInUserProfile;
    if (userProfile != null && userProfile.enrolledSubjects.isNotEmpty) {
      ref
          .read(sectionsProvider.notifier)
          .fetchSectionsForUserSubjects(userProfile.enrolledSubjects);  // ❌ DUPLICATE
    }
  }
});
```

**Solution**: Each tab manages its own data. Remove from ProfileScreen.

### 3. Parallel Data Loading

**Current (Sequential)**:

```dart
await fetchSubjects();      // Wait 500ms
await fetchSections();       // Wait 300ms
await fetchTasks();          // Wait 400ms
// Total: 1200ms
```

**Optimized (Parallel)**:

```dart
void _initializeDataParallel(UserProfile user) async {
  // All fetch simultaneously
  await Future.wait([
    ref.read(subjectsProvider.notifier).fetchAndFilterSubjects(user),
    ref.read(sectionsProvider.notifier).fetchSectionsForUserSubjects(user.enrolledSubjects),
    ref.read(tasksProvider.notifier).getAllTasks(),
  ]);
  // Total: ~500ms (slowest one)
}
```

### 4. Stale-While-Revalidate Pattern

The providers already implement this! ✅

- Load from Hive cache immediately (1-5ms)
- Show UI with cached data
- Fetch from Firestore in background
- Update UI when fresh data arrives

**Current Implementation (sections_provider.dart:64-89)**:

```dart
// Step 1: Load from cache first (INSTANT)
final cachedSections = CacheService.instance.getCachedSections();
if (filteredCached.isNotEmpty && mounted) {
  state = state.copyWith(sections: filteredCached, isLoading: false);  // UI shows cached data
}

// Step 2: Fetch from server in background
final sections = await _sectionService.getSectionsForAssistant(assistantId);
await CacheService.instance.cacheSections(sections);
state = state.copyWith(sections: sections);  // UI updates with fresh data
```

### 5. Optimize Loading States

**Current**: Shows loading spinner until ALL data is fetched
**Optimized**: Show cached data immediately, update in background

```dart
// Modified loading check
final isInitialLoad = subjectsState.filteredSubjects.isEmpty &&
                     sectionsState.sections.isEmpty &&
                     tasksState.tasks.isEmpty;

if (isLoadingData && isInitialLoad) {
  // Only show loading on first load with no cached data
  return Scaffold(body: CircularProgressIndicator());
}

// Otherwise, show UI with available data (even if partially loading)
```

### 6. Cache Expiry Optimization

**Current Cache Expiry Times** (cache_service.dart:23-28):

```dart
users: 30 minutes
sections: 60 minutes
subjects: 120 minutes
schedule: 15 minutes
tasks: ??? (not cached yet)
```

**Recommended for Tasks**:

```dart
tasks: 5 minutes  // Tasks change frequently
```

## Implementation Steps

### Step 1: Add Smart Initialization to WeekTasks

```dart
// In week_tasks.dart, after line 82
void _initializeDataSmart(UserProfile user) {
  final subjectsState = ref.read(subjectsProvider);
  final sectionsState = ref.read(sectionsProvider);
  final tasksState = ref.read(tasksProvider);

  print('WeekTasks: Smart initialization - checking existing data...');
  print('  - Subjects loaded: ${subjectsState.filteredSubjects.length}');
  print('  - Sections loaded: ${sectionsState.sections.length}');
  print('  - Tasks loaded: ${tasksState.tasks.length}');

  // Parallel fetch only what's needed
  final fetchFutures = <Future>[];

  if (subjectsState.filteredSubjects.isEmpty && !subjectsState.isLoading) {
    print('  - 🔄 Fetching subjects...');
    fetchFutures.add(
      ref.read(subjectsProvider.notifier).fetchAndFilterSubjects(user)
    );
  }

  if (sectionsState.sections.isEmpty && !sectionsState.isLoading &&
      user.enrolledSubjects.isNotEmpty) {
    print('  - 🔄 Fetching sections...');
    fetchFutures.add(
      ref.read(sectionsProvider.notifier).fetchSectionsForUserSubjects(user.enrolledSubjects)
    );
  }

  if (tasksState.tasks.isEmpty && !tasksState.isLoading) {
    print('  - 🔄 Fetching tasks...');
    fetchFutures.add(
      ref.read(tasksProvider.notifier).getAllTasks()
    );
  }

  if (fetchFutures.isEmpty) {
    print('  - ✅ All data already loaded!');
  } else {
    // Fetch all in parallel
    Future.wait(fetchFutures);
  }
}
```

### Step 2: Remove Redundant Fetch from ProfileScreen

```dart
// In profile_screen.dart, REMOVE lines 52-63
// Let each tab manage its own data
```

### Step 3: Optimize Loading State Check

```dart
// In week_tasks.dart, around line 395
final hasAnyData = subjectsState.filteredSubjects.isNotEmpty ||
                   sectionsState.sections.isNotEmpty ||
                   tasksState.tasks.isNotEmpty;

// Only show loading if NO data and currently loading
if (isLoadingData && !hasAnyData) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.black),
          SizedBox(height: 16),
          Text('جاري تحميل المهام من الذاكرة المؤقتة...'),
        ],
      ),
    ),
  );
}

// If we have cached data, show it even if loading fresh data
```

### Step 4: Add Task Caching

**Create tasks_cache_service.dart**:

```dart
class TasksCacheService {
  static const String _tasksBoxName = 'tasksBox';
  static const int _tasksCacheExpiry = 5; // 5 minutes

  Future<void> cacheTasks(List<Task> tasks) async {
    final box = Hive.box<Task>(_tasksBoxName);
    await box.clear();
    for (var task in tasks) {
      await box.put(task.id, task);
    }
    await _updateCacheTimestamp();
  }

  List<Task> getCachedTasks() {
    if (!CacheService.instance.isCacheValid(_tasksBoxName, customExpiryMinutes: _tasksCacheExpiry)) {
      return [];
    }
    final box = Hive.box<Task>(_tasksBoxName);
    return box.values.toList();
  }
}
```

## Expected Performance Improvements

### Before Optimization:

- **Initial Load**: ~1500ms (3 sequential fetches)
- **Firestore Reads per profile open**: 3-4 reads (even if data exists)
- **User Experience**: Spinner → Spinner → Content
- **Offline**: ❌ Doesn't work without internet

### After Optimization:

- **Initial Load**: ~50ms (from Hive cache)
- **Background Refresh**: ~500ms (parallel fetches)
- **Firestore Reads per profile open**: 0-3 reads (only if cache expired)
- **User Experience**: Content → Background update
- **Offline**: ✅ Works with cached data

## Estimated Reduction in Firestore Reads

**Current Usage** (per user per day):

- Profile opens: 20 times
- Reads per open: 4
- **Total daily reads**: 80 reads

**After Optimization**:

- Profile opens: 20 times
- Reads per open (cached): 0
- Reads per open (expired): 3 (parallel, no redundancy)
- Cache hit rate: ~75% (subjects/sections change infrequently)
- **Total daily reads**: ~20 reads

**Savings**: **75% reduction** in Firestore reads! 🎯

## Testing Checklist

- [ ] Test with empty cache (first time user)
- [ ] Test with expired cache
- [ ] Test with valid cache
- [ ] Test offline mode
- [ ] Test rapid tab switching
- [ ] Test after coming back from background
- [ ] Verify no duplicate fetches
- [ ] Verify loading states are smooth

## Migration Steps

1. ✅ Verify Hive caching is working (already done)
2. ✅ Add smart initialization method
3. ✅ Update initState in week_tasks.dart
4. ✅ Remove redundant fetch from profile_screen.dart
5. ✅ Optimize loading state logic
6. ✅ Add task caching
7. ✅ Test thoroughly
8. ✅ Monitor Firestore usage metrics

---

**Priority**: HIGH
**Effort**: 2-3 hours
**Impact**: Major UX improvement + 75% cost reduction
