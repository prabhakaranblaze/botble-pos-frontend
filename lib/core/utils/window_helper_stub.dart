/// Stub implementation - should never be used
Future<void> initializeWindow({
  double width = 1280,
  double height = 800,
  double minWidth = 800,
  double minHeight = 600,
  String title = 'StampSmart POS',
}) async {
  // No-op
}

/// Stub - always returns false
Future<bool> isFullScreen() async => false;

/// Stub - no-op
Future<void> setFullScreen(bool fullscreen) async {}

/// Stub - no-op
Future<void> focusWindow() async {}
