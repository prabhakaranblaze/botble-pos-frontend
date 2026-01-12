import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';

final CookieJar _cookieJar = CookieJar();

/// Add cookie manager for desktop platforms
void addCookieManager(Dio dio) {
  dio.interceptors.add(CookieManager(_cookieJar));
  debugPrint('🍪 API SERVICE: Cookie manager added');
}

/// Log cookies for a request (desktop only)
Future<void> logCookies(Uri uri) async {
  try {
    final cookies = await _cookieJar.loadForRequest(uri);
    if (cookies.isNotEmpty) {
      debugPrint('🍪 SENDING ${cookies.length} COOKIE(S):');
      for (var cookie in cookies) {
        final value = cookie.value.length > 20
            ? '${cookie.value.substring(0, 20)}...'
            : cookie.value;
        debugPrint('  🍪 ${cookie.name} = $value');
      }
    } else {
      debugPrint('🍪 NO COOKIES TO SEND');
    }
  } catch (e) {
    debugPrint('⚠️ Cookie check error: $e');
  }
}

/// Clear all cookies on logout
Future<void> clearCookies() async {
  await _cookieJar.deleteAll();
  debugPrint('🍪 API SERVICE: Cookies cleared');
}
