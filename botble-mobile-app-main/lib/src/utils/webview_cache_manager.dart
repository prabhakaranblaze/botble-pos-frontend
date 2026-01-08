import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewCacheManager {
  /// Aggressively clear all WebView caches and data
  static Future<void> clearAllWebViewData(WebViewController controller) async {
    try {
      // Clear cache
      await controller.clearCache();

      // Clear local storage
      await controller.clearLocalStorage();

      // Clear cookies by injecting JavaScript
      await controller.runJavaScript('''
        // Clear all cookies
        document.cookie.split(";").forEach(function(c) {
          document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
        });

        // Clear session storage
        if (typeof(Storage) !== "undefined" && sessionStorage) {
          sessionStorage.clear();
        }

        // Clear local storage via JavaScript (additional cleanup)
        if (typeof(Storage) !== "undefined" && localStorage) {
          localStorage.clear();
        }

        // Clear any cached data in memory
        if (window.caches) {
          caches.keys().then(function(names) {
            for (let name of names) {
              caches.delete(name);
            }
          });
        }
      ''');

    } catch (e) {
      // Error during cache clearing, continue anyway
    }
  }

  /// Create a fresh WebViewController with optimal settings
  static WebViewController createFreshController({
    required String userAgent,
    Function(String)? onPageStarted,
    Function(String)? onPageFinished,
    Function(WebResourceError)? onWebResourceError,
    Function(HttpResponseError)? onHttpError,
    NavigationDecision Function(NavigationRequest)? onNavigationRequest,
  }) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setUserAgent(userAgent);

    // Clear everything immediately
    controller.clearCache();
    controller.clearLocalStorage();

    // Set navigation delegate
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          onPageStarted?.call(url);
        },
        onPageFinished: (String url) {
          // Additional cleanup after page load
          controller.runJavaScript('''
            // Remove any error indicators that might be cached
            var errorElements = document.querySelectorAll('[class*="error"], [id*="error"]');
            errorElements.forEach(function(el) {
              if (el.textContent.includes('timeout') || el.textContent.includes('failed')) {
                el.remove();
              }
            });
          ''');

          onPageFinished?.call(url);
        },
        onWebResourceError: (WebResourceError error) {
          onWebResourceError?.call(error);
        },
        onHttpError: (HttpResponseError error) {
          onHttpError?.call(error);
        },
        onNavigationRequest: (NavigationRequest request) {
          return onNavigationRequest?.call(request) ?? NavigationDecision.navigate;
        },
      ),
    );

    return controller;
  }

  /// Load URL with cache-busting parameters
  static Future<void> loadUrlWithCacheBusting(
    WebViewController controller,
    String url, {
    Map<String, String>? headers,
  }) async {
    // Add cache-busting parameter
    final separator = url.contains('?') ? '&' : '?';
    final cacheBustingUrl = '$url${separator}_cb=${DateTime.now().millisecondsSinceEpoch}';

    // Enhanced headers to prevent caching
    final enhancedHeaders = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      ...?headers,
    };

    await controller.loadRequest(
      Uri.parse(cacheBustingUrl),
      headers: enhancedHeaders,
    );
  }

  /// Check if WebView is in a cached error state
  static Future<bool> isInErrorState(WebViewController controller) async {
    try {
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          var bodyText = document.body ? document.body.innerText.toLowerCase() : '';
          var titleText = document.title ? document.title.toLowerCase() : '';

          var errorKeywords = ['timeout', 'error', 'failed', 'not found', 'unavailable'];

          for (var keyword of errorKeywords) {
            if (bodyText.includes(keyword) || titleText.includes(keyword)) {
              return true;
            }
          }

          return false;
        })();
      ''');

      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Get detailed WebView state information
  static Future<Map<String, dynamic>> getWebViewState(WebViewController controller) async {
    try {
      final result = await controller.runJavaScriptReturningResult('''
        JSON.stringify({
          url: window.location.href,
          title: document.title,
          readyState: document.readyState,
          bodyLength: document.body ? document.body.innerHTML.length : 0,
          hasErrors: document.querySelectorAll('[class*="error"], [id*="error"]').length > 0,
          timestamp: Date.now()
        });
      ''');

      if (result is String) {
        // Parse the JSON result
        // Note: In a real implementation, you'd use dart:convert
        return {'raw': result};
      }

      return {'error': 'Failed to get state'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
