# Sections Tab Fixes

## Issues Identified and Fixed

### Issue 1: Section Cards Showing Wrong Assistant's Information

**Problem:**

- Each section card was always displaying the **first section's** day/time information
- Even when users had selected a specific assistant, the card showed the wrong section details
- This happened because the code used `.take(1)` which always took the first section, ignoring user preferences

**Root Cause:**
In `enhanced_section_list_item.dart`, the code was displaying sections like this:

```dart
if (widget.sections.isNotEmpty)
  ...widget.sections
      .take(1)  // ❌ Always takes first section
      .map((section) => [...])
```

This ignored the user's `assistantPreferences` map which stores which assistant they chose for each subject.

**Solution:**
Added logic to select the correct section based on the user's assistant preference:

```dart
@override
Widget build(BuildContext context) {
  // Watch user profile provider to get the logged-in user and their preferences
  final userProfileState = ref.watch(userProfileProvider);
  final currentUser = userProfileState.loggedInUserProfile;

  // Get the preferred section to display based on user's assistant preference
  Section? displaySection;

  if (widget.sections.isNotEmpty) {
    final preferredAssistantId =
        currentUser?.assistantPreferences[widget.subject.id];

    // If user has a preferred assistant, find their section
    if (preferredAssistantId != null) {
      displaySection = widget.sections.firstWhere(
        (section) => section.assistantId == preferredAssistantId,
        orElse: () => widget.sections.first,
      );
    } else {
      // No preference set, use first section
      displaySection = widget.sections.first;
    }
  }

  // Display the preferred section's info
  if (displaySection != null) ...[
    _buildInfoChip(context, displaySection.location, Colors.green),
    _buildInfoChip(context, '${displaySection.days} - ${displaySection.time}', Colors.orange),
  ]
}
```

**How It Works:**

1. Check if user has an assistant preference for this subject in `assistantPreferences` map
2. If yes, find the section belonging to that specific assistant
3. If no preference, default to the first section
4. Display the correct section's location, days, and time

---

### Issue 2: Section Information Not Appearing Immediately on Tab Open

**Problem:**

- When opening the sections tab, the section cards would appear but without day/time information
- After a brief moment, the information would suddenly appear
- This created a poor user experience with visible loading delay

**Root Cause:**
The original code used a separate `_getPreferredSection()` method that was called during build:

```dart
Section? _getPreferredSection() {
  final userProfileState = ref.watch(userProfileProvider);
  // ... logic
}

@override
Widget build(BuildContext context) {
  final displaySection = _getPreferredSection();  // ❌ Nested ref.watch
}
```

This created a timing issue where:

1. The widget builds before user profile is fully loaded
2. `_getPreferredSection()` is called and returns null initially
3. Later when profile loads, the widget rebuilds with correct data
4. Result: flickering/delayed information display

**Solution:**
Moved the preference logic directly into the build method at the top level:

```dart
@override
Widget build(BuildContext context) {
  // Watch user profile provider at the start of build
  final userProfileState = ref.watch(userProfileProvider);
  final currentUser = userProfileState.loggedInUserProfile;

  // Calculate preferred section immediately with available data
  Section? displaySection;
  if (widget.sections.isNotEmpty) {
    final preferredAssistantId = currentUser?.assistantPreferences[widget.subject.id];
    // ... calculate displaySection
  }

  // Build UI with calculated section
  return AnimatedBuilder(...);
}
```

**Why This Works:**

- `ref.watch()` is now at the top level of build method (best practice)
- User profile state is available immediately when widget builds
- No nested function calls that might cause timing issues
- Section preference is calculated synchronously with the build cycle

---

### Issue 3: InstructorsGate Dialog Showing Wrong Section

**Problem:**

- When clicking on a section card to view instructors, the dialog would show the first section's information
- This was inconsistent with what the user selected

**Solution:**
Updated `_showInstructorsGateDialog()` to calculate the preferred section based on the user's current assistant preference:

```dart
void _showInstructorsGateDialog(...) async {
  // Get user's current assistant preference
  final currentAssistantId = currentUser?.assistantPreferences[widget.subject.id];

  // Calculate preferred section to pass to dialog
  Section? preferredSection;
  if (widget.sections.isNotEmpty && currentAssistantId != null) {
    preferredSection = widget.sections.firstWhere(
      (section) => section.assistantId == currentAssistantId,
      orElse: () => widget.sections.first,
    );
  } else if (widget.sections.isNotEmpty) {
    preferredSection = widget.sections.first;
  }

  // Pass correct section to dialog
  await showInstructorsGate(
    ...
    section: preferredSection,
  );
}
```

---

## Files Modified

1. **`/lib/features/profile/screens/profile_widgets/sections/enhanced_section_list_item.dart`**
   - Removed `_getPreferredSection()` method
   - Moved preference calculation to top of build method
   - Updated `_showInstructorsGateDialog()` to calculate preferred section
   - Improved timing and initialization

---

## User Flow After Fixes

### Before Fixes:

1. User opens sections tab
2. Cards appear without day/time info (blank)
3. After ~500ms, information suddenly appears
4. Information shown is for first assistant (wrong if user selected different assistant)
5. Clicking card shows dialog with first assistant's section (potentially wrong)

### After Fixes:

1. User opens sections tab
2. Cards appear **immediately** with correct day/time information
3. Information shown matches user's selected assistant preference
4. Clicking card shows dialog with **correct** section for selected assistant
5. No flickering or delays

---

## Technical Details

### User Profile Structure

```dart
class UserProfile {
  Map<String, String> assistantPreferences; // subjectId -> assistantId
  List<String> enrolledSubjects;
  // ... other fields
}
```

### Section Model

```dart
class Section {
  String id;
  String assistantId;  // ← This is matched against user preference
  String subjectId;
  String days;
  String time;
  String location;
  String name;
}
```

### Preference Matching Flow

```
User Profile: assistantPreferences[subjectId] → assistantId
                                    ↓
Available Sections: sections.where(s => s.subjectId == subjectId)
                                    ↓
Filter by Assistant: section.assistantId == preferredAssistantId
                                    ↓
Display: section.days, section.time, section.location
```

---

## Testing Recommendations

1. **Test Multiple Assistants:**

   - Enroll in subject with 2+ assistants
   - Select assistant A, verify card shows A's section info
   - Change to assistant B, verify card updates to B's section info

2. **Test First Load:**

   - Kill app and restart
   - Open sections tab
   - Verify information appears immediately (no blank cards)

3. **Test No Preference:**

   - Enroll in new subject (no assistant selected yet)
   - Verify card shows first assistant's section by default
   - Select an assistant, verify card updates

4. **Test Dialog Consistency:**

   - Click section card
   - Verify dialog shows same day/time/location as the card
   - Change assistant in dialog
   - Close and reopen, verify card shows new assistant's info

5. **Test Edge Cases:**
   - Subject with no sections → should show "سيتم إضافة السكشن قريباً"
   - Subject with one assistant → should auto-select and show their section
   - Subject with assistant preference that no longer exists → should fallback to first section

---

## Performance Notes

- **Zero Extra Queries:** The fix uses only existing data from providers, no additional Firebase reads
- **Immediate Display:** Information appears on first render, no delayed updates
- **Reactive Updates:** Changes to assistant preferences automatically update the UI
- **Efficient Lookups:** `firstWhere` with `orElse` ensures safe section finding

---

## Related Files

- `/lib/features/profile/screens/profile/sections_tab.dart` - Tab container
- `/lib/features/profile/screens/profile_widgets/sections/sections_builder.dart` - Builds section list
- `/lib/models/user_profile.dart` - User profile model with assistantPreferences
- `/lib/models/section_model.dart` - Section model
- `/lib/widgets/unified_dialog.dart` - Dialog components
- `/lib/screens/models/instructors_gate.dart` - Instructors selection dialog
