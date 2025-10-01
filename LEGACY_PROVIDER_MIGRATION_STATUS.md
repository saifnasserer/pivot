# Legacy Provider Migration Status

**Date**: October 1, 2025
**Status**: 🟡 75% Complete

---

## ✅ Completed Tasks

1. **All legacy provider files DELETED** ✅

   - announcement_provider.dart ✅
   - bookmarks.dart ✅
   - doctor_subject_provider.dart ✅
   - material_links_provider.dart ✅
   - schadule_provider.dart ✅
   - section_provider.dart ✅
   - settings_provider.dart ✅
   - super_admin_provider.dart ✅
   - task_provider.dart ✅
   - team_provider.dart ✅
   - teams_provider.dart ✅
   - user_profile_provider.dart ✅

2. **Migrated Utility Classes** ✅

   - assistant_profile_controller.dart - Converted to use WidgetRef
   - sections.dart - Converted to use WidgetRef

3. **All imports updated** ✅
   - No files importing from `lib/providers/`
   - All imports point to Riverpod versions in `lib/features/`

---

## 🟡 Remaining Work

### Files Still Using Old Provider.of Pattern

These 12 files need to be converted to use Riverpod:

1. **lib/features/profile/screens/profile_widgets/sections.dart** - ⚠️ PARTIALLY MIGRATED

   - Main class migrated to Riverpod
   - Need to update call sites

2. **lib/features/administration/screens/assistants/profile/assistant_profile_controller.dart** - ⚠️ PARTIALLY MIGRATED

   - Migrated to accept WidgetRef
   - Need to update call sites

3. **lib/features/profile/screens/profile/quick_actions_section.dart** (1 match)

   - Convert to ConsumerWidget or ConsumerStatefulWidget

4. **lib/screens/models/material_links_widget.dart** (2 matches)

   - Convert to use Riverpod providers

5. **lib/screens/models/instructors_gate.dart** (2 matches)

   - Convert to use Riverpod providers

6. **lib/services/data_deletion_service.dart** (2 matches)

   - Convert service to accept WidgetRef parameter

7. **lib/widgets/comment_section.dart** (9 matches)

   - Convert to ConsumerWidget

8. **lib/features/home/screens/adminstration/announcement/add_announcement_main.dart** (1 match)

   - Convert to use Riverpod providers

9. **lib/features/teams/screens/team_members_screen.dart** (4 matches)

   - Convert to ConsumerWidget

10. **lib/features/teams/screens/team_formation_screen.dart** (4 matches)

    - Convert to ConsumerWidget

11. **lib/features/teams/screens/teams.dart** (2 matches)

    - Convert to ConsumerWidget

12. **lib/features/media/screens/material_links_screen.dart** (9 matches)

    - Convert to ConsumerWidget

13. **lib/features/profile/screens/feedback_screen** (1 match)
    - Convert to use Riverpod providers

---

## 📋 Next Steps

### Phase 1: Quick Fixes (Low-Hanging Fruit)

1. **data_deletion_service.dart** - Service class, easy to convert
2. **quick_actions_section.dart** - Single usage, straightforward
3. **feedback_screen** - Single usage

### Phase 2: Widget Conversions

4. **material_links_widget.dart** - Widget conversion
5. **instructors_gate.dart** - Widget conversion
6. **add_announcement_main.dart** - Screen conversion

### Phase 3: Complex Widgets

7. **comment_section.dart** - 9 usages, needs careful migration
8. **material_links_screen.dart** - 9 usages, complex screen
9. **team_members_screen.dart** - Team feature
10. **team_formation_screen.dart** - Team feature
11. **teams.dart** - Team feature

### Phase 4: Update Call Sites

12. Update all call sites for migrated utility classes:
    - SectionsBuilder.buildSectionsSlivers (now requires WidgetRef)
    - AssistantProfileController methods (now require WidgetRef)

### Phase 5: Cleanup

13. Remove `provider: ^6.1.4` from pubspec.yaml
14. Run `flutter pub get`
15. Test all features
16. Delete `lib/providers/` folder

---

## Migration Pattern

### For Widgets:

```dart
// OLD
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyProvider>(context);
    return Text(provider.data);
  }
}

// NEW
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    return Text(state.data);
  }
}
```

### For Utility Classes:

```dart
// OLD
static void myMethod(BuildContext context) {
  final provider = Provider.of<MyProvider>(context, listen: false);
  provider.doSomething();
}

// NEW
static void myMethod(WidgetRef ref, BuildContext context) {
  ref.read(myProvider.notifier).doSomething();
}
```

---

## Testing Checklist

After migration, test:

- [ ] All screens load correctly
- [ ] No ProviderNotFoundException errors
- [ ] Hot restart works
- [ ] State updates properly
- [ ] Navigation works
- [ ] Forms submit correctly

---

## Success Criteria

✅ Migration complete when:

1. All 12 files converted to Riverpod
2. No `Provider.of<>` usage in codebase
3. No imports from `package:provider/provider.dart`
4. `provider` package removed from pubspec.yaml
5. `lib/providers/` folder deleted
6. App runs without errors
7. All features working
