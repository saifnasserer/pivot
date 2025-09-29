import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _firstRunKey = 'first_run_completed';
  static const String _introShownKey = 'intro_shown';
  static const String _deepLinkKey = 'pending_deep_link';

  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_firstRunKey) ?? true);
  }

  Future<void> markFirstRunCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstRunKey, true);
  }

  Future<bool> isIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_introShownKey) ?? false;
  }

  Future<void> markIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introShownKey, true);
  }

  Future<String?> getPendingDeepLink() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deepLinkKey);
  }

  Future<void> setPendingDeepLink(String? link) async {
    final prefs = await SharedPreferences.getInstance();
    if (link != null) {
      await prefs.setString(_deepLinkKey, link);
    } else {
      await prefs.remove(_deepLinkKey);
    }
  }

  Future<void> clearPendingDeepLink() async {
    await setPendingDeepLink(null);
  }
}
