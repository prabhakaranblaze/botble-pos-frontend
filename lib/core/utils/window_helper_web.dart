// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation - uses browser fullscreen API
Future<void> initializeWindow({
  double width = 1280,
  double height = 800,
  double minWidth = 800,
  double minHeight = 600,
  String title = 'StampSmart POS',
}) async {
  // No window management on web
  // The browser handles window sizing
}

/// Check if browser is in fullscreen mode
Future<bool> isFullScreen() async {
  return html.document.fullscreenElement != null;
}

/// Toggle browser fullscreen mode
Future<void> setFullScreen(bool fullscreen) async {
  if (fullscreen) {
    await html.document.documentElement?.requestFullscreen();
  } else {
    html.document.exitFullscreen();
  }
}

/// Focus window (no-op on web)
Future<void> focusWindow() async {
  // Browser handles focus automatically
}
