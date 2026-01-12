import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop implementation using window_manager
Future<void> initializeWindow({
  double width = 1280,
  double height = 800,
  double minWidth = 800,
  double minHeight = 600,
  String title = 'StampSmart POS',
}) async {
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(width, height),
    minimumSize: Size(minWidth, minHeight),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: title,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
