import 'package:flutter/foundation.dart';
import '../responsive.dart';

// Conditional import for web-only code
import 'platform_service_web.dart'
    if (dart.library.io) 'platform_service_stub.dart';

class PlatformService {
  static bool isIOSWeb() {
    if (!kIsWeb) return false;
    return PlatformServiceWeb.isIOSWeb();
  }
}
