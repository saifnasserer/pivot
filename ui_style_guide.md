# Application UI Style Guide

This document outlines the UI styles, components, and design patterns used in the application. Its purpose is to ensure a consistent and cohesive user experience.

## 1. Colors

The application uses a minimalistic color palette.

- **Primary Background**: `Colors.white`
- **Primary Action Color**: `Colors.black` (Used for primary buttons, FABs, and focused borders)
- **Primary Text on Dark Background**: `Colors.white`
- **Primary Text on Light Background**: `Colors.black`
- **Text Field Fill**: `Color(0xFFF7F7F7)`
- **Validation States**:
  - **Valid/Success**: `Colors.green`
  - **Error**: `Colors.red`

**Example (`add_edit_schedule_dialog.dart`):**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
  child: Text('Submit', style: TextStyle(color: Colors.white)),
)
```

## 2. Typography

Text sizes are managed by the `Responsive` class to ensure adaptability across different screen sizes. The main text sizes are:

- `TextSize.heading`: For titles and headers.
- `TextSize.medium`: For body text and hints in text fields.
- `TextSize.small`: For smaller text elements.

**Example (`add_edit_schedule_dialog.dart`):**
```dart
Text(
  'Dialog Title',
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: Responsive.text(context, size: TextSize.heading),
  ),
),
```

## 3. Buttons

### ElevatedButton

Used for primary actions (e.g., 'Submit', 'Add').

- **Style**: Black background with white text.
- **Reference**: `add_edit_schedule_dialog.dart`

**Example:**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
  onPressed: _submitForm,
  child: Text(
    'اضافة',
    style: TextStyle(color: Colors.white),
  ),
),
```

### TextButton

Used for secondary actions (e.g., 'Cancel').

- **Style**: Default `TextButton` style.
- **Reference**: `add_edit_schedule_dialog.dart`

**Example:**
```dart
TextButton(
  child: const Text('الغاء'),
  onPressed: () {
    Navigator.of(context).pop();
  },
),
```

### FloatingActionButton

- **Style**: Black background with a white icon.
- **Reference**: `profile.dart`

**Example:**
```dart
FloatingActionButton(
  backgroundColor: Colors.black,
  onPressed: () { /* ... */ },
  child: const Icon(Icons.add, color: Colors.white),
)
```

## 4. Text Fields

The `CustomTextField` widget is a `TextFormField` wrapper that provides a consistent style for text input.

- **Layout**: Right-to-left (`TextDirection.rtl`) and centered text alignment.
- **Decoration**:
  - **Fill Color**: `Color(0xFFF7F7F7)`
  - **Border**: `OutlineInputBorder` with rounded corners (`Responsive.space(context, size: Space.medium)`).
  - **Hint Style**: Black text with `TextSize.medium`.
- **State-based Borders**:
  - **Focused**: Black border.
  - **Valid**: Green border (width: 2).
  - **Error**: Red border.
- **Reference**: `lib/screens/models/custom_text_field.dart`

## 5. Dialogs

`AlertDialog` is used for modals and dialogs.

- **Title**: Centered, bold text with `TextSize.heading`.
- **Content**: Often a `SingleChildScrollView` containing a `Form`.
- **Actions**: A `TextButton` for cancellation and an `ElevatedButton` for submission.
- **Reference**: `add_edit_schedule_dialog.dart`

## 6. Responsiveness

The `lib/responsive.dart` file is crucial for maintaining a consistent and adaptive UI. It provides methods for:

- **Spacing**: `Responsive.space(context, size: Space.small | medium | large)`
- **Padding**: `Responsive.paddingHorizontal(context)`
- **Text Sizes**: `Responsive.text(context, size: TextSize.small | medium | heading)`

Always use the `Responsive` class for dimensions and text sizes to ensure the UI scales correctly on different devices.
