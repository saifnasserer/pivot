# Legacy Provider Cleanup & Riverpod Migration Plan

**Goal**: Eliminate all legacy `ChangeNotifier` providers and migrate completely to Riverpod `StateNotifier` providers.

**Status**: 🟡 In Progress

---

## Current State Analysis

### ✅ Already Migrated to Riverpod (Features Folder)

These providers are already using Riverpod StateNotifier and are ready:

1. ✅ `lib/features/auth/providers/auth_provider.dart` - AuthProvider (Riverpod)
2. ✅ `lib/features/user/providers/user_profile_provider.dart` - UserProfileProvider (Riverpod)
3. ✅ `lib/features/announcements/providers/announcements_provider.dart` - AnnouncementsProvider (Riverpod)
4. ✅ `lib/features/settings/providers/settings_provider.dart` - SettingsProvider (Riverpod)
5. ✅ `lib/features/subjects/providers/subjects_provider.dart` - SubjectsProvider (Riverpod)
6. ✅ `lib/features/administration/providers/sections_provider.dart` - SectionsProvider (Riverpod)
7. ✅ `lib/features/tasks/providers/tasks_provider.dart` - TasksProvider (Riverpod)
8. ✅ `lib/features/schedule/providers/schedule_provider.dart` - ScheduleProvider (Riverpod)
9. ✅ `lib/features/teams/providers/teams_provider.dart` - TeamsProvider (Riverpod)
10. ✅ `lib/features/bookmarks/providers/bookmarks_provider.dart` - BookmarksProvider (Riverpod)
11. ✅ `lib/features/guide/providers/guide_provider.dart` - GuideProvider (Riverpod) - **Just migrated**
12. ✅ `lib/features/subjects/providers/legacy_subject_provider.dart` - LegacySubjectProvider (Riverpod) - **Just migrated**
13. ✅ `lib/features/administration/providers/super_admin_provider.dart` - SuperAdminProvider (Riverpod)
14. ✅ `lib/features/notifications/providers/notifications_provider.dart` - NotificationsProvider (Riverpod)
15. ✅ `lib/features/media/providers/media_provider.dart` - MediaProvider (Riverpod)
16. ✅ `lib/features/media/providers/materials_provider.dart` - MaterialsProvider (Riverpod)

### 🔴 Legacy Providers Still Using ChangeNotifier (lib/providers/)

These providers use the old `Provider` package and need migration:

1. 🔴 `lib/providers/schadule_provider.dart` - ScheduleProvider (ChangeNotifier)

   - **Has Riverpod version**: `lib/features/schedule/providers/schedule_provider.dart`
   - **Action**: Delete legacy, update imports

2. 🔴 `lib/providers/user_profile_provider.dart` - UserProfileProvider (ChangeNotifier)

   - **Has Riverpod version**: `lib/features/user/providers/user_profile_provider.dart`
   - **Action**: Delete legacy, update imports

3. 🔴 `lib/providers/announcement_provider.dart` - AnnouncementProvider (ChangeNotifier)

   - **Has Riverpod version**: `lib/features/announcements/providers/announcements_provider.dart`
   - **Action**: Delete legacy, update imports

4. 🔴 `lib/providers/settings_provider.dart` - SettingsProvider (ChangeNotifier)

   - **Has Riverpod version**: `lib/features/settings/providers/settings_provider.dart`
   - **Action**: Delete legacy, update imports

5. 🔴 `lib/providers/task_provider.dart` - TaskProvider (ChangeNotifier)

   - **Has Riverpod version**: `lib/features/tasks/providers/tasks_provider.dart`
   - **Action**: Delete legacy, update imports

6. 🔴 `lib/providers/section_provider.dart` - SectionProvider (ChangeNotifier)

   - **Has Riverpod version**: `lib/features/administration/providers/sections_provider.dart`
   - **Action**: Delete legacy, update imports

7. 🔴 `lib/providers/team_provider.dart` - TeamProvider (ChangeNotifier)

   - **Has Riverpod version**: `lib/features/teams/providers/teams_provider.dart`
   - **Action**: Delete legacy, update imports

8. 🔴 `lib/providers/teams_provider.dart` - TeamsProvider (ChangeNotifier)

   - **Has Riverpod version**: `lib/features/teams/providers/teams_provider.dart`
   - **Action**: Delete legacy, update imports (may be duplicate)

9. 🔴 `lib/providers/super_admin_provider.dart` - SuperAdminProvider (ChangeNotifier)

   - **Has Riverpod version**: `lib/features/administration/providers/super_admin_provider.dart`
   - **Action**: Delete legacy, update imports

10. 🔴 `lib/providers/bookmarks.dart` - Bookmarks (ChangeNotifier)

    - **Has Riverpod version**: `lib/features/bookmarks/providers/bookmarks_provider.dart`
    - **Action**: Delete legacy, update imports

11. 🔴 `lib/providers/doctor_subject_provider.dart` - DoctorSubjectProvider (ChangeNotifier)

    - **Check if Riverpod version exists**: Need to verify
    - **Action**: Create Riverpod version if needed, or delete if unused

12. 🔴 `lib/providers/material_links_provider.dart` - MaterialLinksProvider (ChangeNotifier)
    - **Has Riverpod version**: `lib/features/media/providers/materials_provider.dart`
    - **Action**: Delete legacy, update imports

---

## Migration Strategy

### Phase 1: Verify & Map (✅ COMPLETE)

- [x] Identify all legacy providers
- [x] Map each legacy provider to its Riverpod equivalent
- [x] Identify providers without Riverpod versions

### Phase 2: Low-Risk Migrations (🟡 IN PROGRESS)

Migrate providers that are least used and have clear Riverpod equivalents.

#### Priority Order:

1. **bookmarks.dart** → `bookmarks_provider.dart`

   - Already migrated in `card_model.dart` and `bookmarks_screen.dart`
   - Just need to update remaining references and delete

2. **settings_provider.dart** → Already migrated

   - Update remaining old imports
   - Delete legacy file

3. **super_admin_provider.dart** → Already migrated

   - Update remaining old imports
   - Delete legacy file

4. **team_provider.dart** & **teams_provider.dart** → Consolidate to one Riverpod version

   - These might be duplicates
   - Verify and merge

5. **material_links_provider.dart** → `materials_provider.dart`
   - Update imports
   - Delete legacy file

### Phase 3: Medium-Risk Migrations

Providers with moderate usage that need careful migration.

6. **doctor_subject_provider.dart**

   - Check if Riverpod version exists or create one
   - Migrate usage
   - Delete legacy

7. **section_provider.dart** → `sections_provider.dart`

   - Already have Riverpod version
   - Update all references (many in assistant/doctor profiles)
   - Delete legacy file

8. **announcement_provider.dart** → `announcements_provider.dart`
   - Already have Riverpod version
   - Update all references
   - Delete legacy file

### Phase 4: High-Risk Migrations

Core providers that are heavily used - need careful migration.

9. **task_provider.dart** → `tasks_provider.dart`

   - Core functionality for tasks
   - Update all references
   - Thorough testing needed
   - Delete legacy file

10. **schadule_provider.dart** → `schedule_provider.dart`

    - Core functionality for schedules
    - Already have Riverpod version
    - Update all references
    - Delete legacy file

11. **user_profile_provider.dart** → Riverpod version
    - Most critical provider
    - Already have Riverpod version in features/
    - Update all old Provider.of<UserProfileProvider> references
    - Last to delete

---

## Detailed Migration Steps for Each Provider

### Template for Each Migration:

````markdown
## Provider Name: [Provider]

**Status**: 🔴 Not Started | 🟡 In Progress | ✅ Complete

**Legacy Path**: `lib/providers/[file].dart`
**Riverpod Path**: `lib/features/[feature]/providers/[file].dart`

### Step 1: Find All Usages

```bash
grep -r "import.*providers/[file]" lib/
grep -r "Provider.of<[Provider]>" lib/
grep -r "context.read<[Provider]>" lib/
grep -r "context.watch<[Provider]>" lib/
```
````

### Step 2: Update Imports

- Replace old import with new Riverpod import
- Files affected: [list files]

### Step 3: Update Usage Patterns

- Old: `Provider.of<[Provider]>(context)`
- New: `ref.read/watch([provider]Provider)`
- Convert widgets to ConsumerWidget/ConsumerStatefulWidget if needed

### Step 4: Test

- Run app
- Test all features using this provider
- Check for errors

### Step 5: Delete Legacy File

- Only after all tests pass
- Delete `lib/providers/[file].dart`

### Files to Update:

- [ ] File 1
- [ ] File 2

````

---

## Migration Execution Plan

### Week 1: Low-Risk Providers (Priority 1-5)
- Day 1: Bookmarks migration
- Day 2: Settings & SuperAdmin migration
- Day 3: Teams consolidation
- Day 4: MaterialLinks migration
- Day 5: Testing & verification

### Week 2: Medium-Risk Providers (Priority 6-8)
- Day 1: DoctorSubject migration
- Day 2: Section provider migration
- Day 3: Announcement provider migration
- Day 4: Testing & verification
- Day 5: Bug fixes

### Week 3: High-Risk Providers (Priority 9-11)
- Day 1-2: Task provider migration (critical)
- Day 3-4: Schedule provider migration (critical)
- Day 5: Testing

### Week 4: Final Migration & Cleanup
- Day 1-2: UserProfile provider migration (most critical)
- Day 3: Final testing
- Day 4: Delete all legacy providers
- Day 5: Clean up any remaining references

---

## Safety Rules

### Before Deleting ANY Legacy Provider:
1. ✅ All imports updated to Riverpod version
2. ✅ All `Provider.of<>` replaced with `ref.read/watch`
3. ✅ All widgets converted to Consumer variants if needed
4. ✅ No linter errors
5. ✅ App runs without ProviderNotFoundException
6. ✅ Feature tested and working
7. ✅ Hot restart successful
8. ✅ No console errors related to the provider

### Rollback Plan:
- Keep git commits for each provider migration
- If issues arise, revert specific commit
- Document any breaking changes

---

## Current Issues to Fix First

### 1. assistant_profile_controller.dart
**Issue**: Still using `Provider.of<SubjectProvider>` and old Provider package
**Fix**: This file seems to be a utility/controller file. Options:
  - Convert to accept WidgetRef as parameter
  - Or migrate to Riverpod fully
  - Or delete if unused

**Files affected**: 1 file (only imported by itself)

### 2. Import Path Conflicts
Some files may import both old and new paths. Need to ensure consistency.

---

## Quick Wins (Do First)

### 1. Delete Already-Migrated Duplicates
Files where Riverpod version exists and is already in use:
- ✅ `lib/providers/guide_provider.dart` - **DELETED**
- ✅ `lib/providers/subject_provider.dart` - **DELETED**

### 2. Update Import Statements (Batch Operation)
Use find-and-replace across codebase:
```dart
// Old
import 'package:pivot/providers/bookmarks.dart';
// New
import 'package:pivot/features/bookmarks/providers/bookmarks_provider.dart';
````

### 3. Remove Provider Package Dependency

After all migrations:

- Remove `provider: ^6.0.0` from pubspec.yaml
- Run `flutter pub get`
- Verify no code uses `package:provider/provider.dart`

---

## Testing Checklist

After each provider migration, test:

- [ ] Login flow
- [ ] User profile loading
- [ ] Subject selection
- [ ] Schedule management
- [ ] Task management
- [ ] Announcements
- [ ] Admin controls
- [ ] Settings
- [ ] Bookmarks
- [ ] Teams
- [ ] Navigation between screens

---

## Success Criteria

### Migration Complete When:

1. ✅ No files in `lib/providers/` remain (folder can be deleted)
2. ✅ No imports from `package:provider/provider.dart`
3. ✅ No `Provider.of<>` usage in codebase
4. ✅ No `ChangeNotifier` classes (except in features/ if intentional)
5. ✅ All StateNotifierProviders in `lib/features/[feature]/providers/`
6. ✅ App runs without any ProviderNotFoundException
7. ✅ All features working correctly
8. ✅ No linter errors
9. ✅ `provider` package removed from pubspec.yaml

---

## Next Immediate Actions

### 1. Fix assistant_profile_controller.dart (URGENT)

This file is causing errors and still uses old Provider package.

**Options**:

- **Option A**: Convert to Riverpod utility function that accepts WidgetRef
- **Option B**: Delete if unused (check usage first)
- **Option C**: Inline the logic into the widget that uses it

**Check usage**:

```bash
grep -r "AssistantProfileController" lib/
```

### 2. Start with Bookmarks Migration (EASIEST)

Already 90% migrated, just need to:

- Update any remaining old imports
- Delete `lib/providers/bookmarks.dart`

### 3. Settings Provider (EASY)

Already migrated to `lib/features/settings/providers/settings_provider.dart`

- Find all old imports
- Replace with new
- Delete `lib/providers/settings_provider.dart`

---

## Risk Assessment

### Low Risk ⬇️

- Bookmarks
- Settings
- SuperAdmin
- MaterialLinks
- Teams (if duplicate)

### Medium Risk ⚠️

- Sections
- Announcements
- DoctorSubject
- Tasks

### High Risk ⚠️⚠️⚠️

- Schedule (core feature)
- UserProfile (most critical)

---

## Notes

- Always do **hot restart** after provider changes, not hot reload
- Test on both Android and Web if applicable
- Keep debug logging during migration
- Document any API differences between old and new providers
- Update ARCHITECTURE document after completion

---

## Progress Tracking

### Completed:

- [x] GuideProvider migrated
- [x] SubjectProvider migrated (legacy_subject_provider)
- [x] task_model.dart migrated to Riverpod
- [x] card_model.dart migrated to Riverpod
- [x] bookmarks_screen.dart migrated to Riverpod
- [x] search_card.dart migrated to Riverpod
- [x] landing.dart updated to use ref.watch for reactive updates
- [x] section_card.dart migrated to ConsumerWidget

### In Progress:

- [ ] Fix assistant_profile_controller.dart
- [ ] Clean up remaining old imports

### Pending:

- [ ] All providers in lib/providers/ folder
- [ ] Remove provider package from pubspec.yaml
- [ ] Delete lib/providers/ folder entirely

---

## Estimated Timeline

- **Week 1**: Low-risk migrations (5 providers)
- **Week 2**: Medium-risk migrations (4 providers)
- **Week 3**: High-risk migrations (2 providers)
- **Week 4**: Final cleanup, testing, documentation

**Total**: ~4 weeks for complete migration

---

## Decision: Next Steps

**Immediate Priority (This Week)**:

1. ✅ Fix `assistant_profile_controller.dart` (blocking issue)
2. ✅ Migrate `bookmarks.dart` (easy win)
3. ✅ Migrate `settings_provider.dart` (easy win)
4. ✅ Migrate `super_admin_provider.dart` (easy win)
5. ✅ Test thoroughly
6. ✅ Deploy updated rules if needed

After these 5 are done, we'll have cleared ~40% of legacy providers and can reassess.

---

## API Compatibility Notes

### Key Differences Between Provider and Riverpod:

#### Old Provider:

```dart
class MyProvider with ChangeNotifier {
  String _data = '';
  String get data => _data;

  void updateData(String newData) {
    _data = newData;
    notifyListeners();
  }
}

// Usage
final provider = Provider.of<MyProvider>(context, listen: false);
provider.updateData('new');
```

#### New Riverpod:

```dart
class MyState {
  final String data;
  MyState({this.data = ''});
}

class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState());

  void updateData(String newData) {
    state = MyState(data: newData);
  }
}

final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) => MyNotifier());

// Usage
final myState = ref.watch(myProvider);
ref.read(myProvider.notifier).updateData('new');
```

### Common Migration Patterns:

1. **Reading State**:

   - Old: `provider.data`
   - New: `state.data`

2. **Calling Methods**:

   - Old: `provider.method()`
   - New: `ref.read(provider.notifier).method()`

3. **Listening to Changes**:

   - Old: `Provider.of<T>(context)` or `context.watch<T>()`
   - New: `ref.watch(provider)`

4. **Widget Conversion**:
   - Old: `StatefulWidget` with `Provider.of`
   - New: `ConsumerStatefulWidget` with `ref`
   - Old: `Consumer<T>`
   - New: `Consumer` with `ref.watch(provider)`

---

## End Goal Structure

```
lib/
  features/
    [feature]/
      providers/
        [feature]_provider.dart  # All Riverpod StateNotifiers
  providers/  # ❌ DELETE THIS ENTIRE FOLDER
```

All providers organized by feature, using Riverpod exclusively.

