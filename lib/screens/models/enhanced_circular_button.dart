import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/haptic_service.dart';

/// An enhanced circular button component with haptic feedback.
///
/// This button extends the original CircularButton with haptic feedback
/// for better user experience.
class EnhancedCircularButton extends StatelessWidget {
  /// Creates an enhanced circular button.
  ///
  /// The [onPressed] and [icon] parameters are required.
  const EnhancedCircularButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor = Colors.black87,
    this.iconColor = Colors.white,
    this.elevation = 5,
    this.iconSizeMultiplier = 1.5,
    this.sizeMultiplier = 4,
    this.hapticType = HapticType.light,
  });

  /// The callback that is called when the button is tapped.
  final VoidCallback onPressed;

  /// The icon to display inside the button.
  final IconData icon;

  /// The background color of the button. Defaults to black87.
  final Color backgroundColor;

  /// The color of the icon. Defaults to white.
  final Color iconColor;

  /// The elevation of the button. Defaults to 5.
  final double elevation;

  /// Multiplier for the icon size relative to the heading text size.
  /// Defaults to 1.5.
  final double iconSizeMultiplier;

  /// Multiplier for the button size relative to xlarge space.
  /// Defaults to 4.
  final double sizeMultiplier;

  /// The type of haptic feedback to provide. Defaults to light.
  final HapticType hapticType;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Provide haptic feedback
        await _provideHapticFeedback();
        // Call the original onPressed callback
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: CircleBorder(),
        minimumSize: Size(
          Responsive.space(context, size: Space.xlarge) * sizeMultiplier,
          Responsive.space(context, size: Space.xlarge) * sizeMultiplier,
        ),
        elevation: elevation,
      ),
      child: Icon(
        icon,
        size:
            Responsive.text(context, size: TextSize.heading) *
            iconSizeMultiplier,
        color: iconColor,
      ),
    );
  }

  /// Provide haptic feedback based on the specified type
  Future<void> _provideHapticFeedback() async {
    final hapticService = HapticService();

    switch (hapticType) {
      case HapticType.light:
        await hapticService.lightImpact();
        break;
      case HapticType.medium:
        await hapticService.mediumImpact();
        break;
      case HapticType.heavy:
        await hapticService.heavyImpact();
        break;
      case HapticType.selection:
        await hapticService.selectionClick();
        break;
      case HapticType.success:
        await hapticService.success();
        break;
      case HapticType.error:
        await hapticService.error();
        break;
      case HapticType.warning:
        await hapticService.warning();
        break;
      case HapticType.navigation:
        await hapticService.navigation();
        break;
    }
  }
}

/// Enum for different types of haptic feedback
enum HapticType {
  light,
  medium,
  heavy,
  selection,
  success,
  error,
  warning,
  navigation,
}
