import 'package:dio/dio.dart';

/// Stub implementation for web - browsers handle cookies natively
void addCookieManager(Dio dio) {
  // No-op on web - browsers handle cookies automatically
}

/// Check cookies for a request (no-op on web)
Future<void> logCookies(Uri uri) async {
  // No-op on web
}

/// Clear all cookies (no-op on web - browser manages cookies)
Future<void> clearCookies() async {
  // No-op on web
}
