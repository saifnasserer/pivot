import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // Updated to use available height considering system UI insets
  static double height(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
  }

  // New method to get available height for dialogs and overlays
  static double availableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.viewInsets.top -
        mediaQuery.viewInsets.bottom;
  }

  // New method to get safe area height
  static double safeHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        mediaQuery.viewInsets.top -
        mediaQuery.viewInsets.bottom;
  }

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

  static EdgeInsets padding(BuildContext context, {Space size = Space.medium}) {
    return EdgeInsets.all(space(context, size: size));
  }

  static EdgeInsets paddingHorizontal(
    BuildContext context, {
    Space size = Space.medium,
  }) {
    return EdgeInsets.symmetric(horizontal: space(context, size: size));
  }

  static EdgeInsets paddingVertical(
    BuildContext context, {
    Space size = Space.medium,
  }) {
    return EdgeInsets.symmetric(vertical: space(context, size: size));
  }
}

enum TextSize { small, medium, heading }

enum Space { tiny, small, medium, large, xlarge }

class ScreenD {
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // Updated to use available height
  static double height(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
  }
}
