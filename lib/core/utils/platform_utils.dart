import 'package:flutter/foundation.dart' show kIsWeb;
import 'platform_utils_stub.dart'
    if (dart.library.io) 'platform_utils_io.dart'
    if (dart.library.html) 'platform_utils_web.dart' as platform;

/// Platform detection utility for conditional logic
class PlatformUtils {
  /// Returns true if running on web
  static bool get isWeb => kIsWeb;

  /// Returns true if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop => platform.isDesktop();

  /// Returns true if running on mobile (iOS, Android)
  static bool get isMobile => platform.isMobile();

  /// Returns true if running on Windows
  static bool get isWindows => platform.isWindows();

  /// Returns true if running on macOS
  static bool get isMacOS => platform.isMacOS();

  /// Returns true if running on Linux
  static bool get isLinux => platform.isLinux();

  /// Returns the current platform name
  static String get platformName => platform.platformName();

  /// Returns true if Web Serial API is likely supported (Chrome/Edge on desktop)
  static bool get supportsWebSerial => kIsWeb;
}
