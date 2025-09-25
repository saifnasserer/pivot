// Only imported on web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> registerServiceWorkerWeb() async {
  if (html.window.navigator.serviceWorker != null) {
    try {
      await html.window.navigator.serviceWorker!.register(
        'firebase-messaging-sw.js',
      );
      // ignore: avoid_print

    } catch (e) {
      // ignore: avoid_print
    }
  }
}
