import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:martfury/src/service/currency_service.dart';
import 'package:martfury/src/service/language_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:martfury/core/app_config.dart';
import 'package:martfury/src/service/token_service.dart';
import 'package:martfury/src/view/screen/start_screen.dart';
import 'package:martfury/src/view/screen/maintenance_screen.dart';
import 'package:martfury/src/view/screen/server_error_screen.dart';
import 'package:get/get.dart';

class BaseService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final currency = json.decode(
      prefs.getString(CurrencyService.selectedCurrencyKey) ?? '{}',
    );
    final language = json.decode(
      prefs.getString(LanguageService.selectedLanguageKey) ?? '{}',
    );

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-CURRENCY': (currency?['title'] ?? '').toString(),
      'X-LANGUAGE': (language?['lang_locale'] ?? '').toString(),
      'X-API-KEY': AppConfig.apiKey,
    };

    if (includeAuth) {
      headers['Authorization'] =
          'Bearer ${await TokenService.getToken() ?? ''}';
    }

    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // Handle unauthorized - clear token and redirect to start screen
      await TokenService.deleteToken();
      Get.offAll(() => const StartScreen());
      throw Exception('Unauthorized');
    }

    if (response.statusCode == 502) {
      // Handle bad gateway - show server error screen
      Get.offAll(
        () => ServerErrorScreen(
          onRetry: () {
            // Go back to start screen when retry is pressed
            Get.offAll(() => const StartScreen());
          },
        ),
      );
      throw Exception('Bad Gateway - Server Error');
    }

    if (response.statusCode == 503) {
      // Handle maintenance mode - show maintenance screen
      Get.offAll(
        () => MaintenanceScreen(
          onRetry: () {
            // Go back to start screen when retry is pressed
            Get.offAll(() => const StartScreen());
          },
        ),
      );
      throw Exception('Service Unavailable - Maintenance Mode');
    }

    if (response.statusCode == 404) {
      // Don't navigate away for 404 errors, just throw exception
      // Many API endpoints return 404 for valid operations (e.g., resource doesn't exist)
      throw Exception('Not Found - Resource Not Available');
    }

    if (response.statusCode == 500) {
      // Handle internal server error

      // Try to parse error message from response
      String errorMessage = 'Internal Server Error';
      try {
        final errorBody = json.decode(response.body);
        errorMessage =
            errorBody['message'] ?? errorBody['error'] ?? errorMessage;
      } catch (e) {
        // If response body is not valid JSON, use the raw body if it's not too long
        if (response.body.length < 200) {
          errorMessage = response.body;
        }
      }

      throw Exception('Server Error: $errorMessage');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Handle different response types
      try {
        final decoded = json.decode(response.body);

        // If the API returns a boolean 'true' as an error indicator
        if (decoded is bool && decoded == true) {
          throw Exception('API returned error flag: true');
        }

        return decoded;
      } catch (e) {
        // If it's already a FormatException, the body might not be JSON
        if (e is FormatException) {
          // Return raw body for non-JSON responses
          return response.body;
        }
        // Re-throw other exceptions
        rethrow;
      }
    } else {
      // Try to parse the error message from the response body
      try {
        final errorBody = json.decode(response.body);
        // Check for various error message formats
        final errorMessage =
            errorBody['message'] ??
            errorBody['error'] ??
            errorBody['errors']?.toString() ??
            'An error occurred';
        throw Exception(errorMessage);
      } on FormatException {
        // If response body is not valid JSON, throw a generic error
        throw Exception('An error occurred (${response.statusCode})');
      }
    }
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, Object> body) async {
    final headers = await _getHeaders();
    final url = '$baseUrl$endpoint';

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, Object> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint, Map<String, Object> body) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  /// POST method for authentication endpoints (without Authorization header)
  Future<dynamic> postAuth(String endpoint, Map<String, Object> body) async {
    final headers = await _getHeaders(includeAuth: false);
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(body),
    );

    return _handleResponse(response);
  }
}
