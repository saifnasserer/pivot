import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Text sizes that automatically adapt to screen size
  static double text(BuildContext context, {TextSize size = TextSize.medium}) {
    final double screenWidth = width(context);
    final multiplier =
        screenWidth >= 900 ? 1.5 : (screenWidth >= 600 ? 1.25 : 1.0);

    switch (size) {
      case TextSize.small:
        return 14.0 * multiplier;
      case TextSize.medium:
        return 18.0 * multiplier;
      case TextSize.heading:
        return 24.0 * multiplier;
    }
  }

  // Spacing that automatically adapts to screen size
  static double space(BuildContext context, {Space size = Space.medium}) {
    final double screenWidth = width(context);
    final multiplier =
        screenWidth >= 900 ? 1.5 : (screenWidth >= 600 ? 1.25 : 1.0);

    switch (size) {
      case Space.tiny:
        return 4.0 * multiplier;
      case Space.small:
        return 8.0 * multiplier;
      case Space.medium:
        return 20.0 * multiplier;
      case Space.large:
        return 24.0 * multiplier;
      case Space.xlarge:
        return 32.0 * multiplier;
    }
  }

  // Padding that automatically adapts to screen size
  static EdgeInsets padding(BuildContext context, {Space size = Space.medium}) {
    return EdgeInsets.all(space(context, size: size));
  }

  // Horizontal padding that automatically adapts to screen size
  static EdgeInsets paddingHorizontal(
    BuildContext context, {
    Space size = Space.medium,
  }) {
    return EdgeInsets.symmetric(horizontal: space(context, size: size));
  }

  // Vertical padding that automatically adapts to screen size
  static EdgeInsets paddingVertical(
    BuildContext context, {
    Space size = Space.medium,
  }) {
    return EdgeInsets.symmetric(vertical: space(context, size: size));
  }
}

// Enums for type safety
enum TextSize { small, medium, heading }

enum Space { tiny, small, medium, large, xlarge }

class ScreenD {
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;
}
