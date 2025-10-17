import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class PlatformServiceWeb {
  static bool isIOSWeb() {
    if (!kIsWeb) return false;

    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      final platform = html.window.navigator.platform?.toLowerCase() ?? '';

      // More comprehensive iOS detection
      final isIOS =
          userAgent.contains('iphone') ||
          userAgent.contains('ipad') ||
          userAgent.contains('ipod') ||
          platform.contains('iphone') ||
          platform.contains('ipad') ||
          platform.contains('ipod') ||
          // Safari on iOS detection
          (userAgent.contains('safari') &&
              userAgent.contains('mobile') &&
              !userAgent.contains('chrome') &&
              !userAgent.contains('android'));

      // Check standalone mode more efficiently
      bool isStandalone = false;
      try {
        isStandalone =
            html.window.matchMedia('(display-mode: standalone)').matches;
      } catch (_) {
        // Fallback if matchMedia fails
        try {
          isStandalone = _hasStandaloneTrue(html.window.navigator);
        } catch (_) {
          isStandalone = false;
        }
      }

      final shouldShowIOSScreen = isIOS && !isStandalone;

      // ALWAYS print for iOS detection (not just debug mode)
      print('🍎 [iOS Detection]');
      print('   UserAgent: $userAgent');
      print('   Platform: $platform');
      print('   isIOS: $isIOS');
      print('   isStandalone: $isStandalone');
      print('   Should show iOS screen: $shouldShowIOSScreen');

      return shouldShowIOSScreen;
    } catch (e) {
      print('❌ [iOS Detection] Error: $e');
      print('   Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  static bool isAndroidWeb() {
    if (!kIsWeb) return false;

    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      // Check if it's Android and not in standalone/app mode
      final isAndroid = userAgent.contains('android');
      final isStandalone =
          html.window.matchMedia('(display-mode: standalone)').matches;

      if (kDebugMode) {
        print('UserAgent: $userAgent');
        print('isAndroid: $isAndroid');
        print('isStandalone: $isStandalone');
        print('Should show Android landing: ${isAndroid && !isStandalone}');
      }

      return isAndroid && !isStandalone;
    } catch (e) {
      return false;
    }
  }

  static bool _hasStandaloneTrue(dynamic navigator) {
    try {
      return navigator.standalone == true;
    } catch (_) {
      return false;
    }
  }
}
