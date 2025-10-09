// Conditional import for web-only code
import 'package:flutter/foundation.dart';
import 'platform_service_web.dart'
    if (dart.library.io) 'platform_service_stub.dart';

class PlatformService {
  static bool isIOSWeb() {
    if (!kIsWeb) return false;
    return PlatformServiceWeb.isIOSWeb();
  }

  static bool isAndroidWeb() {
    if (!kIsWeb) return false;
    return PlatformServiceWeb.isAndroidWeb();
  }
}
