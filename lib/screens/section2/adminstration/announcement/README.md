# Announcement Components

This folder contains the refactored components for the announcement functionality, split from the original monolithic `add_announcement_screen.dart` file.

## Structure

```
announcement/
├── add_announcement_main.dart      # Main screen orchestrating all components
├── add_announcement_controller.dart # Shared logic, constants, and utility methods
├── steps/                          # Individual step components
│   ├── basic_info_step.dart        # Title and description input
│   ├── attachments_step.dart       # Images, PDF files, and links
│   ├── styling_step.dart          # Color selection and department tags
│   └── scheduling_step.dart       # Publish/expire dates and options
├── index.dart                      # Exports for easier importing
└── README.md                       # This documentation
```

## Components

### `AddAnnouncementMain`

- **Purpose**: Main screen that orchestrates all step components
- **Responsibilities**:
  - State management for the entire form
  - Navigation between steps
  - Form validation and submission
  - Animation controllers

### `AddAnnouncementController`

- **Purpose**: Shared logic and constants
- **Responsibilities**:
  - Department tags enum and constants
  - File picking and upload methods
  - Dialog methods for editing
  - DateTime selection utilities

### Step Components

Each step is a focused, reusable component:

#### `BasicInfoStep`

- Title and description input fields
- Character count validation
- Form validation

#### `AttachmentsStep`

- Image picking and display
- PDF file upload
- Link management
- Attachment editing and deletion

#### `StylingStep`

- Color selection for importance levels
- Department tag selection
- Visual feedback for selections

#### `SchedulingStep`

- Publish and expire date selection
- Draft and pinned options
- DateTime picker integration

## Benefits of Refactoring

1. **Maintainability**: Each component has a single responsibility
2. **Reusability**: Components can be reused in other contexts
3. **Testability**: Smaller components are easier to test
4. **Readability**: Code is more organized and easier to understand
5. **Scalability**: Easy to add new features or modify existing ones

## Usage

```dart
import 'package:pivot/screens/section2/adminstration/announcement/index.dart';

// Use the main component
AddAnnouncementMain(
  isEditing: false,
  announcement: null,
)
```

## Migration Notes

- The original `add_announcement_screen.dart` has been replaced
- All imports should be updated to use the new components
- The functionality remains the same, just better organized
