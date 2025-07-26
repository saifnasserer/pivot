import 'package:flutter/foundation.dart';
import 'dart:html' as html;

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
      print('PlatformServiceWeb error: $e');
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
