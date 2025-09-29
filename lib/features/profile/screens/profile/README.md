# Profile Refactored Structure

This folder contains the refactored profile functionality, split into logical components for better maintainability and separation of concerns.

## File Structure

### Core Files

- **`profile.dart`** - Main entry point that sets up the provider and renders the screen
- **`profile_screen.dart`** - Main screen widget that orchestrates all components
- **`profile_provider.dart`** - State management for the profile functionality

### UI Components

- **`profile_app_bar.dart`** - App bar with title, logout button, and tab bar
- **`profile_details_tab.dart`** - Profile details and quick actions tab
- **`quick_actions_section.dart`** - Quick action cards for different user roles
- **`schedule_tab.dart`** - Schedule display tab
- **`subjects_tab.dart`** - Subjects display tab
- **`sections_tab.dart`** - Sections display tab

## Component Responsibilities

### ProfileProvider

- Manages the state of the profile screen
- Handles data fetching for schedule, tasks, subjects, and sections
- Manages user profile changes and data synchronization
- Handles logout functionality
- Manages notification preferences and permissions

### ProfileScreen

- Main orchestrator that combines all tab components
- Manages tab controller and lifecycle
- Handles app lifecycle state changes
- Coordinates between UI components and the provider
- Routes to special profiles (Doctor, Assistant) based on user role

### ProfileAppBar

- Displays the app bar with title and logout button
- Manages the tab bar with all profile tabs
- Handles logout confirmation dialog
- Provides navigation functionality

### ProfileDetailsTab

- Displays user profile information
- Shows quick actions section
- Handles profile details layout

### QuickActionsSection

- Displays action cards based on user role
- Handles navigation to different sections
- Manages notification settings dialog
- Provides role-specific actions (subject registration, etc.)

### Tab Components

- **ScheduleTab**: Displays user's schedule with calendar
- **SubjectsTab**: Shows user's enrolled/teaching subjects
- **SectionsTab**: Displays user's sections
- **BookmarksScreen**: Shows bookmarked items (imported from existing)
- **WeekTasks**: Shows weekly tasks (imported from existing)

## Benefits of This Refactoring

1. **Separation of Concerns**: Each component has a single responsibility
2. **Maintainability**: Easier to modify individual components without affecting others
3. **Reusability**: Components can be reused in other parts of the app
4. **Testability**: Each component can be tested independently
5. **Readability**: Code is more organized and easier to understand
6. **Scalability**: Easy to add new features or modify existing ones

## Usage

The main entry point is `profile.dart` which should be imported and used as a widget:

```dart
import 'package:pivot/screens/section3/profile/profile.dart';

// Use in your app
Profile(initialTabIndex: 0)
```

## State Management

The `ProfileProvider` uses the Provider pattern for state management and integrates with:

- `UserProfileProvider` - For user profile data
- `ScheduleProvider` - For schedule data
- `TaskProvider` - For task data
- `SubjectProvider` - For subject data
- `SectionProvider` - For section data

All UI components receive the provider instance and update the state through provider methods, ensuring a clean data flow.

## Tab Structure

The profile screen contains 6 tabs:

1. **Profile Details** - User info and quick actions
2. **Bookmarks** - Saved/bookmarked items
3. **Sections** - User's sections
4. **Subjects** - User's subjects
5. **Schedule** - User's schedule
6. **Week Tasks** - Weekly tasks

## Special User Roles

The profile screen automatically routes to special profiles for:

- **Professors** → `DoctorProfile`
- **Mini Professors** → `AssistantProfile`

This ensures appropriate functionality for different user types.
