# Sections Module

This folder contains the refactored sections functionality, split into focused components for better maintainability.

## Structure

- **`sections_builder.dart`**: Main builder class that handles the core logic for building sections
- **`enhanced_section_list_item.dart`**: Individual section list item component with animations and interactions
- **`assistant_selection_dialog.dart`**: Dialog for selecting assistants for sections
- **`sections.dart`**: Main export file that provides backward compatibility

## Usage

```dart
import 'package:pivot/screens/section3/profile_widgets/sections/sections.dart';

// Use the main builder function
final sections = buildSectionsSlivers(context);

// Or use the builder class directly
final sections = SectionsBuilder.buildSectionsSlivers(context);
```

## Components

### SectionsBuilder

- Handles the main logic for building sections
- Manages loading, error, and empty states
- Filters sections based on user preferences and enrolled subjects

### EnhancedSectionListItem

- Individual section card with hover animations
- Displays section information (location, time, days)
- Handles tap interactions to show assistant selection

### AssistantSelectionDialog

- Modal dialog for selecting assistants
- Manages assistant preferences
- Provides edit mode for changing default assistants

## Benefits of Refactoring

1. **Separation of Concerns**: Each file has a single responsibility
2. **Maintainability**: Easier to find and modify specific functionality
3. **Reusability**: Components can be used independently
4. **Testability**: Individual components can be tested in isolation
5. **Backward Compatibility**: Original API is preserved through the main sections.dart file
