import 'dart:convert';
import 'package:martfury/src/service/base_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:martfury/core/app_config.dart';
import 'dart:async';

class CartService extends BaseService {
  static const String _cartIdKey = 'cart_id';
  static const String _cartProductsKey = 'cart_products';
  static const String _lastApiUrlKey = 'last_api_url';
  static const String _appliedCouponKey = 'applied_coupon';

  static final StreamController<int> _cartCountController =
      StreamController<int>.broadcast();
  static Stream<int> get cartCountStream => _cartCountController.stream;

  static Future<String?> getCartId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cartIdKey);
  }

  static Future<void> saveCartId(String cartId) async {
    if (cartId.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartIdKey, cartId);
  }

  static Future<void> clearCartId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartIdKey);
  }

  // Get list of product IDs in cart
  static Future<List<String>> getCartProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_cartProductsKey);

    if (productsJson == null) return [];

    try {
      final List<dynamic> products = jsonDecode(productsJson);
      return products.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  // Save list of product IDs to localStorage
  static Future<void> _saveCartProducts(List<String> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartProductsKey, jsonEncode(products));
    _cartCountController.add(products.length);
  }

  // Add product ID to cart if not exists
  static Future<void> addProductToCart(String productId) async {
    final products = await getCartProducts();
    if (!products.contains(productId)) {
      products.add(productId);
      await _saveCartProducts(products);
    }
  }

  // Remove product ID from cart
  static Future<void> removeProductFromCart(String productId) async {
    final products = await getCartProducts();
    products.remove(productId);
    await _saveCartProducts(products);
  }

  // Get number of unique products in cart
  static Future<int> getCartCount() async {
    final products = await getCartProducts();
    return products.length;
  }

  // Clear all products from cart
  static Future<void> clearCartProducts() async {
    await _saveCartProducts([]);
  }

  // Check if API URL has changed and clear cart if needed
  static Future<void> checkAndClearCartOnApiChange() async {
    final prefs = await SharedPreferences.getInstance();
    final lastApiUrl = prefs.getString(_lastApiUrlKey);
    final currentApiUrl = AppConfig.apiBaseUrl;

    if (lastApiUrl != null && lastApiUrl != currentApiUrl) {
      await clearCartId();
      await clearCartProducts();
    }

    await prefs.setString(_lastApiUrlKey, currentApiUrl);
  }

  // Save applied coupon code
  static Future<void> saveAppliedCoupon(String couponCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appliedCouponKey, couponCode);
  }

  // Get applied coupon code
  static Future<String?> getAppliedCoupon() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appliedCouponKey);
  }

  // Clear applied coupon
  static Future<void> clearAppliedCoupon() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appliedCouponKey);
  }

  // Clear all cart data
  static Future<void> clearAllCartData() async {
    await clearCartId();
    await clearCartProducts();
    _cartCountController.add(0);
  }

  Future<Map<String, dynamic>> getCartDetail(String cartId) async {
    try {
      final response = await get('/api/v1/ecommerce/cart/$cartId');

      return response;
    } catch (e) {
      if (e.toString().contains('Not Found') || e.toString().contains('404')) {
        await clearCartId();
        await clearCartProducts();
        throw Exception('Cart not found. Cart has been cleared.');
      }
      throw Exception('Failed to get cart details: $e');
    }
  }

  Future<Map<String, dynamic>> createCartItem({
    required String productId,
    required int quantity,
    bool skipCartCount = false,
  }) async {
    try {
      String? existingCartId = await getCartId();
      if (existingCartId != null) {
        return await addItemToExistingCart(
          cartId: existingCartId,
          productId: productId,
          quantity: quantity,
          skipCartCount: skipCartCount,
        );
      } else {
        return await _createNewCartWithItem(
          productId: productId,
          quantity: quantity,
          skipCartCount: skipCartCount,
        );
      }
    } catch (e) {
      throw Exception('Failed to create cart item: $e');
    }
  }

  Future<Map<String, dynamic>> _createNewCartWithItem({
    required String productId,
    required int quantity,
    bool skipCartCount = false,
  }) async {
    final response = await post('/api/v1/ecommerce/cart', {
      'product_id': productId,
      'qty': quantity,
    });

    final data = response;

    if (!skipCartCount) {
      String? cartId;

      if (data['id'] != null) {
        cartId = data['id'].toString();
      } else if (data['cart_id'] != null) {
        cartId = data['cart_id'].toString();
      } else if (data['data'] != null && data['data']['id'] != null) {
        cartId = data['data']['id'].toString();
      }

      if (cartId != null && cartId.isNotEmpty) {
        await saveCartId(cartId);
      }

      await addProductToCart(productId);
    }
    return data;
  }

  Future<Map<String, dynamic>> addItemToExistingCart({
    required String cartId,
    required String productId,
    required int quantity,
    bool skipCartCount = false,
  }) async {
    final response = await post('/api/v1/ecommerce/cart/$cartId', {
      'product_id': productId,
      'qty': quantity,
    });

    final data = response;

    if (!skipCartCount) {
      await addProductToCart(productId);
    }
    return data;
  }

  Future<void> removeCartItem({
    required String cartItemId,
    required String productId,
  }) async {
    try {
      await delete('/api/v1/ecommerce/cart/$cartItemId', {
        'product_id': productId,
      });

      await removeProductFromCart(productId);
    } catch (e) {
      throw 'Failed to remove item from cart: ${e.toString()}';
    }
  }

  Future<Map<String, dynamic>> updateCartItem({
    required String cartItemId,
    required String productId,
    required int quantity,
  }) async {
    try {
      final response = await put('/api/v1/ecommerce/cart/$cartItemId', {
        'product_id': productId,
        'qty': quantity,
      });

      final data = response;

      await addProductToCart(productId);
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> applyCoupon({
    required String couponCode,
    required String cartId,
  }) async {
    try {
      final response = await post('/api/v1/ecommerce/coupon/apply', {
        'coupon_code': couponCode,
        'cart_id': cartId,
      });

      final data = response;

      return data;
    } catch (e) {
      throw Exception('Failed to apply coupon: $e');
    }
  }

  Future<Map<String, dynamic>> removeCoupon({required String cartId}) async {
    try {
      final response = await post('/api/v1/ecommerce/coupon/remove', {
        'cart_id': cartId,
      });

      final data = response;

      return data;
    } catch (e) {
      throw Exception('Failed to remove coupon: $e');
    }
  }
}
