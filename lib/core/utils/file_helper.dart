import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports
import 'file_helper_stub.dart'
    if (dart.library.io) 'file_helper_io.dart'
    if (dart.library.html) 'file_helper_web.dart' as file_helper;

/// Helper class for file operations
/// Platform-specific implementations for desktop and web
class FileHelper {
  /// Check if file operations are supported
  static bool get isSupported => !kIsWeb;

  /// Save CSV content and open it
  /// Returns true if successful, false otherwise
  static Future<bool> saveCsvAndOpen(String filename, String csvContent) {
    return file_helper.saveCsvAndOpen(filename, csvContent);
  }
}
