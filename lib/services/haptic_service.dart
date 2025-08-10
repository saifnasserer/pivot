import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// A centralized service for managing haptic feedback throughout the app.
///
/// This service provides different types of haptic feedback and handles
/// platform compatibility (web vs mobile).
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  /// Whether haptic feedback is enabled
  bool _isEnabled = true;

  /// Enable or disable haptic feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if haptic feedback is enabled
  bool get isEnabled => _isEnabled;

  /// Light impact feedback - for subtle interactions
  /// Use for: button taps, minor selections, navigation
  Future<void> lightImpact() async {
    if (!_isEnabled || kIsWeb) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Medium impact feedback - for more noticeable interactions
  /// Use for: form submissions, important actions, confirmations
  Future<void> mediumImpact() async {
    if (!_isEnabled || kIsWeb) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Heavy impact feedback - for significant interactions
  /// Use for: errors, warnings, major state changes
  Future<void> heavyImpact() async {
    if (!_isEnabled || kIsWeb) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Selection click feedback - for selection changes
  /// Use for: dropdown selections, checkbox toggles, radio buttons
  Future<void> selectionClick() async {
    if (!_isEnabled || kIsWeb) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Vibration feedback - for notifications and alerts
  /// Use for: notifications, alerts, important system messages
  Future<void> vibrate() async {
    if (!_isEnabled || kIsWeb) return;
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Custom vibration pattern
  /// Use for: custom feedback patterns
  Future<void> customVibrate(List<int> pattern) async {
    if (!_isEnabled || kIsWeb) return;
    try {
      // Note: This would require a custom implementation or plugin
      // For now, fall back to standard vibration
      await HapticFeedback.vibrate();
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Success feedback - combination of light impact
  Future<void> success() async {
    await lightImpact();
  }

  /// Error feedback - combination of heavy impact
  Future<void> error() async {
    await heavyImpact();
  }

  /// Warning feedback - combination of medium impact
  Future<void> warning() async {
    await mediumImpact();
  }

  /// Navigation feedback - light impact for navigation
  Future<void> navigation() async {
    await lightImpact();
  }

  /// Form interaction feedback - selection click for form elements
  Future<void> formInteraction() async {
    await selectionClick();
  }
}
