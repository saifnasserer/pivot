# Systematic autoDispose Fix - Pivot Project

**Date**: October 1, 2025  
**Issue**: Bad State - Multiple providers using autoDispose without mounted checks  
**Status**: 🔄 In Progress

---

## 🚨 Problem Summary

**Error Pattern**:

```
Bad state: Tried to use [Provider]Notifier after `dispose` was called.
Consider checking `mounted`.
```

### Root Cause

Multiple Riverpod providers use `StateNotifierProvider.autoDispose` for memory efficiency, but their async methods don't check if the provider is still `mounted` before updating state. This creates crashes when:

1. User navigates away quickly
2. Async operations complete after provider disposal
3. State updates attempted on disposed provider

### Impact

- **Severity**: Critical - Causes app crashes
- **Frequency**: High - Happens frequently during normal navigation
- **User Experience**: Very poor - Users lose work, app appears unstable

---

## 📊 Affected Providers

Total `autoDispose` providers found: **17**

### ✅ Fixed (2/17 - 12%)

1. **`lib/features/profile/providers/edit_profile_provider.dart`** ✅

   - Status: Fixed
   - Methods protected: `loadProfile()`, `saveProfile()`
   - Has graceful degradation for settingsProvider

2. **`lib/features/profile/providers/profile_provider.dart`** ✅
   - Status: Fixed
   - Methods protected: `initialize()`, `updateProfile()`, `changePassword()`, `updateProfileImage()`, `toggleBiometricAuth()`, `updateNotificationSettings()`, `logout()`

### ⏳ Needs Review (15/17 - 88%)

3. **`lib/features/administration/providers/sections_provider.dart`**
   - Priority: High
   - Likely has: `fetchSections()`, CRUD operations
4. **`lib/features/announcements/providers/announcements_provider.dart`**
   - Priority: High (heavily used)
   - Likely has: `fetchAnnouncements()`, `createAnnouncement()`, `updateAnnouncement()`, `deleteAnnouncement()`
5. **`lib/features/home/providers/home_provider.dart`** (if exists)
   - Priority: High
   - Likely has: Data loading methods
6. **`lib/features/schedule/providers/schedule_provider.dart`**
   - Priority: High
   - Likely has: `fetchSchedule()`, CRUD operations
7. **`lib/features/settings/providers/settings_provider.dart`**
   - Priority: High (causes cascading failures)
   - Has: `fetchSectionCounts()` - KNOWN ISSUE
8. **`lib/features/subjects/providers/subjects_provider.dart`**
   - Priority: Medium
   - Likely has: `fetchSubjects()`, CRUD operations
9. **`lib/features/tasks/providers/tasks_provider.dart`**
   - Priority: High (frequently used)
   - Likely has: `fetchTasks()`, CRUD operations
10. **`lib/features/user/providers/user_profile_provider.dart`**
    - Priority: Critical (core functionality)
    - Has: `loadLoggedInUserProfile()`, `getUserProfileById()`, update methods

11-17. **Additional providers** (need identification)

---

## 🔧 Standard Fix Pattern

Apply this pattern to **ALL** async methods in autoDispose providers:

### Pattern Template

```dart
Future<ReturnType> methodName(parameters) async {
  // 1. Early exit check
  if (!mounted) return defaultValue;

  // 2. Initial state update (if needed)
  if (mounted) {
    state = state.copyWith(isLoading: true);
  }

  try {
    // 3. First async operation
    final result1 = await asyncOperation1();
    if (!mounted) return defaultValue; // Check after EVERY await

    // 4. Second async operation
    final result2 = await asyncOperation2();
    if (!mounted) return defaultValue; // Check after EVERY await

    // 5. Final state update
    if (mounted) {
      state = state.copyWith(
        isLoading: false,
        data: result1,
      );
    }

    return result1;
  } catch (e) {
    // 6. Error handling
    if (mounted) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    return defaultValue;
  }
}
```

### Return Values for Early Exit

| Method Return Type  | Default Return Value |
| ------------------- | -------------------- |
| `Future<void>`      | `return;`            |
| `Future<bool>`      | `return false;`      |
| `Future<T?>`        | `return null;`       |
| `Future<List<T>>`   | `return [];`         |
| `Future<Map<K, V>>` | `return {};`         |

---

## 📋 Fix Checklist by Provider

### 1. User Profile Provider ⏳ CRITICAL

**File**: `lib/features/user/providers/user_profile_provider.dart`

- [ ] Review all async methods
- [ ] Add mounted checks after each await
- [ ] Test: Navigate during profile load
- [ ] Test: Navigate during profile update

### 2. Announcements Provider ⏳ HIGH

**File**: `lib/features/announcements/providers/announcements_provider.dart`

- [ ] Review all async methods
- [ ] Add mounted checks
- [ ] Test: Navigate during fetch
- [ ] Test: Navigate during create/update

### 3. Tasks Provider ⏳ HIGH

**File**: `lib/features/tasks/providers/tasks_provider.dart`

- [ ] Review all async methods
- [ ] Add mounted checks
- [ ] Test: Navigate during task operations

### 4. Schedule Provider ⏳ HIGH

**File**: `lib/features/schedule/providers/schedule_provider.dart`

- [ ] Review all async methods
- [ ] Add mounted checks
- [ ] Test: Navigate during schedule load

### 5. Settings Provider ⏳ HIGH (CAUSES CASCADING FAILURES)

**File**: `lib/features/settings/providers/settings_provider.dart`

- [ ] Fix `fetchSectionCounts()` - Known to cause issues in edit_profile
- [ ] Add mounted checks to all methods
- [ ] Consider if this should use autoDispose at all (used by many screens)
- [ ] Test: Navigate during settings load

### 6. Sections Provider ⏳ MEDIUM

**File**: `lib/features/administration/providers/sections_provider.dart`

- [ ] Review all async methods
- [ ] Add mounted checks
- [ ] Test: Navigate during section operations

### 7. Subjects Provider ⏳ MEDIUM

**File**: `lib/features/subjects/providers/subjects_provider.dart`

- [ ] Review all async methods
- [ ] Add mounted checks
- [ ] Test: Navigate during subject operations

### 8-17. Remaining Providers ⏳

- [ ] Identify all remaining autoDispose providers
- [ ] Apply fix pattern to each
- [ ] Test each provider

---

## 🎯 Priority Fix Order

### Phase 1: Critical (Do First)

1. ✅ `profile_provider.dart` - DONE
2. ✅ `edit_profile_provider.dart` - DONE
3. ⏳ `user_profile_provider.dart` - Core functionality
4. ⏳ `settings_provider.dart` - Causes cascading failures

### Phase 2: High Priority (Do Next)

5. ⏳ `announcements_provider.dart` - Heavily used
6. ⏳ `tasks_provider.dart` - Frequently accessed
7. ⏳ `schedule_provider.dart` - Daily use

### Phase 3: Medium Priority

8. ⏳ `sections_provider.dart`
9. ⏳ `subjects_provider.dart`
   10-17. ⏳ Remaining providers

---

## 🧪 Testing Strategy

### For Each Fixed Provider

#### Manual Testing

1. **Quick Navigation Test**

   - Open screen using provider
   - Immediately navigate back
   - **Expected**: No crash, no error logs

2. **During Load Test**

   - Start loading data
   - Navigate away mid-load
   - **Expected**: Operation cancels gracefully

3. **During Save Test**

   - Start save operation
   - Navigate away mid-save
   - **Expected**: No crash, may complete or cancel

4. **Rapid Navigation Test**
   - Quickly open/close screen 10 times
   - **Expected**: No crashes, no memory leaks

#### Automated Testing (Recommended)

```dart
test('Provider handles dispose during async operation', () async {
  final container = ProviderContainer();
  final notifier = container.read(myProvider.notifier);

  // Start async operation
  final future = notifier.someAsyncMethod();

  // Dispose provider immediately
  container.dispose();

  // Should not throw
  await expectLater(future, completes);
});
```

---

## 📈 Progress Tracking

**Overall Progress**: 2/17 (12%) ✅

| Category | Fixed | Total | Progress |
| -------- | ----- | ----- | -------- |
| Critical | 2     | 4     | 50% ⏳   |
| High     | 0     | 3     | 0% ❌    |
| Medium   | 0     | 10    | 0% ❌    |

### Target Completion

- **Phase 1 (Critical)**: By end of Day 1
- **Phase 2 (High)**: By end of Day 2
- **Phase 3 (Medium)**: By end of Day 3

---

## 🔍 How to Identify Which Methods Need Fixing

For each provider file:

1. **Find the provider definition**:

   ```dart
   final myProvider = StateNotifierProvider.autoDispose<...>
   ```

2. **List all async methods** in the notifier class:

   ```dart
   class MyNotifier extends StateNotifier<MyState> {
     Future<void> method1() async { ... }  // ← Fix this
     Future<bool> method2() async { ... }  // ← Fix this
     void syncMethod() { ... }              // ← OK, no fix needed
   }
   ```

3. **Check for state updates after await**:

   ```dart
   Future<void> badMethod() async {
     await something();
     state = newState; // ❌ NEEDS FIX - no mounted check!
   }

   Future<void> goodMethod() async {
     await something();
     if (!mounted) return;  // ✅ SAFE
     state = newState;
   }
   ```

---

## 💡 Alternative Solutions Considered

### Option 1: Remove autoDispose ❌

**Pros**: No disposal issues  
**Cons**: Memory leaks, stale data, against best practices  
**Decision**: NO - Keep autoDispose for memory efficiency

### Option 2: Use keepAlive ❌

**Pros**: Provider stays alive longer  
**Cons**: Defeats purpose of autoDispose, memory issues  
**Decision**: NO - Not a real solution

### Option 3: Convert to regular Provider ❌

**Pros**: Never disposes  
**Cons**: Defeats entire purpose of state management  
**Decision**: NO - Wrong approach

### Option 4: Add mounted checks ✅ (CHOSEN)

**Pros**:

- Maintains autoDispose benefits
- Prevents crashes
- Graceful error handling
- Best practice pattern

**Cons**:

- Requires code changes in many files
- Need to be diligent about checking after every await

**Decision**: YES - This is the correct solution

---

## 📚 Resources for Developers

### Quick Reference: Mounted Check Pattern

```dart
// ✅ CORRECT - Check before and after async
Future<void> doSomething() async {
  if (!mounted) return;           // Early exit

  if (mounted) {                  // Guard state update
    state = state.copyWith(loading: true);
  }

  await asyncOperation();
  if (!mounted) return;           // Check after await

  if (mounted) {                  // Guard state update
    state = state.copyWith(loading: false);
  }
}

// ❌ WRONG - No checks
Future<void> doSomething() async {
  state = state.copyWith(loading: true);  // May be disposed
  await asyncOperation();
  state = state.copyWith(loading: false); // May be disposed
}
```

### Common Mistakes

1. **Forgetting to check after EVERY await**

   ```dart
   await operation1();
   // Missing check here! ❌
   await operation2();
   ```

2. **Not returning after mounted check**

   ```dart
   if (!mounted) {
     // Missing return! ❌
   }
   state = newState; // Still executes!
   ```

3. **Checking mounted but not guarding state update**
   ```dart
   if (!mounted) return;
   state = newState; // ❌ Still needs guard!
   // Should be:
   if (mounted) {
     state = newState; // ✅
   }
   ```

---

## 🚀 Next Steps

### Immediate Actions

1. [ ] Review and fix `user_profile_provider.dart`
2. [ ] Review and fix `settings_provider.dart`
3. [ ] Review and fix `announcements_provider.dart`
4. [ ] Test all fixed providers

### Short-term Actions

1. [ ] Create automated tests for dispose scenarios
2. [ ] Add linter rule to catch missing mounted checks (if possible)
3. [ ] Document pattern in team guidelines

### Long-term Actions

1. [ ] Consider custom StateNotifier base class with built-in mounted checks
2. [ ] Review all non-autoDispose providers for similar issues
3. [ ] Add to code review checklist

---

## 📝 Notes

### Why This Happens

- Flutter's navigation is fast - screens can be popped before async completes
- Firebase operations can be slow (network latency)
- Multiple screens may share providers that dispose independently
- User navigation patterns are unpredictable

### Prevention for New Code

When creating new autoDispose providers:

1. ✅ Always add mounted checks after await
2. ✅ Test quick navigation scenarios
3. ✅ Consider if provider should use autoDispose
4. ✅ Document async method behavior

---

**Status**: 🔄 In Progress  
**Last Updated**: October 1, 2025  
**Next Review**: After Phase 1 completion

---

**Remember**: Every async method in an autoDispose provider needs mounted checks!


