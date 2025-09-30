# Migration Notes & Blockers

## Files with Complex Dependencies

### week_tasks.dart - BLOCKED

**Status**: Partially migrated, has compilation errors  
**Blocker**: Missing provider properties and methods

**Required Provider Enhancements:**

1. **SubjectsProvider** needs:

   - `instructorsBySubject` property
   - Logic to map instructors by subject ID

2. **AdministrationProvider** needs:

   - `sections` property
   - Section filtering logic

3. **TasksProvider** needs:

   - `toggleTaskCompletion(taskId)` method
   - `deleteTask(taskId)` method

4. **UserProfileProvider** needs:
   - `updateAssistantPreferences()` method

**Action Plan:**

1. First migrate simpler files that don't depend on these properties
2. Then enhance the providers with missing functionality
3. Return to complete week_tasks.dart migration

---

## Migration Order (Revised)

### Priority 1: Simple Files First

1. ✅ login.dart
2. ✅ signup_page2.dart
3. ⏸️ week_tasks.dart (PAUSED - too complex)
4. 🔄 all_tasks.dart (TRY NEXT)
5. 🔄 add_edit_task_dialog.dart (TRY NEXT)

### Priority 2: Enhance Providers

After simpler files are done, enhance providers to support complex features

### Priority 3: Return to Complex Files

Complete week_tasks.dart and other complex files

---

## Technical Debt

- Old providers in `/lib/providers/` have more features than new ones in `/lib/features/*/providers/`
- Need to port missing functionality to new providers
- Some screens might need refactoring to work with new architecture

---

**Date**: September 30, 2025
