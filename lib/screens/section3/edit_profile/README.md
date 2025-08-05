# Edit Profile Refactored Structure

This folder contains the refactored edit profile functionality, split into logical components for better maintainability and separation of concerns.

## File Structure

### Core Files

- **`edit_profile.dart`** - Main entry point that sets up the provider and renders the screen
- **`edit_profile_screen.dart`** - Main screen widget that orchestrates all components
- **`edit_profile_provider.dart`** - State management for the edit profile functionality

### UI Components

- **`profile_image_section.dart`** - Handles profile image display and image picking functionality
- **`basic_info_section.dart`** - Form for basic user information (name, gender)
- **`educational_details_section.dart`** - Form for educational details (year, department, section)
- **`password_section.dart`** - Form for password change functionality
- **`action_buttons.dart`** - Save and cancel buttons with loading states

## Component Responsibilities

### EditProfileProvider

- Manages the state of the edit profile form
- Handles profile loading, validation, and saving
- Manages error states and loading states
- Coordinates with UserProfileProvider and SettingsProvider

### EditProfileScreen

- Main orchestrator that combines all UI components
- Manages form initialization and data flow
- Handles navigation and user feedback
- Coordinates between UI components and the provider

### ProfileImageSection

- Displays current profile image (from URL or picked file)
- Handles image picking from gallery
- Compresses images for optimal performance
- Manages image upload states

### BasicInfoSection

- Form for user's basic information
- Handles name and gender inputs
- Validates required fields
- Updates provider state on changes

### EducationalDetailsSection

- Form for educational information
- Handles year, department, and section selection
- Manages dependent dropdowns (departments based on year, sections based on department)
- Updates provider state on changes

### PasswordSection

- Form for password change functionality
- Handles current password, new password, and confirmation
- Manages password visibility toggles
- Validates password requirements

### ActionButtons

- Save and cancel buttons
- Shows loading state during save operations
- Handles form validation for save button
- Manages navigation on cancel

## Benefits of This Refactoring

1. **Separation of Concerns**: Each component has a single responsibility
2. **Maintainability**: Easier to modify individual components without affecting others
3. **Reusability**: Components can be reused in other parts of the app
4. **Testability**: Each component can be tested independently
5. **Readability**: Code is more organized and easier to understand
6. **Scalability**: Easy to add new features or modify existing ones

## Usage

The main entry point is `edit_profile.dart` which should be imported and used as a widget:

```dart
import 'package:pivot/screens/section3/edit_profile/edit_profile.dart';

// Use in your app
EditProfile()
```

## State Management

The `EditProfileProvider` uses the Provider pattern for state management and integrates with:

- `UserProfileProvider` - For user profile data
- `SettingsProvider` - For section counts and settings

All UI components receive the provider instance and update the state through provider methods, ensuring a clean data flow.
