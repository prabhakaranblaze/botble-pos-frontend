import 'package:martfury/src/service/base_service.dart';
import 'package:martfury/src/model/order.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:martfury/core/app_config.dart';
import 'package:martfury/src/service/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:martfury/src/service/currency_service.dart';
import 'package:martfury/src/service/language_service.dart';
import 'package:path_provider/path_provider.dart';

class OrderService extends BaseService {
  Future<List<Order>> getOrders() async {
    try {
      final response = await get('/api/v1/ecommerce/orders');

      final List<dynamic> ordersJson = response['data'];

      return ordersJson.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<Map<String, dynamic>> trackOrder({
    required String code,
    required String email,
  }) async {
    try {
      // Clean the order code (remove # if present for API call)
      final cleanCode = code.startsWith('#') ? code.substring(1) : code;

      // Try the primary API endpoint for order tracking
      final response = await post('/api/v1/ecommerce/orders/tracking', {
        'code': cleanCode,
        'email': email,
      });

      // Handle different response structures from the API
      if (response != null) {
        // If response has 'data' field, return it
        if (response['data'] != null) {
          return response['data'];
        }
        // If response has 'order' field directly, return the whole response
        else if (response['order'] != null) {
          return response;
        }
        // If response is the order data itself
        else if (response['id'] != null || response['code'] != null) {
          return {'order': response};
        }
      }

      throw Exception('Invalid response format from server');
    } catch (e) {
      // Try alternative endpoint if the primary one fails
      try {
        final response = await get('/api/v1/orders/tracking?code=${Uri.encodeComponent(code)}&email=${Uri.encodeComponent(email)}');

        if (response != null) {
          if (response['data'] != null) {
            return response['data'];
          } else if (response['order'] != null) {
            return response;
          }
        }
      } catch (fallbackError) {
        // If both endpoints fail, provide a helpful error message
        if (e.toString().contains('404') || e.toString().contains('not found')) {
          throw Exception('Order not found. Please check your order code and email address.');
        } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          throw Exception('Invalid email address for this order.');
        } else {
          throw Exception('Unable to track order. Please try again later.');
        }
      }

      throw Exception('Order not found. Please check your order code and email address.');
    }
  }

  Future<Map<String, dynamic>> cancelOrder({
    required int orderId,
    required String cancellationReason,
    String? cancellationReasonDescription,
  }) async {
    try {
      final Map<String, Object> requestData = {
        'cancellation_reason': cancellationReason,
      };

      if (cancellationReasonDescription != null && cancellationReasonDescription.isNotEmpty) {
        requestData['cancellation_reason_description'] = cancellationReasonDescription;
      }

      final response = await post('/api/v1/ecommerce/orders/$orderId/cancel', requestData);

      return response;
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        throw Exception('Order not found or cannot be cancelled.');
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('You are not authorized to cancel this order.');
      } else if (e.toString().contains('422') || e.toString().contains('Unprocessable')) {
        throw Exception('This order cannot be cancelled at this time.');
      } else {
        throw Exception('Failed to cancel order. Please try again later.');
      }
    }
  }

  Future<Map<String, dynamic>> uploadPaymentProof({
    required int orderId,
    required File proofFile,
  }) async {
    // Try the primary upload method first
    try {
      return await _uploadProofPrimary(orderId, proofFile);
    } catch (e) {

      // Try alternative field name
      try {
        return await _uploadProofAlternative(orderId, proofFile);
      } catch (e2) {

        // Return the original error
        if (e.toString().contains('404') || e.toString().contains('not found')) {
          throw Exception('Order not found or upload proof is not available for this order.');
        } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          throw Exception('You are not authorized to upload proof for this order.');
        } else if (e.toString().contains('422') || e.toString().contains('Unprocessable')) {
          throw Exception('Invalid file format or size. Please check your file and try again.');
        } else if (e.toString().contains('Exception:')) {
          rethrow; // Re-throw our custom exceptions
        } else {
          throw Exception('Network error: Please check your connection and try again.');
        }
      }
    }
  }

  Future<Map<String, dynamic>> _uploadProofPrimary(int orderId, File proofFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ecommerce/orders/$orderId/upload-proof'),
    );

    // Add headers similar to base service
    final token = await TokenService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add the same headers as BaseService
    final prefs = await SharedPreferences.getInstance();
    final currency = json.decode(
      prefs.getString(CurrencyService.selectedCurrencyKey) ?? '{}',
    );
    final language = json.decode(
      prefs.getString(LanguageService.selectedLanguageKey) ?? '{}',
    );

    request.headers['Accept'] = 'application/json';
    request.headers['X-CURRENCY'] = (currency?['title'] ?? '').toString();
    request.headers['X-LANGUAGE'] = (language?['lang_locale'] ?? '').toString();
    request.headers['X-API-KEY'] = AppConfig.apiKey;

    // Determine content type based on file extension
    String fileName = proofFile.path.split('/').last.toLowerCase();
    MediaType contentType;
    if (fileName.endsWith('.png')) {
      contentType = MediaType('image', 'png');
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      contentType = MediaType('image', 'jpeg');
    } else if (fileName.endsWith('.pdf')) {
      contentType = MediaType('application', 'pdf');
    } else {
      contentType = MediaType('image', 'jpeg'); // default
    }

    // Add the proof file
    request.files.add(
      await http.MultipartFile.fromPath(
        'proof',
        proofFile.path,
        contentType: contentType,
      ),
    );


    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);


    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data;
    } else {
      try {
        final errorData = json.decode(response.body);
        String errorMessage = errorData['message'] ??
                             errorData['error'] ??
                             'Failed to upload payment proof';
        throw Exception(errorMessage);
      } catch (parseError) {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }
    }
  }

  Future<Map<String, dynamic>> _uploadProofAlternative(int orderId, File proofFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ecommerce/orders/$orderId/upload-proof'),
    );

    // Add headers similar to base service
    final token = await TokenService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final prefs = await SharedPreferences.getInstance();
    final currency = json.decode(
      prefs.getString(CurrencyService.selectedCurrencyKey) ?? '{}',
    );
    final language = json.decode(
      prefs.getString(LanguageService.selectedLanguageKey) ?? '{}',
    );

    request.headers['Accept'] = 'application/json';
    request.headers['X-CURRENCY'] = (currency?['title'] ?? '').toString();
    request.headers['X-LANGUAGE'] = (language?['lang_locale'] ?? '').toString();
    request.headers['X-API-KEY'] = AppConfig.apiKey;

    // Try alternative field names
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Alternative field name
        proofFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );


    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);


    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data;
    } else {
      try {
        final errorData = json.decode(response.body);
        String errorMessage = errorData['message'] ??
                             errorData['error'] ??
                             'Failed to upload payment proof';
        throw Exception(errorMessage);
      } catch (parseError) {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }
    }
  }

  Future<String> downloadPaymentProof({
    required int orderId,
  }) async {
    try {
      final response = await get('/api/v1/ecommerce/orders/$orderId/download-proof');


      // Try different response formats
      String? downloadUrl;

      if (response is Map<String, dynamic>) {
        // Try data.download_url format
        if (response['data'] != null && response['data']['download_url'] != null) {
          downloadUrl = response['data']['download_url'];
        }
        // Try direct download_url format
        else if (response['download_url'] != null) {
          downloadUrl = response['download_url'];
        }
        // Try data.url format
        else if (response['data'] != null && response['data']['url'] != null) {
          downloadUrl = response['data']['url'];
        }
        // Try direct url format
        else if (response['url'] != null) {
          downloadUrl = response['url'];
        }
        // Try if the response itself is a URL string
        else if (response['data'] is String) {
          downloadUrl = response['data'];
        }
      }

      if (downloadUrl != null && downloadUrl.isNotEmpty) {

        // If URL is relative, make it absolute
        if (downloadUrl.startsWith('/')) {
          downloadUrl = '${AppConfig.apiBaseUrl}$downloadUrl';
        }

        return downloadUrl;
      } else {
        throw Exception('Download URL not available in response');
      }
    } catch (e) {

      if (e.toString().contains('404') || e.toString().contains('not found')) {
        throw Exception('Payment proof not found for this order.');
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('You are not authorized to download proof for this order.');
      } else if (e.toString().contains('Exception:')) {
        rethrow; // Re-throw our custom exceptions
      } else {
        throw Exception('Failed to get download link. Please try again later.');
      }
    }
  }

  // Alternative download method that tries direct URL access
  Future<String> downloadPaymentProofDirect({
    required int orderId,
  }) async {
    try {
      // Try direct download URL construction with authentication
      final token = await TokenService.getToken();
      final directUrl = '${AppConfig.apiBaseUrl}/api/v1/ecommerce/orders/$orderId/download-proof?token=${token ?? ''}&api_key=${AppConfig.apiKey}';

      // Test if the URL is accessible
      final response = await http.get(Uri.parse(directUrl));

      if (response.statusCode == 200) {
        // If it's a direct file download, return the URL
        return directUrl;
      } else if (response.statusCode == 302 || response.statusCode == 301) {
        // If it's a redirect, get the redirect URL
        final location = response.headers['location'];
        if (location != null) {
          return location.startsWith('http') ? location : '${AppConfig.apiBaseUrl}$location';
        }
      }

      throw Exception('Direct download not available (${response.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  // Try token-based download URL (common pattern for file downloads)
  Future<String> downloadPaymentProofToken({
    required int orderId,
  }) async {
    try {
      // Some APIs use a token-based download system
      final response = await get('/api/v1/ecommerce/orders/$orderId');


      // Look for download token or proof file info in order details
      if (response['data'] != null) {
        final orderData = response['data'];

        // Try different possible field names for proof file
        final proofFields = ['proof_file', 'payment_proof', 'proof', 'proof_url', 'proof_token'];

        for (final field in proofFields) {
          if (orderData[field] != null) {
            final proofValue = orderData[field];

            if (proofValue is String) {
              // If it's already a URL, return it
              if (proofValue.startsWith('http')) {
                return proofValue;
              }
              // If it's a relative path, make it absolute
              else if (proofValue.startsWith('/')) {
                return '${AppConfig.apiBaseUrl}$proofValue';
              }
              // If it's a token or filename, construct download URL
              else {
                return '${AppConfig.apiBaseUrl}/api/v1/ecommerce/download/$proofValue';
              }
            }
          }
        }
      }

      throw Exception('No proof file information found in order details');
    } catch (e) {
      rethrow;
    }
  }

  // Get order details including payment_proof information
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final response = await get('/api/v1/ecommerce/orders/$orderId');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Test method to check if upload proof endpoint exists
  Future<bool> testUploadProofEndpoint(int orderId) async {
    try {
      final response = await getOrderDetails(orderId);
      return response['data'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Download invoice PDF directly from API (Enhanced)
  Future<Uint8List?> downloadInvoicePdf(int orderId, {String type = 'download'}) async {
    try {

      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication required - please log in');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ecommerce/orders/$orderId/invoice?format=pdf&type=$type'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 MartFury-App/1.0',
          if (AppConfig.apiKey.isNotEmpty) 'X-API-KEY': AppConfig.apiKey,
        },
      );


      if (response.statusCode == 200) {
        // Verify it's actually PDF content
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/pdf')) {
          return response.bodyBytes;
        } else {
          // Still return the bytes, might be PDF without proper headers
          return response.bodyBytes;
        }
      } else if (response.statusCode == 404) {
        throw Exception('Invoice not found or not available for this order');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - please check your login status');
      } else {
        throw Exception('Failed to download invoice: HTTP ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Save PDF bytes to local file
  Future<File> savePdfToFile(Uint8List pdfBytes, int orderId, {String prefix = 'invoice'}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/$prefix-$orderId-$timestamp.pdf');
      
      // Ensure the file is written completely
      await file.writeAsBytes(pdfBytes, flush: true);
      
      // Verify the file was written correctly
      final writtenBytes = await file.readAsBytes();
      if (writtenBytes.length != pdfBytes.length) {
        throw Exception('File write verification failed');
      }
      
      return file;
    } catch (e) {
      rethrow;
    }
  }

  /// Stream PDF invoice directly from API
  Future<Stream<List<int>>> streamInvoicePdf(int orderId, {String type = 'print'}) async {
    try {

      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication required - please log in');
      }

      final request = http.Request(
        'GET',
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ecommerce/orders/$orderId/invoice?format=pdf&type=$type'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/pdf',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 MartFury-App/1.0',
        if (AppConfig.apiKey.isNotEmpty) 'X-API-KEY': AppConfig.apiKey,
      });

      final streamedResponse = await request.send();


      if (streamedResponse.statusCode == 200) {
        return streamedResponse.stream;
      } else if (streamedResponse.statusCode == 404) {
        throw Exception('Invoice not found or not available for this order');
      } else if (streamedResponse.statusCode == 401) {
        throw Exception('Unauthorized - please check your login status');
      } else {
        throw Exception('Failed to stream invoice: HTTP ${streamedResponse.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get PDF invoice URL for external download
  Future<String> getInvoicePdfUrl(int orderId, {String type = 'download'}) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication required - please log in');
      }

      // Request the invoice URL from the API (format=url)
      final response = await get('/api/v1/ecommerce/orders/$orderId/invoice?format=url&type=$type');

      if (response is Map<String, dynamic> && response['data'] != null && response['data']['url'] != null) {
        String invoiceUrl = response['data']['url'];
        
        // Make URL absolute if it's relative
        if (invoiceUrl.startsWith('/')) {
          invoiceUrl = '${AppConfig.apiBaseUrl}$invoiceUrl';
        }
        
        return invoiceUrl;
      } else {
        throw Exception('Invoice URL not available');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Stream payment proof file directly from API
  Future<Stream<List<int>>> streamPaymentProof(int orderId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication required - please log in');
      }

      final request = http.Request(
        'GET',
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ecommerce/orders/$orderId/download-proof?format=stream'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/octet-stream, application/pdf, image/jpeg, image/png',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 MartFury-App/1.0',
        if (AppConfig.apiKey.isNotEmpty) 'X-API-KEY': AppConfig.apiKey,
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        return streamedResponse.stream;
      } else if (streamedResponse.statusCode == 404) {
        throw Exception('Payment proof not found for this order');
      } else if (streamedResponse.statusCode == 401) {
        throw Exception('Unauthorized - please check your login status');
      } else {
        throw Exception('Failed to stream payment proof: HTTP ${streamedResponse.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if invoice is available
  Future<bool> isInvoiceAvailable(int orderId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) return false;

      // Test invoice availability
      final response = await http.head(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ecommerce/orders/$orderId/invoice?format=pdf&type=print'),
        headers: {
          'Authorization': 'Bearer $token',
          if (AppConfig.apiKey.isNotEmpty) 'X-API-KEY': AppConfig.apiKey,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check if PDF invoice is supported for this order
  Future<bool> supportsInvoicePdf(int orderId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) return false;

      // Test PDF invoice availability
      final response = await http.head(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ecommerce/orders/$orderId/invoice?format=pdf&type=print'),
        headers: {
          'Authorization': 'Bearer $token',
          if (AppConfig.apiKey.isNotEmpty) 'X-API-KEY': AppConfig.apiKey,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get invoice URL for WebView display
  Future<String?> getInvoiceUrl(int orderId, {String type = 'print', String? format}) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication required - please log in');
      }

      // Construct authenticated URL
      final queryParams = <String, String>{
        'type': type,
        'token': token,
      };

      if (format != null) {
        queryParams['format'] = format;
      }

      if (AppConfig.apiKey.isNotEmpty) {
        queryParams['api_key'] = AppConfig.apiKey;
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ecommerce/orders/$orderId/invoice')
          .replace(queryParameters: queryParams);

      return uri.toString();
    } catch (e) {
      return null;
    }
  }

  /// Get invoice URL with authentication headers
  Future<Map<String, String>> getInvoiceUrlWithHeaders(int orderId, {String type = 'print', String? format}) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication required - please log in');
      }

      // Construct URL without token in query params
      final queryParams = <String, String>{
        'type': type,
      };

      if (format != null) {
        queryParams['format'] = format;
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ecommerce/orders/$orderId/invoice')
          .replace(queryParameters: queryParams);

      // Return URL with headers
      final result = <String, String>{
        'url': uri.toString(),
        'Authorization': 'Bearer $token',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 MartFury-App/1.0',
      };

      if (AppConfig.apiKey.isNotEmpty) {
        result['X-API-KEY'] = AppConfig.apiKey;
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

}
