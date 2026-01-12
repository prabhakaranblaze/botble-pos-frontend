import 'package:flutter/foundation.dart' show kIsWeb;
import 'print_service_interface.dart';

// Conditional imports
import 'print_service_stub.dart'
    if (dart.library.io) 'print_service_desktop.dart'
    if (dart.library.html) 'print_service_web.dart' as platform_print;

/// Factory to get the appropriate PrintService implementation
/// based on the current platform
class PrintServiceFactory {
  static PrintServiceInterface? _instance;

  /// Get the singleton instance of the print service
  static PrintServiceInterface getInstance() {
    _instance ??= platform_print.createPrintService();
    return _instance!;
  }

  /// Check if we're running on web
  static bool get isWeb => kIsWeb;

  /// Check if printing is supported on current platform
  static bool get isPrintingSupported {
    if (kIsWeb) {
      // On web, check for Web Serial API support
      return getInstance().isWebSerialSupported;
    }
    // Desktop always supports printing
    return true;
  }
}
