import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Get download path for update installer
Future<String?> getDownloadPath(String downloadUrl) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final fileName = downloadUrl.split('/').last;
    return '${tempDir.path}/$fileName';
  } catch (e) {
    debugPrint('❌ UPDATE SERVICE: Failed to get download path: $e');
    return null;
  }
}

/// Install update from installer path
Future<bool> installUpdate(String installerPath) async {
  try {
    // Verify file exists
    final file = File(installerPath);
    if (!await file.exists()) {
      debugPrint('❌ UPDATE SERVICE: Installer file not found');
      return false;
    }

    // Launch the installer with /SILENT flag for quiet install
    final result = await Process.start(
      installerPath,
      ['/SILENT', '/CLOSEAPPLICATIONS'],
      mode: ProcessStartMode.detached,
    );

    debugPrint('✅ UPDATE SERVICE: Installer launched with PID: ${result.pid}');

    // Exit the app to allow installation
    exit(0);
  } catch (e) {
    debugPrint('❌ UPDATE SERVICE: Failed to launch installer: $e');
    return false;
  }
}
