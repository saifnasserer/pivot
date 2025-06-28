import 'package:shared_preferences/shared_preferences.dart';

class IntroductionService {
  static const String _hasSeenIntroductionKey = 'hasSeenIntroduction';

  /// Check if the user has seen the introduction screen
  static Future<bool> hasSeenIntroduction() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenIntroductionKey) ?? false;
  }

  /// Mark that the user has seen the introduction screen
  static Future<void> markIntroductionAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenIntroductionKey, true);
  }

  /// Reset the introduction flag (useful for testing)
  static Future<void> resetIntroduction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenIntroductionKey);
  }
}
