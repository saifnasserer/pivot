import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

/// A reusable circular button component used throughout the app.
///
/// This button is designed to be used for primary actions like form submissions
/// and navigation. It features a circular shape with customizable icon and color.
class CircularButton extends StatelessWidget {
  /// Creates a circular button.
  ///
  /// The [onPressed] and [icon] parameters are required.
  const CircularButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor = Colors.black87,
    this.iconColor = Colors.white,
    this.elevation = 5,
    this.iconSizeMultiplier = 1.5,
    this.sizeMultiplier = 4,
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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
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
}
