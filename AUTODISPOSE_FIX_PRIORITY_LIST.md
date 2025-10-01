# autoDispose Fix - Priority Action List

**Date**: October 1, 2025  
**Total Providers with autoDispose**: 14  
**Fixed**: 2 (14%)  
**Remaining**: 12 (86%)

---

## ✅ FIXED (2/14)

### 1. ✅ edit_profile_provider.dart

- **Status**: Fixed & Tested
- **Fixed Methods**: `loadProfile()`, `saveProfile()`
- **Special**: Has graceful degradation for settingsProvider
- **No Issues Found**: ✓

### 2. ✅ profile_provider.dart

- **Status**: Fixed & Tested
- **Fixed Methods**: All 7 async methods
- **No Issues Found**: ✓

---

## 🔥 CRITICAL PRIORITY (Fix TODAY)

### 3. ⏳ user_profile_provider.dart

**Why Critical**: Core user functionality, used everywhere
**Methods to Fix**:

- `loadLoggedInUserProfile()`
- `getUserProfileById()`
- `restoreLoggedInUserProfile()`
- `updateSocialMediaLinks()`
- `updateAboutMe()`

**Impact**: High - Used by almost every screen

### 4. ⏳ settings_provider.dart

**Why Critical**: Causes cascading failures in other providers
**Methods to Fix**:

- `fetchSectionCounts()` ← **Known to cause issues**
- Other settings methods

**Impact**: Critical - When this crashes, it crashes other providers

### 5. ⏳ auth_provider.dart

**Why Critical**: Login/logout functionality
**Methods to Fix**:

- `login()`
- `logout()`
- `signup()`
- Any session management

**Impact**: Critical - App unusable if broken

---

## 🚨 HIGH PRIORITY (Fix Day 2)

### 6. ⏳ announcements_provider.dart

**Why High**: Most visible feature, heavily used
**Methods to Fix**:

- `fetchAnnouncements()`
- `createAnnouncement()`
- `updateAnnouncement()`
- `deleteAnnouncement()`
- `uploadImage()` if present

**Impact**: High - Main content feature

### 7. ⏳ task_provider.dart

**Why High**: Daily student usage
**Methods to Fix**:

- `fetchTasks()`
- `createTask()`
- `updateTask()`
- `deleteTask()`
- `toggleComplete()`

**Impact**: High - Core productivity feature

### 8. ⏳ schedule_provider.dart

**Why High**: Daily student usage
**Methods to Fix**:

- `fetchSchedule()`
- `createScheduleItem()`
- `updateScheduleItem()`
- `deleteScheduleItem()`

**Impact**: High - Core feature

---

## ⚠️ MEDIUM PRIORITY (Fix Day 3)

### 9. ⏳ home_provider.dart

**Why Medium**: Dashboard data
**Methods to Fix**: TBD - need to review file

**Impact**: Medium - Affects home screen

### 10. ⏳ sections_provider.dart

**Why Medium**: Admin feature
**Methods to Fix**:

- `fetchSections()`
- CRUD operations

**Impact**: Medium - Admin/Assistant use

### 11. ⏳ subjects_provider.dart

**Why Medium**: Educational content
**Methods to Fix**:

- `fetchSubjects()`
- CRUD operations

**Impact**: Medium - Used by multiple roles

### 12. ⏳ administration_provider.dart

**Why Medium**: Admin panel
**Methods to Fix**: TBD - need to review file

**Impact**: Medium - Admin only

---

## 🔵 LOW PRIORITY (Fix Day 4)

### 13. ⏳ guide_provider.dart

**Why Low**: Optional feature
**Methods to Fix**: TBD

**Impact**: Low - Nice to have

### 14. ⏳ onboarding_provider.dart

**Why Low**: One-time use
**Methods to Fix**: Onboarding flow

**Impact**: Low - Only affects new users once

---

## 🎯 Today's Action Plan

### Step 1: Fix Critical Providers (3-4 hours)

```bash
# Fix these in order:
1. user_profile_provider.dart    (1 hour)
2. settings_provider.dart         (30 min)
3. auth_provider.dart             (1 hour)
```

### Step 2: Test Critical Providers (1 hour)

- [ ] Test user profile operations
- [ ] Test settings loading
- [ ] Test login/logout
- [ ] Test quick navigation

### Step 3: Fix High Priority (2-3 hours)

```bash
4. announcements_provider.dart    (1 hour)
5. task_provider.dart             (45 min)
6. schedule_provider.dart         (45 min)
```

### Step 4: Test High Priority (1 hour)

- [ ] Test announcements CRUD
- [ ] Test tasks CRUD
- [ ] Test schedule CRUD

---

## 📋 Quick Fix Checklist (Per Provider)

For each provider file:

1. [ ] Open the provider file
2. [ ] Find all `Future<...>` methods
3. [ ] For EACH async method:
   - [ ] Add `if (!mounted) return` at the start
   - [ ] Add `if (mounted)` before EVERY state update
   - [ ] Add `if (!mounted) return` after EVERY `await`
   - [ ] Wrap error handlers with `if (mounted)`
4. [ ] Run `flutter analyze [filename]`
5. [ ] Test quick navigation scenarios
6. [ ] Mark as complete

---

## 🧪 Test Script (Use for Each)

```dart
// Quick test for each provider
void testProviderDispose() async {
  // 1. Open screen that uses provider
  // 2. Wait 100ms
  // 3. Navigate back immediately
  // 4. Check logs - should see NO "Bad state" errors

  // Repeat 10 times quickly
  for (int i = 0; i < 10; i++) {
    await openScreen();
    await Future.delayed(Duration(milliseconds: 100));
    await navigateBack();
  }
}
```

---

## 📊 Progress Tracker

Update this after each fix:

| #   | Provider       | Priority | Status  | Time | Tested |
| --- | -------------- | -------- | ------- | ---- | ------ |
| 1   | edit_profile   | Critical | ✅ Done | 45m  | ✅     |
| 2   | profile        | Critical | ✅ Done | 30m  | ✅     |
| 3   | user_profile   | Critical | ⏳ Todo | -    | -      |
| 4   | settings       | Critical | ⏳ Todo | -    | -      |
| 5   | auth           | Critical | ⏳ Todo | -    | -      |
| 6   | announcements  | High     | ⏳ Todo | -    | -      |
| 7   | task           | High     | ⏳ Todo | -    | -      |
| 8   | schedule       | High     | ⏳ Todo | -    | -      |
| 9   | home           | Medium   | ⏳ Todo | -    | -      |
| 10  | sections       | Medium   | ⏳ Todo | -    | -      |
| 11  | subjects       | Medium   | ⏳ Todo | -    | -      |
| 12  | administration | Medium   | ⏳ Todo | -    | -      |
| 13  | guide          | Low      | ⏳ Todo | -    | -      |
| 14  | onboarding     | Low      | ⏳ Todo | -    | -      |

---

## 🎯 Success Criteria

**Milestone 1: Critical Fixed**

- [ ] user_profile_provider.dart ✓
- [ ] settings_provider.dart ✓
- [ ] auth_provider.dart ✓
- [ ] All critical paths tested
- [ ] **NO "Bad state" errors in logs**

**Milestone 2: High Priority Fixed**

- [ ] announcements_provider.dart ✓
- [ ] task_provider.dart ✓
- [ ] schedule_provider.dart ✓
- [ ] All main features tested

**Milestone 3: All Fixed**

- [ ] All 14 providers fixed
- [ ] All tested
- [ ] Documentation updated
- [ ] Beta testing can proceed safely

---

## 💡 Tips for Fast Fixing

1. **Use Find & Replace (Carefully)**

   - Find: `await ` (with space)
   - After each occurrence, add: `if (!mounted) return;`

2. **Use Multi-Cursor (VS Code/Cursor)**

   - Select all state updates
   - Wrap with `if (mounted) { ... }`

3. **Copy the Pattern**

   - Use edit_profile_provider.dart as reference
   - Copy-paste the pattern

4. **Test Continuously**
   - Fix one, test one
   - Don't fix all then test all

---

## 🆘 If You Get Stuck

**Still seeing "Bad state" errors?**

1. **Check the stack trace** - Which provider?
2. **Find the method** - Which method is being called?
3. **Look for await** - Is there an await without a check after it?
4. **Add more checks** - You can't have too many mounted checks!

**Example of missing check:**

```dart
Future<void> method() async {
  await operation1();
  // ❌ Missing check here!
  final data = await operation2(); // Uses disposed state
}

// Fix:
Future<void> method() async {
  await operation1();
  if (!mounted) return; // ✅ Added
  final data = await operation2();
}
```

---

**Let's fix these systematically! 🚀**

**Start with user_profile_provider.dart - it's the most critical!**
