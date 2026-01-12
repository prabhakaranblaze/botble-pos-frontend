import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports
import 'window_helper_stub.dart'
    if (dart.library.io) 'window_helper_desktop.dart'
    if (dart.library.html) 'window_helper_web.dart' as platform_window;

/// Helper class for window management
/// Only functional on desktop platforms
class WindowHelper {
  /// Initialize the window (desktop only)
  static Future<void> initialize({
    double width = 1280,
    double height = 800,
    double minWidth = 800,
    double minHeight = 600,
    String title = 'StampSmart POS',
  }) async {
    if (kIsWeb) {
      // No window management on web
      return;
    }

    await platform_window.initializeWindow(
      width: width,
      height: height,
      minWidth: minWidth,
      minHeight: minHeight,
      title: title,
    );
  }
}
