# Riverpod Migration Plan

## 📋 Overview

This document tracks the migration from legacy `provider` package to `flutter_riverpod` across all features.

**Status**: 🔄 In Progress  
**Last Updated**: September 30, 2025  
**Files Using Legacy Provider**: 46 files  
**Provider Usages**: 87 instances

---

## 🎯 Migration Strategy

### Phase 1: Core Infrastructure ✅ (COMPLETED)

- [x] Auth Provider (Riverpod) - `lib/features/auth/providers/auth_provider.dart`
- [x] User Profile Provider (Riverpod) - `lib/features/user/providers/user_profile_provider.dart`
- [x] Login Screen - Migrated to Riverpod
- [x] Signup Screen - Migrated to Riverpod

### Phase 2: Critical Features (Priority 1)

**Target**: Week 1

#### 2.1 Tasks Feature 🔴 HIGH PRIORITY

- [ ] **File**: `lib/features/tasks/screens/week_tasks.dart`
  - Uses: `Provider.of<TaskProvider>`, `Provider.of<UserProfileProvider>`
  - Action: Replace with `ref.watch(tasksProvider)`, `ref.watch(userProfileProvider)`
  - New Provider: `lib/features/tasks/providers/tasks_provider.dart` ✅ EXISTS
- [ ] **File**: `lib/features/tasks/screens/all_tasks.dart`
  - Uses: `Provider.of<TaskProvider>`, `Provider.of<UserProfileProvider>`
  - Action: Replace with Riverpod equivalents
- [ ] **File**: `lib/features/tasks/screens/add_edit_task_dialog.dart`
  - Uses: `Provider.of<UserProfileProvider>`, `Provider.of<TaskProvider>`
  - Action: Replace with Riverpod equivalents

**Legacy Provider to Remove**: `lib/providers/task_provider.dart`

#### 2.2 Schedule Feature 🔴 HIGH PRIORITY

- [ ] **File**: `lib/features/schedule/screens/add_edit_schedule_dialog.dart`
  - Uses: `Provider.of<UserProfileProvider>`, schedule provider
  - Action: Replace with `ref.watch(scheduleProvider)`
  - New Provider: `lib/features/schedule/providers/schedule_provider.dart` ✅ EXISTS

**Legacy Provider to Remove**: `lib/providers/schadule_provider.dart`

#### 2.3 Profile Feature 🔴 HIGH PRIORITY

- [ ] **File**: `lib/features/profile/screens/profile/profile_screen.dart`
  - Uses: `Provider.of<UserProfileProvider>`
  - Action: Replace with `ref.watch(userProfileProvider)`
- [ ] **File**: `lib/features/profile/screens/profile/profile_details_tab.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/profile/screens/profile/subjects_tab.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/profile/screens/profile/sections_tab.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/profile/screens/profile/schedule_tab.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/profile/screens/profile/quick_actions_section.dart`

  - Uses: Legacy provider
  - Action: Migrate to Riverpod

- [ ] **File**: `lib/features/profile/screens/profile_widgets/Profile_options.dart`
  - Uses: `Provider.of<UserProfileProvider>`
  - Action: Replace with Riverpod
- [ ] **File**: `lib/features/profile/screens/profile_widgets/sections.dart`
  - Uses: Multiple legacy providers
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/profile/screens/profile_widgets/sections/sections_builder.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/profile/screens/profile_widgets/sections/enhanced_section_list_item.dart`

  - Uses: Legacy provider
  - Action: Migrate to Riverpod

- [ ] **File**: `lib/features/profile/screens/edit_profile/edit_profile.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/profile/screens/edit_profile/edit_profile_screen.dart`

  - Uses: Legacy provider
  - Action: Migrate to Riverpod

- [ ] **File**: `lib/features/profile/screens/feedback_screen.dart`
  - Uses: `Provider.of<UserProfileProvider>`
  - Action: Replace with Riverpod

**New Provider**: `lib/features/profile/providers/profile_provider.dart` ✅ EXISTS

---

### Phase 3: Home & Administration (Priority 2)

**Target**: Week 2

#### 3.1 Home Feature 🟡 MEDIUM PRIORITY

- [ ] **File**: `lib/features/home/screens/admin_control.dart`

  - Uses: Multiple legacy providers
  - Action: Migrate to Riverpod
  - New Provider: `lib/features/home/providers/home_provider.dart` ✅ EXISTS

- [ ] **File**: `lib/features/home/screens/landing_categories.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod

#### 3.2 Administration Feature 🟡 MEDIUM PRIORITY

- [ ] **File**: `lib/features/administration/screens/assistants/profile/assistant_profile_main.dart`
  - Uses: `Provider.of<UserProfileProvider>`
  - Action: Replace with Riverpod
- [ ] **File**: `lib/features/administration/screens/assistants/profile/assistant_profile_main_new.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/administration/screens/assistants/profile/assistant_profile_controller.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/administration/screens/assistants/add_edit_section_dialog.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/administration/screens/assistants/profile/assistant_subjects_section.dart`

  - Uses: Legacy provider
  - Action: Migrate to Riverpod

- [ ] **File**: `lib/features/administration/screens/doctor/profile/doctor_profile.dart`
  - Uses: Multiple legacy providers
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/administration/screens/doctor/profile/about_me_widget.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/administration/screens/doctor/profile/contact_info_widget.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/administration/screens/doctor/profile/social_media_widget.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/administration/screens/doctor/profile/subjects_section.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/administration/screens/doctor/edit_about_screen.dart`

  - Uses: Legacy provider
  - Action: Migrate to Riverpod

- [ ] **File**: `lib/features/home/screens/adminstration/user_management_page.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/home/screens/adminstration/add_user_screen.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/home/screens/adminstration/section_management_screen.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/home/screens/adminstration/global_subject_management_screen.dart`
  - Uses: Multiple legacy providers
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/home/screens/adminstration/announcement/add_announcement_main.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/home/screens/adminstration/add_announcement_stepped_dialog.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/home/screens/adminstration/announcement_list_widget.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/home/screens/adminstration/show_dialog.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod

**New Providers**:

- `lib/features/administration/providers/administration_provider.dart` ✅ EXISTS
- `lib/features/administration/providers/analytics_provider.dart` ✅ EXISTS
- `lib/features/administration/providers/super_admin_provider.dart` ✅ EXISTS

**Legacy Providers to Remove**:

- `lib/providers/super_admin_provider.dart`
- `lib/providers/section_provider.dart`
- `lib/providers/doctor_subject_provider.dart`

---

### Phase 4: Secondary Features (Priority 3)

**Target**: Week 3

#### 4.1 Teams Feature 🟢 LOW PRIORITY

- [ ] **File**: `lib/features/teams/screens/teams.dart`
  - Uses: Legacy provider
  - Action: Migrate to `ref.watch(teamsProvider)`
- [ ] **File**: `lib/features/teams/screens/team_formation_screen.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/teams/screens/team_members_screen.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod

**New Provider**: `lib/features/teams/providers/teams_provider.dart` ✅ EXISTS  
**Legacy Providers to Remove**: `lib/providers/team_provider.dart`, `lib/providers/teams_provider.dart`

#### 4.2 Subjects Feature 🟢 LOW PRIORITY

- [ ] **File**: `lib/features/subjects/screens/subject_selection_screen.dart`
  - Uses: Multiple legacy providers
  - Action: Migrate to Riverpod

**New Provider**: `lib/features/subjects/providers/subjects_provider.dart` ✅ EXISTS  
**Legacy Provider to Remove**: `lib/providers/subject_provider.dart`

#### 4.3 Media/Bookmarks Features 🟢 LOW PRIORITY

- [ ] **File**: `lib/features/media/screens/material_links_screen.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod
- [ ] **File**: `lib/features/bookmarks/screens/bookmarks_screen.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod

**New Providers**:

- `lib/features/media/providers/media_provider.dart` ✅ EXISTS
- `lib/features/media/providers/materials_provider.dart` ✅ EXISTS
- `lib/features/bookmarks/providers/bookmarks_provider.dart` ✅ EXISTS

**Legacy Provider to Remove**: `lib/providers/material_links_provider.dart`

#### 4.4 Other Screens 🟢 LOW PRIORITY

- [ ] **File**: `lib/features/onboarding/screens/first_landing.dart`
  - Uses: Legacy provider
  - Action: Migrate to Riverpod

---

## 🔧 Migration Steps (Per File)

### Standard Migration Pattern

1. **Update Imports**

   ```dart
   // Remove:
   import 'package:provider/provider.dart';
   import 'package:pivot/providers/old_provider.dart';

   // Add:
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:pivot/features/*/providers/new_provider.dart';
   ```

2. **Update Widget Type**

   ```dart
   // From:
   class MyWidget extends StatelessWidget

   // To:
   class MyWidget extends ConsumerWidget

   // OR from:
   class MyWidget extends StatefulWidget

   // To:
   class MyWidget extends ConsumerStatefulWidget
   ```

3. **Update build Method**

   ```dart
   // From:
   @override
   Widget build(BuildContext context) {
     final provider = Provider.of<MyProvider>(context);

   // To:
   @override
   Widget build(BuildContext context, WidgetRef ref) {
     final providerState = ref.watch(myProvider);
   ```

4. **Update Provider Calls**

   ```dart
   // From:
   Provider.of<MyProvider>(context, listen: false).method()

   // To:
   ref.read(myProvider.notifier).method()

   // From:
   context.read<MyProvider>().method()

   // To:
   ref.read(myProvider.notifier).method()
   ```

5. **Test & Verify**
   - [ ] Hot reload works
   - [ ] No runtime errors
   - [ ] State management works correctly
   - [ ] Navigation works
   - [ ] Data persistence works

---

## 🗑️ Cleanup Phase (Final Week)

### Legacy Providers to Delete

Once all migrations are complete, remove these files:

- [ ] `lib/providers/task_provider.dart`
- [ ] `lib/providers/schadule_provider.dart`
- [ ] `lib/providers/user_profile_provider.dart`
- [ ] `lib/providers/announcement_provider.dart`
- [ ] `lib/providers/settings_provider.dart`
- [ ] `lib/providers/guide_provider.dart`
- [ ] `lib/providers/team_provider.dart`
- [ ] `lib/providers/teams_provider.dart`
- [ ] `lib/providers/super_admin_provider.dart`
- [ ] `lib/providers/subject_provider.dart`
- [ ] `lib/providers/section_provider.dart`
- [ ] `lib/providers/material_links_provider.dart`
- [ ] `lib/providers/doctor_subject_provider.dart`

### Remove Legacy Package

- [ ] Remove `provider: ^6.x.x` from `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Search for any remaining imports: `grep -r "package:provider" lib/`
- [ ] Remove any `MultiProvider` or `ChangeNotifierProvider` wrappers

---

## 📊 Progress Tracker

| Feature        | Files  | Status        | Priority |
| -------------- | ------ | ------------- | -------- |
| Auth           | 2      | ✅ Complete   | P0       |
| Tasks          | 3      | 🔄 Pending    | P1       |
| Schedule       | 1      | 🔄 Pending    | P1       |
| Profile        | 13     | 🔄 Pending    | P1       |
| Home           | 2      | 🔄 Pending    | P2       |
| Administration | 17     | 🔄 Pending    | P2       |
| Teams          | 3      | 🔄 Pending    | P3       |
| Subjects       | 1      | 🔄 Pending    | P3       |
| Media          | 1      | 🔄 Pending    | P3       |
| Bookmarks      | 1      | 🔄 Pending    | P3       |
| Onboarding     | 1      | 🔄 Pending    | P3       |
| **TOTAL**      | **45** | **2/47 (4%)** |          |

---

## 🚨 Common Pitfalls & Solutions

### Issue 1: ProviderNotFoundException

**Problem**: `Error: Could not find the correct Provider<X>`  
**Solution**: Ensure you're using Riverpod provider, not legacy Provider

### Issue 2: Context Not Available in Callbacks

**Problem**: Need to call provider in async callback  
**Solution**: Use `ref.read()` instead of `ref.watch()` in callbacks

### Issue 3: Disposing Resources

**Problem**: Need to dispose controllers/listeners  
**Solution**: Use `ref.onDispose()` in provider initialization

### Issue 4: Hot Reload Issues

**Problem**: Riverpod state not updating on hot reload  
**Solution**: Perform hot restart instead of hot reload

---

## ✅ Testing Checklist

After each file migration:

- [ ] File compiles without errors
- [ ] No lint warnings related to providers
- [ ] Hot reload works
- [ ] Screen loads correctly
- [ ] All user interactions work
- [ ] State persists correctly
- [ ] Navigation works
- [ ] No console errors
- [ ] Memory leaks checked (using DevTools)

---

## 📝 Notes

- Always test on a separate branch
- Commit after each successful file migration
- Update this document as you progress
- Mark items as complete with the date completed
- Document any custom solutions or edge cases encountered

---

## 🎓 Resources

- [Riverpod Documentation](https://riverpod.dev/)
- [Migration Guide from Provider to Riverpod](https://riverpod.dev/docs/from_provider/motivation)
- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/reading)

---

**Last Updated**: September 30, 2025  
**Maintained By**: Development Team
