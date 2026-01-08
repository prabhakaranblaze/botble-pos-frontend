import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class WebViewTimeoutHandler {
  /// Test if URL is accessible before loading in WebView
  static Future<bool> testUrlAccessibility(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final response = await http.head(
        Uri.parse(url),
        headers: headers ?? {},
      ).timeout(timeout);

      final isAccessible = response.statusCode >= 200 && response.statusCode < 400;
      return isAccessible;
    } catch (e) {
      return false;
    }
  }
  
  /// Create a WebView controller with enhanced timeout handling
  static WebViewController createTimeoutResistantController({
    required String userAgent,
    Function(String)? onPageStarted,
    Function(String)? onPageFinished,
    Function(WebResourceError)? onWebResourceError,
    Function(HttpResponseError)? onHttpError,
    NavigationDecision Function(NavigationRequest)? onNavigationRequest,
  }) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(userAgent)
      // Clear all caches to prevent timeout caching
      ..clearCache()
      ..clearLocalStorage();
    
    // Enhanced navigation delegate with timeout handling
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          onPageStarted?.call(url);
        },
        onPageFinished: (String url) {
          // Inject JavaScript to detect and handle timeout states
          controller.runJavaScript('''
            // Remove any cached timeout indicators
            var timeoutElements = document.querySelectorAll('[class*="timeout"], [id*="timeout"]');
            timeoutElements.forEach(function(el) {
              el.remove();
            });

            // Check if page shows timeout content
            var bodyText = document.body ? document.body.innerText.toLowerCase() : '';
            if (bodyText.includes('timeout') || bodyText.includes('timed out')) {
              window.location.reload(true); // Force reload
            }
          ''');

          onPageFinished?.call(url);
        },
        onWebResourceError: (WebResourceError error) {
          // Handle specific WebKit timeout errors
          if (_isTimeoutError(error)) {
            _handleTimeoutError(controller, error);
          }

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
  
  /// Check if the error is a timeout-related error
  static bool _isTimeoutError(WebResourceError error) {
    // WebKit timeout error codes
    const timeoutErrorCodes = [-1001, -1009, -1004];
    
    if (timeoutErrorCodes.contains(error.errorCode)) {
      return true;
    }
    
    if (error.errorType == WebResourceErrorType.timeout) {
      return true;
    }
    
    final description = error.description.toLowerCase();
    return description.contains('timeout') || 
           description.contains('timed out') ||
           description.contains('request timeout');
  }
  
  /// Handle timeout errors with recovery strategies
  static void _handleTimeoutError(WebViewController controller, WebResourceError error) {
    // Strategy 1: Clear all caches and try again
    Timer(const Duration(seconds: 2), () {
      controller.clearCache();
      controller.clearLocalStorage();

      // Strategy 2: Inject JavaScript to clear any cached timeout states
      controller.runJavaScript('''
        // Clear all storage
        if (typeof(Storage) !== "undefined") {
          if (localStorage) localStorage.clear();
          if (sessionStorage) sessionStorage.clear();
        }

        // Clear cookies
        document.cookie.split(";").forEach(function(c) {
          document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
        });

        // Clear any error indicators
        var errorElements = document.querySelectorAll('[class*="error"], [class*="timeout"]');
        errorElements.forEach(function(el) {
          el.remove();
        });
      ''');
    });
  }
  
  /// Load URL with enhanced timeout handling
  static Future<void> loadUrlWithTimeoutHandling(
    WebViewController controller,
    String url, {
    Map<String, String>? headers,
    Duration preTestTimeout = const Duration(seconds: 10),
  }) async {
    // Step 1: Test URL accessibility first
    await testUrlAccessibility(
      url,
      headers: headers,
      timeout: preTestTimeout,
    );

    // Step 2: Prepare enhanced headers
    final enhancedHeaders = {
      'Cache-Control': 'no-cache, no-store, must-revalidate, max-age=0',
      'Pragma': 'no-cache',
      'Expires': '0',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'DNT': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      ...?headers,
    };

    // Step 3: Add cache-busting parameter
    final separator = url.contains('?') ? '&' : '?';
    final cacheBustingUrl = '$url${separator}_t=${DateTime.now().millisecondsSinceEpoch}&_r=${DateTime.now().microsecond}';

    // Step 4: Load with enhanced headers
    await controller.loadRequest(
      Uri.parse(cacheBustingUrl),
      headers: enhancedHeaders,
    );
  }
  
  /// Perform aggressive timeout recovery
  static Future<void> performTimeoutRecovery(WebViewController controller, String url, {Map<String, String>? headers}) async {
    // Step 1: Clear everything
    await controller.clearCache();
    await controller.clearLocalStorage();

    // Step 2: Wait a moment for clearing to complete
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 3: Inject aggressive cleanup JavaScript
    await controller.runJavaScript('''
      // Clear all possible storage
      try {
        if (typeof(Storage) !== "undefined") {
          if (localStorage) localStorage.clear();
          if (sessionStorage) sessionStorage.clear();
        }

        // Clear IndexedDB
        if (window.indexedDB) {
          indexedDB.databases().then(databases => {
            databases.forEach(db => {
              indexedDB.deleteDatabase(db.name);
            });
          });
        }

        // Clear Web SQL (if supported)
        if (window.openDatabase) {
          try {
            var db = openDatabase('', '', '', '');
            db.transaction(function(tx) {
              tx.executeSql('DELETE FROM __WebKitDatabaseInfoTable__');
            });
          } catch(e) {}
        }

        // Clear all cookies aggressively
        document.cookie.split(";").forEach(function(c) {
          document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date(0).toUTCString() + ";path=/");
          document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date(0).toUTCString() + ";path=/;domain=" + window.location.hostname);
        });
      } catch(e) {
        // Cleanup error, continue anyway
      }
    ''');

    // Step 4: Wait for cleanup to complete
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 5: Reload with fresh request
    await loadUrlWithTimeoutHandling(controller, url, headers: headers);
  }
}
