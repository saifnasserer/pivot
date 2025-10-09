# Sections Tab Debugging Guide

## Date: October 9, 2025

## Changes Made

Added extensive logging to track section data flow and identify why section info changes when navigating between profiles.

### **Files with Added Logging:**

1. ✅ `sections_tab.dart` - Tracks profile changes and section loading
2. ✅ `sections_builder.dart` - Shows which sections are being filtered and displayed
3. ✅ `enhanced_section_list_item.dart` - Shows which section is selected for each subject

### **Fixed Core Issues:**

1. ✅ All `ref.watch(userProfileProvider).userProfile` → `loggedInUserProfile` in profile screens
2. ✅ `sections_builder.dart` now filters sections to ONLY show logged-in user's relevant sections
3. ✅ Navigation properly updates `userProfile` in provider when viewing assistants
4. ✅ Back navigation restores logged-in user as viewed profile

---

## How to Test and Debug

### **Test Scenario:**

1. Login as Student (e.g., Saif in Section 1)
2. Open your profile → Go to Sections tab
3. Observe the logs and note which sections appear
4. Navigate to an Assistant's profile
5. Go back to your profile → Sections tab
6. Check if the section info is correct or corrupted

### **What to Look For in Logs:**

#### **Step 1: Opening Own Profile**

```
📱 [ProfileScreen] didChangeDependencies
   Logged-in: Saif Nasser
   Viewed: null (or different)
   → Loading logged-in user as viewed profile

🔍 [SectionsTab] _getTargetProfile called
   userProfile: Saif Nasser (brattzLWzXgcn2NDvdLzvhCYVe23)
   loggedInUser: Saif Nasser (brattzLWzXgcn2NDvdLzvhCYVe23)
   → Returning loggedInUser (own profile)

🔍 [SectionsBuilder] Logged-in user: Saif Nasser (brattzLWzXgcn2NDvdLzvhCYVe23)
   Total sections in provider: X
   Logged-in user enrolled subjects: [subject1, subject2, ...]
   Logged-in user section: 1
   Filtered sections count: Y
   Section IDs: [...]

🎯 [EnhancedSectionItem] Subject: Subject Name
   Available sections: N
   - Section 1 (Assistant: assistant_id_1)
   - Section 2 (Assistant: assistant_id_2)
   User preferred assistant: assistant_id_X
   → Selected section: Section 1 (matched preference)
```

**Expected**: Should show YOUR sections with correct details (days, time, location, etc.)

#### **Step 2: Viewing Assistant Profile**

```
🔄 [DoctorProfile] or [AssistantProfile] Loading...
```

No sections_tab logs should appear here (you're on assistant's profile screen, not your own).

#### **Step 3: Going Back to Your Profile**

```
Navigating back from assistant profile
← loadUserProfile called with logged-in user ID

🔍 [SectionsTab] _getTargetProfile called
   userProfile: Saif Nasser (brattzLWzXgcn2NDvdLzvhCYVe23)
   loggedInUser: Saif Nasser (brattzLWzXgcn2NDvdLzvhCYVe23)

📋 [SectionsTab] _loadSectionsForUser called for: Saif Nasser
   Current sections in provider: X
   [List of ALL sections - might include assistant's sections!]

🔍 [SectionsBuilder] Logged-in user: Saif Nasser
   Total sections in provider: X
   Filtered sections count: Y  ← Should only be YOUR sections

🎯 [EnhancedSectionItem] Subject: Subject Name
   Available sections: N  ← Should only show sections from YOUR enrolled subjects
   - Section X (Assistant: Y)
   → Selected section: Section X
```

---

## Key Questions to Answer from Logs:

### **Q1: Are assistant's sections polluting the provider?**

**Check:** When you go back, does "Total sections in provider" include sections from the assistant you just viewed?

- ❌ **Problem**: If yes, the provider is keeping assistant sections
- ✅ **Expected**: Should only have sections for YOUR enrolled subjects

### **Q2: Is the filtering working?**

**Check:** Compare "Total sections in provider" vs "Filtered sections count"

- ❌ **Problem**: If filtered count is wrong, the filter logic has a bug
- ✅ **Expected**: Filtered count should match only YOUR relevant sections

### **Q3: Which section is being selected?**

**Check:** In `[EnhancedSectionItem]` logs, which section is "Selected section"?

- ❌ **Problem**: If it shows wrong section number, the preference or selection logic is wrong
- ✅ **Expected**: Should show the section matching your preference or the first one for your department/level

### **Q4: Is the preferred assistant correct?**

**Check:** "User preferred assistant" value

- ❌ **Problem**: If it shows assistant ID you didn't select, preferences are corrupted
- ✅ **Expected**: Should match the assistant you chose (or null if none chosen)

---

##Likely Root Causes:

### **Issue 1: Provider Pollution**

```
User sections + Assistant sections mixed in global provider
→ Filter fails to exclude assistant sections
→ Wrong sections displayed
```

**Fix**: The `userRelevantSections` filter in `sections_builder.dart` should prevent this.

### **Issue 2: Wrong Section Selected**

```
Multiple sections available for same subject
→ Preference points to assistant not teaching your section
→ Wrong section details displayed
```

**Fix**: Need to verify assistant preferences are correct.

### **Issue 3: Cache/Provider Not Clearing**

```
Assistant sections remain in provider after navigation
→ Provider thinks it has "relevant data"
→ Doesn't refetch user's actual sections
```

**Fix**: Might need to clear sections when navigating between profiles.

---

## Next Steps:

1. **Run the app** with the new logging
2. **Follow the test scenario** above
3. **Share the console logs** showing:

   - What sections are in the provider at each step
   - Which section is being selected for display
   - Any mismatches between expected and actual

4. Based on the logs, we can identify:
   - If it's a provider pollution issue (needs clearing)
   - If it's a filtering issue (needs better filtering)
   - If it's a preference issue (needs preference reset)
   - If it's a selection logic issue (needs smarter selection)

---

## Expected Behavior:

**Sections Tab should ALWAYS show:**

- Only sections for YOUR enrolled subjects
- Only sections matching YOUR department/level/section
- The section from the assistant YOU chose (via preference)
- Correct details: days, time, location for YOUR section

**It should NEVER show:**

- Sections from assistants' profiles you viewed
- Sections from subjects you're not enrolled in
- Wrong section numbers (e.g., Section 2 when you're in Section 1)

---

**Status:** 🔍 Debugging Mode Active  
**Action Required:** Run app and share console logs
