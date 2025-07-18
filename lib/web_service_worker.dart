// Conditional import for web and non-web platforms
export 'web_service_worker_stub.dart'
    if (dart.library.html) 'web_service_worker_web.dart';

// Stub for non-web platforms
Future<void> registerServiceWorkerWeb() async {}
