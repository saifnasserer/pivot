# User Profile Separation Implementation Guide

## Overview

This document explains the refactored user profile management system that properly separates the **logged-in user** from the **viewed profile**, similar to how social media platforms (Instagram, Twitter, etc.) handle profile navigation.

## Problem Statement

Previously, the app used two variables (`loggedInUserProfile` and `userProfile`) that sometimes shared the same data reference. When a user viewed someone else's profile (like a doctor or assistant), the `loggedInUserProfile` would temporarily change, causing multiple logic and UI issues.

## Solution

The new implementation maintains strict separation between:

1. **`loggedInUserProfile`** (Current User/Authenticated User)

   - Represents the authenticated user who is currently logged in
   - **Constant during the entire session**
   - Only changes when:
     - User logs in/out
     - User updates their own profile data
   - Never affected by profile navigation

2. **`userProfile`** (Viewed User/Profile Being Viewed)
   - Represents the profile currently being viewed
   - **Changes dynamically** when navigating between profiles
   - Can be any user (including own profile)
   - Always a separate instance from `loggedInUserProfile`

## Key Concepts

### Profile Viewing States

```dart
// When viewing own profile
currentUser = Saif, viewedUser = Saif
// (but separate instances, not shared reference)

// When viewing another user's profile
currentUser = Saif, viewedUser = Dr. Ahmed
```

### Checking Profile Ownership

```dart
// Use the helper getter to check if viewing own profile
bool isOwnProfile = notifier.isViewingOwnProfile;

// Or compare IDs directly
bool isOwnProfile = state.userProfile?.id == state.loggedInUserProfile?.id;
```

## API Reference

### Loading Profiles

#### `loadLoggedInUserProfile()`

Loads the authenticated user's profile. Should be called:

- At app startup after authentication
- After the user updates their own profile data
- Never when navigating to view profiles

```dart
await ref.read(userProfileProvider.notifier).loadLoggedInUserProfile();
```

#### `loadUserProfile(String userId)`

Loads a user profile for viewing. Should be called:

- When opening any profile (including own profile)
- When navigating between different user profiles
- Always creates a fresh instance, never shares reference

```dart
await ref.read(userProfileProvider.notifier).loadUserProfile(userId);
```

#### `viewOwnProfile()`

Convenience method to load the logged-in user's profile for viewing.
Internally calls `loadUserProfile()` with the logged-in user's ID.

```dart
await ref.read(userProfileProvider.notifier).viewOwnProfile();
```

### State Getters

#### `isViewingOwnProfile`

Helper getter that returns `true` if the currently viewed profile belongs to the logged-in user.

```dart
final notifier = ref.read(userProfileProvider.notifier);
if (notifier.isViewingOwnProfile) {
  // Show "Edit Profile" button
} else {
  // Show "Follow" or "Message" button
}
```

### Update Methods

All profile update methods automatically handle both profiles:

- Always update `loggedInUserProfile` with the new data
- If viewing own profile, also update `userProfile`

#### `updateUserProfile(UserProfile profile)`

Updates a user profile with new data.

#### `uploadProfileImage(String imagePath)`

Uploads and sets a new profile image for the logged-in user.

#### `updateEnrolledSubjects(List<String> subjectIds)`

Updates the enrolled subjects for the logged-in user.

#### `updateTeachingSubjects(List<String> subjectIds)`

Updates the teaching subjects for the logged-in user.

#### `updateAssistantPreferences(Map<String, String> preferences)`

Updates assistant preferences for the logged-in user.

#### `updateSocialMediaLinks(String userId, List<SocialMediaLink> socialMediaLinks)`

Updates social media links for a specific user.

#### `updateAboutMe(String userId, String aboutMe)`

Updates the "About Me" section for a specific user.

## Usage Examples

### Example 1: Profile Screen

```dart
class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);

    useEffect(() {
      // Load the profile to view
      notifier.loadUserProfile(userId);
      return null;
    }, [userId]);

    final viewedProfile = state.userProfile;
    final isOwnProfile = notifier.isViewingOwnProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text(viewedProfile?.name ?? 'Profile'),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _navigateToEditProfile(context),
            )
          else
            IconButton(
              icon: Icon(Icons.message),
              onPressed: () => _sendMessage(viewedProfile!),
            ),
        ],
      ),
      body: _buildProfileContent(viewedProfile, isOwnProfile),
    );
  }
}
```

### Example 2: Home Screen (Own Profile)

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);

    useEffect(() {
      // Load logged-in user at startup
      notifier.loadLoggedInUserProfile();
      return null;
    }, []);

    // The logged-in user is always available
    final currentUser = state.loggedInUserProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${currentUser?.name ?? ''}'),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundImage: currentUser?.profileImageUrl != null
                ? NetworkImage(currentUser!.profileImageUrl!)
                : null,
            ),
            onPressed: () {
              // Navigate to own profile
              // This will call loadUserProfile with own ID
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    userId: currentUser!.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildHomeContent(),
    );
  }
}
```

### Example 3: User List (Viewing Others' Profiles)

```dart
class UserListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);

    useEffect(() {
      notifier.fetchAllUsers();
      return null;
    }, []);

    return ListView.builder(
      itemCount: state.allUsers.length,
      itemBuilder: (context, index) {
        final user = state.allUsers[index];
        final isCurrentUser = user.id == state.loggedInUserProfile?.id;

        return ListTile(
          title: Text(user.name),
          subtitle: Text(user.role),
          trailing: isCurrentUser
            ? Chip(label: Text('You'))
            : null,
          onTap: () {
            // Navigate to user profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: user.id),
              ),
            );
          },
        );
      },
    );
  }
}
```

### Example 4: Editing Own Profile

```dart
class EditProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);

    // Always use loggedInUserProfile for editing
    final profile = state.loggedInUserProfile;

    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Form(
        child: Column(
          children: [
            TextFormField(
              initialValue: profile?.name,
              decoration: InputDecoration(labelText: 'Name'),
              onSaved: (value) => _nameController.text = value ?? '',
            ),
            ElevatedButton(
              onPressed: () async {
                // Update the profile
                final updatedProfile = profile!.copyWith(
                  name: _nameController.text,
                );

                await notifier.updateUserProfile(updatedProfile);

                // loggedInUserProfile will be updated automatically
                // If viewing own profile, userProfile will also be updated

                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Migration Guide

### For Existing Code

1. **Profile Loading**: No changes needed to method calls, just ensure proper usage:

   ```dart
   // At app startup
   await notifier.loadLoggedInUserProfile();

   // When viewing any profile (including own)
   await notifier.loadUserProfile(userId);
   ```

2. **Checking Own Profile**: Replace manual ID comparison with helper:

   ```dart
   // Old approach (still works but verbose)
   final isOwnProfile = state.userProfile?.id == state.loggedInUserProfile?.id;

   // New approach (recommended)
   final isOwnProfile = notifier.isViewingOwnProfile;
   ```

3. **Update Methods**: No changes needed. They already handle both profiles correctly.

4. **Remove `restoreLoggedInUserProfile()` calls**: This method has been replaced with `viewOwnProfile()`:

   ```dart
   // Old (removed)
   notifier.restoreLoggedInUserProfile();

   // New
   await notifier.viewOwnProfile();
   ```

## Benefits

1. **Clear Separation**: Logged-in user and viewed profile are always separate instances
2. **Consistent State**: App state remains consistent across profile navigation
3. **Scalable**: Easy to add multi-profile features in the future
4. **Predictable**: UI logic becomes simpler and more predictable
5. **Bug Prevention**: Prevents accidental profile data mixing
6. **Social Media Pattern**: Follows industry-standard patterns from Instagram, Twitter, etc.

## Implementation Details

### State Structure

```dart
class UserProfileState {
  /// The profile currently being viewed (changes dynamically)
  final UserProfile? userProfile;

  /// The authenticated user (constant during session)
  final UserProfile? loggedInUserProfile;

  // Other fields...
}
```

### Key Implementation Points

1. **`loadUserProfile()` always fetches fresh data** from the repository, ensuring separate instances
2. **Update methods check IDs** to update both profiles when viewing own profile
3. **`isViewingOwnProfile` getter** provides convenient comparison
4. **No shared references** between `loggedInUserProfile` and `userProfile`

## Testing Checklist

- [ ] Login flow: `loggedInUserProfile` is set correctly
- [ ] View own profile: Both profiles have same ID but are separate instances
- [ ] View other's profile: `userProfile` changes, `loggedInUserProfile` stays constant
- [ ] Navigate between profiles: `userProfile` updates correctly each time
- [ ] Update own profile: Both profiles update if viewing own profile
- [ ] Update from edit screen: Changes reflect immediately
- [ ] Profile image upload: Updates both profiles if viewing own
- [ ] Logout: Both profiles cleared correctly

## Troubleshooting

### Issue: Changes not reflecting in viewed profile

**Solution**: Ensure you're calling `loadUserProfile()` after updates, or use the update methods that automatically handle this.

### Issue: `loggedInUserProfile` changing when viewing others

**Solution**: Never call `loadLoggedInUserProfile()` during profile navigation. Only call it at app startup or after explicit user data updates.

### Issue: Shared reference between profiles

**Solution**: Always use `loadUserProfile()` instead of `setUserProfile()` with `loggedInUserProfile`. The `loadUserProfile()` method fetches fresh data.

## Architecture Diagram

```
┌─────────────────────────────────────────────┐
│           User Profile Provider             │
├─────────────────────────────────────────────┤
│                                             │
│  loggedInUserProfile (Constant)             │
│  ├─ Set at login                            │
│  ├─ Updated on own data changes             │
│  └─ Never affected by navigation            │
│                                             │
│  userProfile (Dynamic)                      │
│  ├─ Changes on navigation                   │
│  ├─ Can be any user                         │
│  └─ Always separate instance                │
│                                             │
└─────────────────────────────────────────────┘
         │                    │
         │                    │
    ┌────▼────┐          ┌────▼────┐
    │  Login  │          │ Profile │
    │  Screen │          │ Screen  │
    └─────────┘          └─────────┘
         │                    │
         │                    │
    loadLogged...()      loadUser...()
```

## Conclusion

This refactored implementation provides a robust, scalable, and maintainable approach to user profile management. By keeping the logged-in user and viewed profile strictly separated, we eliminate a whole class of bugs and make the app behavior more predictable and aligned with user expectations.
