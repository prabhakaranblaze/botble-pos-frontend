import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:martfury/src/service/base_service.dart';
import 'package:martfury/core/app_config.dart';

class WishlistService extends BaseService {
  static const String _wishlistIdKey = 'wishlist_id';
  static const String _lastApiUrlKey = 'wishlist_last_api_url';

  static final StreamController<int> _wishlistCountController =
      StreamController<int>.broadcast();
  static Stream<int> get wishlistCountStream => _wishlistCountController.stream;

  static Future<String?> getWishlistId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_wishlistIdKey);
  }

  static Future<void> saveWishlistId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wishlistIdKey, id);
    _wishlistCountController.add(await getWishlistCount());
  }

  static Future<void> clearWishlistId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wishlistIdKey);
    _wishlistCountController.add(0);
  }

  // Check if API URL has changed and clear wishlist if needed
  static Future<void> checkAndClearWishlistOnApiChange() async {
    final prefs = await SharedPreferences.getInstance();
    final lastApiUrl = prefs.getString(_lastApiUrlKey);
    final currentApiUrl = AppConfig.apiBaseUrl;
    
    if (lastApiUrl != null && lastApiUrl != currentApiUrl) {
      // API URL has changed, clear wishlist data
      await clearWishlistId();
    }
    
    // Save current API URL
    await prefs.setString(_lastApiUrlKey, currentApiUrl);
  }

  // Clear all wishlist data
  static Future<void> clearAllWishlistData() async {
    await clearWishlistId();
  }

  Future<Map<String, dynamic>> createWishlist(String productId) async {
    try {
      final wishlistId = await getWishlistId();
      final url =
          wishlistId == null
              ? '/api/v1/ecommerce/wishlist'
              : '/api/v1/ecommerce/wishlist/$wishlistId';

      final response = await post(url, {'product_id': productId});

      await saveWishlistId(response['id'].toString());

      return response;
    } catch (e) {
      throw Exception('Failed to create wishlist: $e');
    }
  }

  Future<Map<String, dynamic>> removeFromWishlist(String productId) async {
    try {
      final wishlistId = await getWishlistId();
      final url = '/api/v1/ecommerce/wishlist/$wishlistId';

      final response = await delete(url, {'product_id': productId});

      await saveWishlistId(response['id'].toString());

      return response;
    } catch (e) {
      throw Exception('Failed to remove from wishlist: $e');
    }
  }

  Future<Map<String, dynamic>> getWishlist() async {
    try {
      final wishlistId = await getWishlistId();

      final response = await get('/api/v1/ecommerce/wishlist/$wishlistId');

      return response['data'];
    } catch (e) {
      // Check if it's a 404 error (wishlist not found)
      if (e.toString().contains('Not Found') || e.toString().contains('404')) {
        // Clear the invalid wishlist ID
        await clearWishlistId();
        // Return empty wishlist data
        return {'items': []};
      }
      throw Exception('Failed to get wishlist: $e');
    }
  }

  static Future<int> getWishlistCount() async {
    try {
      final wishlistId = await getWishlistId();

      if (wishlistId == null) {
        return 0;
      }
      final response = await BaseService().get(
        '/api/v1/ecommerce/wishlist/$wishlistId',
      );
      if (response['data'] != null && response['data']['items'] != null) {
        final items = response['data']['items'];
        if (items is Map) {
          return items.length;
        } else if (items is List) {
          return items.length;
        }
      }
      return 0;
    } catch (e) {
      // Check if it's a 404 error (wishlist not found)
      if (e.toString().contains('Not Found') || e.toString().contains('404')) {
        // Clear the invalid wishlist ID
        await clearWishlistId();
      }
      return 0;
    }
  }
}
