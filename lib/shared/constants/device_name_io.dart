import 'dart:io' show Platform;

/// Desktop implementation - uses hostname
String getDeviceName() {
  try {
    return Platform.localHostname.isNotEmpty
        ? 'POS-${Platform.localHostname}'
        : 'Desktop Terminal';
  } catch (e) {
    return 'Desktop Terminal';
  }
}
