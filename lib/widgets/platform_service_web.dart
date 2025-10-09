import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class PlatformServiceWeb {
  static bool isIOSWeb() {
    if (!kIsWeb) return false;

    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      final isIOS = userAgent.contains('iphone') || userAgent.contains('ipad');
      final isStandalone =
          html.window.matchMedia('(display-mode: standalone)').matches ||
          _hasStandaloneTrue(html.window.navigator);
      // print('UserAgent: $userAgent');
      // print('isIOS: $isIOS');
      // print('isStandalone: $isStandalone');
      // print('Should show install screen: ${isIOS && !isStandalone}');
      return isIOS && !isStandalone;
    } catch (e) {
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
