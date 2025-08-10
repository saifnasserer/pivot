import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// A wrapper widget that provides haptic feedback for common interactions.
///
/// This widget can wrap any widget and provide haptic feedback when tapped.
class HapticWrapper extends StatelessWidget {
  /// Creates a haptic wrapper.
  ///
  /// The [child] and [onTap] parameters are required.
  const HapticWrapper({
    super.key,
    required this.child,
    required this.onTap,
    this.hapticType = HapticType.light,
    this.behavior = HitTestBehavior.opaque,
  });

  /// The child widget to wrap.
  final Widget child;

  /// The callback that is called when the widget is tapped.
  final VoidCallback onTap;

  /// The type of haptic feedback to provide. Defaults to light.
  final HapticType hapticType;

  /// The hit test behavior. Defaults to opaque.
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _provideHapticFeedback();
        onTap();
      },
      behavior: behavior,
      child: child,
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
