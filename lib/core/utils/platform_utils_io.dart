import 'dart:io' show Platform;

/// IO implementation for desktop and mobile platforms

bool isDesktop() => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

bool isMobile() => Platform.isIOS || Platform.isAndroid;

bool isWindows() => Platform.isWindows;

bool isMacOS() => Platform.isMacOS;

bool isLinux() => Platform.isLinux;

String platformName() {
  if (Platform.isWindows) return 'Windows';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isLinux) return 'Linux';
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  return 'Unknown';
}
