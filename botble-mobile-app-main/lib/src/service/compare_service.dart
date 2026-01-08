import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:martfury/src/service/base_service.dart';
import 'package:martfury/core/app_config.dart';

class CompareService extends BaseService {
  static const String _compareIdKey = 'compare_id';
  static const String _lastApiUrlKey = 'compare_last_api_url';

  static final StreamController<int> _compareCountController =
      StreamController<int>.broadcast();
  static Stream<int> get compareCountStream => _compareCountController.stream;

  static Future<String?> getCompareId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_compareIdKey);
  }

  static Future<void> saveCompareId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_compareIdKey, id);
    _compareCountController.add(await getCompareCount());
  }

  static Future<void> clearCompareId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_compareIdKey);
    _compareCountController.add(0);
  }

  // Check if API URL has changed and clear compare if needed
  static Future<void> checkAndClearCompareOnApiChange() async {
    final prefs = await SharedPreferences.getInstance();
    final lastApiUrl = prefs.getString(_lastApiUrlKey);
    final currentApiUrl = AppConfig.apiBaseUrl;
    
    if (lastApiUrl != null && lastApiUrl != currentApiUrl) {
      // API URL has changed, clear compare data
      await clearCompareId();
    }
    
    // Save current API URL
    await prefs.setString(_lastApiUrlKey, currentApiUrl);
  }

  // Clear all compare data
  static Future<void> clearAllCompareData() async {
    await clearCompareId();
  }

  Future<Map<String, dynamic>> createCompare(String productId) async {
    try {
      final compareId = await getCompareId();
      final url =
          compareId == null
              ? '/api/v1/ecommerce/compare'
              : '/api/v1/ecommerce/compare/$compareId';

      final response = await post(url, {'product_id': productId});

      await saveCompareId(response['id'].toString());

      return response;
    } catch (e) {
      throw Exception('Failed to create compare: $e');
    }
  }

  Future<Map<String, dynamic>> removeFromCompare(String productId) async {
    try {
      final compareId = await getCompareId();
      final url = '/api/v1/ecommerce/compare/$compareId';

      final response = await delete(url, {'product_id': productId});

      await saveCompareId(response['id'].toString());

      return response;
    } catch (e) {
      throw Exception('Failed to remove from compare: $e');
    }
  }

  Future<Map<String, dynamic>> getCompare() async {
    try {
      final compareId = await getCompareId();

      if (compareId == null) {
        return {'data': []};
      }

      final response = await get('/api/v1/ecommerce/compare/$compareId');

      return response['data'];
    } catch (e) {
      // Check if it's a 404 error (compare not found)
      if (e.toString().contains('Not Found') || e.toString().contains('404')) {
        // Clear the invalid compare ID
        await clearCompareId();
        // Return empty compare data
        return {'data': []};
      }
      throw Exception('Failed to get compare: $e');
    }
  }

  static Future<int> getCompareCount() async {
    try {
      final compareId = await getCompareId();

      if (compareId == null) {
        return 0;
      }
      final response = await BaseService().get(
        '/api/v1/ecommerce/compare/$compareId',
      );
      if (response['data'] != null && response['data']['count'] != null) {
        return response['data']['count'];
      }
      return 0;
    } catch (e) {
      // Check if it's a 404 error (compare not found)
      if (e.toString().contains('Not Found') || e.toString().contains('404')) {
        // Clear the invalid compare ID
        await clearCompareId();
      }
      return 0;
    }
  }
}
