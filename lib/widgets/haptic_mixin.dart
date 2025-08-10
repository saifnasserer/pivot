import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// A mixin that provides easy access to haptic feedback methods.
///
/// Use this mixin in StatefulWidget classes to add haptic feedback
/// to user interactions.
mixin HapticMixin<T extends StatefulWidget> on State<T> {
  final HapticService _hapticService = HapticService();

  /// Light impact feedback for subtle interactions
  Future<void> hapticLight() async {
    await _hapticService.lightImpact();
  }

  /// Medium impact feedback for noticeable interactions
  Future<void> hapticMedium() async {
    await _hapticService.mediumImpact();
  }

  /// Heavy impact feedback for significant interactions
  Future<void> hapticHeavy() async {
    await _hapticService.heavyImpact();
  }

  /// Selection click feedback for selection changes
  Future<void> hapticSelection() async {
    await _hapticService.selectionClick();
  }

  /// Success feedback
  Future<void> hapticSuccess() async {
    await _hapticService.success();
  }

  /// Error feedback
  Future<void> hapticError() async {
    await _hapticService.error();
  }

  /// Warning feedback
  Future<void> hapticWarning() async {
    await _hapticService.warning();
  }

  /// Navigation feedback
  Future<void> hapticNavigation() async {
    await _hapticService.navigation();
  }

  /// Form interaction feedback
  Future<void> hapticFormInteraction() async {
    await _hapticService.formInteraction();
  }

  /// Vibration feedback
  Future<void> hapticVibrate() async {
    await _hapticService.vibrate();
  }
}
