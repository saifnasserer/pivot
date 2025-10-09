import 'dart:html' as html;

class AndroidLandingScreenHelper {
  static void continueOnWeb() {
    // Reload the page with a skip parameter to bypass platform detection
    final currentUrl = html.window.location.href;
    final uri = Uri.parse(currentUrl);
    final newUri = uri.replace(
      queryParameters: {'skip_platform_check': 'true'},
    );
    html.window.location.href = newUri.toString();
  }
}
