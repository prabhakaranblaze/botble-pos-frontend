import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:martfury/core/app_config.dart';
import 'package:martfury/src/service/token_service.dart';

class WebViewDiagnostics {
  static Future<void> testCheckoutUrl(String cartId) async {
    final url = '${AppConfig.apiBaseUrl}/api/v1/ecommerce/checkout/cart/$cartId';
    debugPrint('=== WebView Diagnostics ===');
    debugPrint('Testing URL: $url');
    debugPrint('API Base URL: ${AppConfig.apiBaseUrl}');
    debugPrint('API Key: ${AppConfig.apiKey}');
    
    try {
      // Test basic connectivity to the API base URL
      debugPrint('\n1. Testing basic connectivity...');
      final baseResponse = await http.get(
        Uri.parse(AppConfig.apiBaseUrl),
        headers: {
          'User-Agent': 'MartFury-App-Diagnostics/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('Base URL Response: ${baseResponse.statusCode}');
      debugPrint('Base URL Headers: ${baseResponse.headers}');
      
      // Test the specific checkout URL
      debugPrint('\n2. Testing checkout URL...');
      final token = await TokenService.getToken();
      
      final checkoutResponse = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-KEY': AppConfig.apiKey,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'User-Agent': 'MartFury-App-Diagnostics/1.0',
        },
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('Checkout URL Response: ${checkoutResponse.statusCode}');
      debugPrint('Checkout URL Headers: ${checkoutResponse.headers}');
      debugPrint('Response body length: ${checkoutResponse.body.length}');
      
      if (checkoutResponse.statusCode == 200) {
        debugPrint('✅ Checkout URL is accessible');
        
        // Check if response contains HTML
        if (checkoutResponse.body.toLowerCase().contains('<html')) {
          debugPrint('✅ Response contains HTML content');
        } else {
          debugPrint('⚠️ Response does not contain HTML content');
          debugPrint('Response preview: ${checkoutResponse.body.substring(0, 200)}...');
        }
      } else {
        debugPrint('❌ Checkout URL returned error: ${checkoutResponse.statusCode}');
        debugPrint('Error body: ${checkoutResponse.body}');
      }
      
    } catch (e) {
      debugPrint('❌ Error testing URLs: $e');
      
      if (e is SocketException) {
        debugPrint('Network error: ${e.message}');
        debugPrint('This might indicate DNS issues or server unavailability');
      } else if (e is HttpException) {
        debugPrint('HTTP error: ${e.message}');
      } else if (e.toString().contains('timeout')) {
        debugPrint('Timeout error - server is taking too long to respond');
      }
    }
    
    debugPrint('=== End Diagnostics ===\n');
  }
  
  static Future<void> testWebViewCompatibility() async {
    debugPrint('=== WebView Compatibility Test ===');
    
    try {
      // Test a simple, reliable URL
      const testUrl = 'https://httpbin.org/html';
      debugPrint('Testing simple HTML URL: $testUrl');
      
      final response = await http.get(
        Uri.parse(testUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 MartFury-App/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('Test URL Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('✅ Basic HTTP requests are working');
      } else {
        debugPrint('❌ Basic HTTP requests failing');
      }
      
    } catch (e) {
      debugPrint('❌ WebView compatibility test failed: $e');
    }
    
    debugPrint('=== End Compatibility Test ===\n');
  }
  
  static void logWebViewSettings() {
    debugPrint('=== WebView Settings ===');
    debugPrint('JavaScript Mode: unrestricted');
    debugPrint('User Agent: Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 MartFury-App/1.0');
    debugPrint('Background Color: white');
    debugPrint('Cache: cleared');
    debugPrint('Local Storage: cleared');
    debugPrint('=== End Settings ===\n');
  }
}
