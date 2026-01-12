// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation - uses browser info
String getDeviceName() {
  try {
    final userAgent = html.window.navigator.userAgent;
    if (userAgent.contains('Chrome')) {
      return 'POS-Web-Chrome';
    } else if (userAgent.contains('Firefox')) {
      return 'POS-Web-Firefox';
    } else if (userAgent.contains('Edge')) {
      return 'POS-Web-Edge';
    }
    return 'POS-Web-Browser';
  } catch (e) {
    return 'POS-Web';
  }
}
