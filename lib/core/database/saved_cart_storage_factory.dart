import 'saved_cart_storage.dart';

// Conditional imports
import 'saved_cart_storage_stub.dart'
    if (dart.library.io) 'saved_cart_storage_desktop.dart'
    if (dart.library.html) 'saved_cart_storage_web.dart' as platform_storage;

/// Factory to get the appropriate SavedCartStorage implementation
class SavedCartStorageFactory {
  static SavedCartStorage? _instance;

  /// Get the singleton instance of the storage
  static SavedCartStorage getInstance() {
    _instance ??= platform_storage.createSavedCartStorage();
    return _instance!;
  }

  /// Initialize the storage (call once at app start)
  static Future<void> initialize() async {
    final storage = getInstance();
    await storage.init();
  }
}
