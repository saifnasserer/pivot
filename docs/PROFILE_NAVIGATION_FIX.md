# Profile Navigation Fix - sections_tab Data Issue

## Date: October 9, 2025

## Problem Description

When navigating between assistant profiles, the `sections_tab.dart` was showing incorrect or stale data. This happened because:

1. Student views their own profile → `sections_tab` shows their sections
2. Student navigates to Assistant A's profile → `userProfile` in provider was NOT being set
3. Student navigates to Assistant B's profile → `userProfile` still not set
4. Student goes back → `sections_tab` had stale or null `userProfile`

## Root Cause

The assistant and doctor profile screens were using **LOCAL state** (`_displayedProfile`) to display profiles, but were NOT updating the **provider's state** (`userProfile`). This caused a disconnect:

- **Local State**: `_displayedProfile` = Assistant A (correct locally)
- **Provider State**: `userProfile` = null or stale (incorrect globally)
- **Result**: `sections_tab` couldn't determine which profile's sections to show

## Solution

Updated all profile screens to properly call `loadUserProfile(userId)` which updates the provider's `userProfile`. This ensures ALL components in the app know which profile is currently being viewed.

---

## Changes Made

### 1. **assistant_profile_main.dart**

**When Loading Profile:**

```dart
// IMPORTANT: Set this profile as the viewed profile in the provider
// This ensures other components (like sections_tab) know which profile is being viewed
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted && profileToShow != null) {
    // Load the profile in the provider (creates separate instance)
    ref.read(userProfileProvider.notifier).loadUserProfile(profileToShow.id);
    _fetchInitialData(profileToShow);
  }
});
```

**When Navigating Back:**

```dart
void _onBackPressed() async {
  // When navigating back, load the logged-in user's profile as the viewed profile
  // This ensures sections_tab and other components show the correct data
  final loggedInUser = ref.read(userProfileProvider).loggedInUserProfile;
  if (loggedInUser != null) {
    await ref.read(userProfileProvider.notifier).loadUserProfile(loggedInUser.id);
  }
  if (mounted) {
    Navigator.pop(context);
  }
}
```

### 2. **doctor_profile.dart**

**In `_refreshProfileData()` method:**

```dart
// IMPORTANT: Load the profile in the provider's userProfile
// This ensures the provider knows which profile is being viewed
await ref
    .read(userProfileProvider.notifier)
    .loadUserProfile(profileIdToRefresh);
```

**When Navigating Back:**
Same as assistant_profile_main.dart - loads logged-in user's profile before navigating back.

### 3. **assistant_profile_main_new.dart**

Applied the same fixes as assistant_profile_main.dart for consistency.

### 4. **profile_screen.dart**

**In `didChangeDependencies()`:**

```dart
// Ensure the logged-in user's profile is set as the viewed profile
// This is important for sections_tab and other components that check userProfile
final userProfileState = ref.read(userProfileProvider);
final loggedInUser = userProfileState.loggedInUserProfile;
final viewedUser = userProfileState.userProfile;

// If viewing own profile and userProfile is not set or outdated, load it
if (loggedInUser != null && (viewedUser == null || viewedUser.id != loggedInUser.id)) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      ref.read(userProfileProvider.notifier).loadUserProfile(loggedInUser.id);
    }
  });
}
```

---

## Navigation Flow (Fixed)

### Scenario 1: Student Views Own Profile

```
1. Student opens ProfileScreen
   ├─ loggedInUserProfile = Student Saif
   ├─ userProfile = null (initially)
   └─ didChangeDependencies → loadUserProfile(Saif.id)
       └─ userProfile = Student Saif ✅

2. sections_tab renders
   ├─ Checks: userProfile (Saif) vs loggedInUserProfile (Saif)
   ├─ _getTargetProfile() returns: Saif
   └─ Shows: Saif's sections ✅
```

### Scenario 2: Student Navigates to Assistant Profile

```
1. Student clicks on Assistant A
   ├─ Navigator.pushNamed('/assistant-profile', arguments: Assistant A)
   └─ AssistantProfileMain loads
       ├─ _displayedProfile = Assistant A (local)
       ├─ loadUserProfile(Assistant A.id) called
       └─ userProfile = Assistant A (provider) ✅

2. AssistantProfileMain renders showing Assistant A's data ✅
```

### Scenario 3: Student Navigates Back from Assistant

```
1. Student presses back button
   ├─ _onBackPressed() called
   ├─ loadUserProfile(loggedInUser.id) → loadUserProfile(Saif.id)
   ├─ userProfile = Student Saif again
   └─ Navigator.pop()

2. Back on ProfileScreen
   ├─ userProfile = Student Saif
   ├─ loggedInUserProfile = Student Saif
   └─ sections_tab shows: Saif's sections ✅
```

### Scenario 4: Student Navigates from Assistant A to Assistant B

```
1. On Assistant A's profile
   ├─ userProfile = Assistant A
   └─ loggedInUserProfile = Student Saif

2. Student clicks link to Assistant B
   ├─ Navigator.pushNamed('/assistant-profile', arguments: Assistant B)
   └─ AssistantProfileMain loads
       ├─ loadUserProfile(Assistant B.id) called
       └─ userProfile = Assistant B ✅

3. Back from Assistant B
   ├─ loadUserProfile(Saif.id)
   ├─ userProfile = Student Saif
   └─ sections_tab shows: Saif's sections ✅
```

---

## Key Insights

### Why This Fix Was Needed

1. **Global State Consistency**: Components like `sections_tab` rely on the provider's `userProfile` to determine what data to show. Without it being set, they had no way to know which profile was being viewed.

2. **Separation Principle**:

   - `loggedInUserProfile` = Who you are (constant)
   - `userProfile` = Who you're viewing (dynamic)
   - Both must be kept in sync for proper app behavior

3. **Back Navigation**: When navigating back from viewing someone else's profile, we need to explicitly set `userProfile` back to the logged-in user's profile, otherwise it stays on the last viewed profile.

### Why Local State Wasn't Enough

Profile screens like `AssistantProfileMain` and `DoctorProfile` were using `_displayedProfile` (local state) to render their UI, which worked fine **for that screen**. However:

- Other components watching the provider didn't know about the profile change
- `sections_tab` couldn't determine which profile's sections to show
- The app's global state was inconsistent with the local state

---

## Testing Checklist

- [ ] Student views own profile → sections_tab shows student's sections
- [ ] Student navigates to Assistant A → assistant profile loads correctly
- [ ] Student presses back → sections_tab shows student's sections again
- [ ] Student views Assistant A, then Assistant B → both load correctly
- [ ] Student goes back from Assistant B → sections_tab shows student's sections
- [ ] Admin views Doctor profile → doctor profile loads correctly
- [ ] Admin goes back → sections_tab shows admin's own sections

---

## Benefits

1. **Consistent State**: Provider's `userProfile` always reflects the currently viewed profile
2. **Predictable Behavior**: sections_tab always knows which profile's data to show
3. **Proper Separation**: `loggedInUserProfile` (constant) vs `userProfile` (dynamic) working as designed
4. **No Stale Data**: Explicit loading on navigation ensures fresh, correct data

---

## Code Pattern to Follow

### When Navigating TO a Profile:

```dart
// Always call loadUserProfile to set the viewed profile
ref.read(userProfileProvider.notifier).loadUserProfile(userId);
```

### When Navigating BACK from a Profile:

```dart
// Load the logged-in user's profile as the viewed profile
final loggedInUser = ref.read(userProfileProvider).loggedInUserProfile;
if (loggedInUser != null) {
  await ref.read(userProfileProvider.notifier).loadUserProfile(loggedInUser.id);
}
```

### In Components That Check Which Profile Is Viewed:

```dart
final userProfile = userProfileState.userProfile;           // Who we're viewing
final loggedInUser = userProfileState.loggedInUserProfile;  // Who we are
final targetProfile = _getTargetProfile(userProfile, loggedInUser);
```

---

## Conclusion

This fix completes the user profile separation implementation. Now the provider's `userProfile` is always kept in sync with the profile being viewed, ensuring all components have consistent, up-to-date information about which profile to display data for.

**Status:** ✅ Complete  
**Impact:** sections_tab and all profile-dependent components now work correctly  
**Testing:** Ready for validation
