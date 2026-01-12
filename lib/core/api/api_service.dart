import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../shared/constants/app_constants.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';
import '../models/session.dart';
import '../services/storage_service.dart';

// Conditional imports for cookie manager (desktop only)
import 'api_cookie_stub.dart'
    if (dart.library.io) 'api_cookie_io.dart' as cookie_helper;

class ApiService {
  late final Dio _dio;
  final StorageService _storage;
  bool _isOnline = true;

  /// Callback triggered on 401 Unauthorized errors
  /// Used to trigger automatic logout when token is invalid
  void Function()? onUnauthorized;

  /// Callback triggered when offline - UI should show toast
  void Function(String message)? onOffline;

  ApiService(this._storage) {
    debugPrint('🟢 API SERVICE: Constructor called');

    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-API-KEY': AppConstants.apiKey,
      },
    ));

    // Add cookie manager only on desktop (not supported on web)
    cookie_helper.addCookieManager(_dio);

    debugPrint('🟢 API SERVICE: Base URL: ${AppConstants.baseUrl}');

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          debugPrint('🔑 API SERVICE: Token added to request');
        }

        debugPrint('📤 API REQUEST: ${options.method} ${options.uri}');
        if (options.data != null) {
          debugPrint('📤 API REQUEST DATA: ${options.data}');
        }

        // Log cookies (desktop only)
        await cookie_helper.logCookies(options.uri);

        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
            '📥 API RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
        debugPrint('📥 API RESPONSE DATA: ${response.data}');

        // 🍪 ADD THIS: Check cookies received
        final setCookies = response.headers['set-cookie'];
        if (setCookies != null && setCookies.isNotEmpty) {
          debugPrint('🍪 RECEIVED ${setCookies.length} COOKIE(S):');
          for (var cookie in setCookies) {
            // Show first 50 chars of each cookie
            final preview =
                cookie.length > 50 ? '${cookie.substring(0, 50)}...' : cookie;
            debugPrint('  🍪 $preview');
          }
        } else {
          debugPrint('🍪 NO COOKIES RECEIVED');
        }

        return handler.next(response);
      },
      onError: (error, handler) async {
        debugPrint('❌ API ERROR: ${error.type}');
        debugPrint('❌ API ERROR: ${error.message}');
        debugPrint('❌ API ERROR RESPONSE: ${error.response?.data}');

        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError) {
          _isOnline = false;
        }

        // Handle 401 Unauthorized - trigger automatic logout
        // Skip for logout endpoint to prevent infinite loop
        final isLogoutRequest = error.requestOptions.path.contains('/auth/logout');
        if (error.response?.statusCode == 401 && !isLogoutRequest) {
          debugPrint('🔐 API ERROR: 401 Unauthorized - triggering auto-logout');
          // Clear token immediately to prevent further 401 loops
          await _storage.removeToken();
          // Trigger the unauthorized callback (will call AuthProvider.logout)
          onUnauthorized?.call();
        }

        return handler.next(error);
      },
    ));

    // Check connectivity
    Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      debugPrint('🌐 API SERVICE: Connectivity changed - Online: $_isOnline');
    });
  }

  bool get isOnline => _isOnline;

  // Auth APIs
  Future<AuthResponse> login(
      String username, String password, String deviceName) async {
    debugPrint('🔐 API SERVICE: login called');

    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
        'device_name': deviceName,
      });

      if (response.data['error'] == false) {
        debugPrint('✅ API SERVICE: Login successful');
        return AuthResponse.fromJson(response.data['data']);
      } else {
        debugPrint('❌ API SERVICE: Login failed - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: Login exception: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<User> getCurrentUser() async {
    debugPrint('👤 API SERVICE: getCurrentUser called');

    try {
      final response = await _dio.get('/auth/me');
      debugPrint('✅ API SERVICE: User retrieved');
      return User.fromJson(response.data['data']['user']);
    } catch (e) {
      debugPrint('❌ API SERVICE: Get user failed: $e');
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore errors
    } finally {
      await cookie_helper.clearCookies();
    }
  }

  /// Verify password for lock screen unlock
  Future<bool> verifyPassword(String password) async {
    try {
      final response = await _dio.post('/auth/verify-password', data: {
        'password': password,
      });
      return response.data['error'] == false;
    } catch (e) {
      debugPrint('❌ API SERVICE: Verify password failed: $e');
      return false;
    }
  }

  // Product APIs
  Future<List<Product>> getProducts({int page = 1, String? search}) async {
    debugPrint(
        '📦 API SERVICE: getProducts called - Page: $page, Search: "$search"');
    debugPrint('📦 API SERVICE: Online: $_isOnline');

    if (!_isOnline) {
      debugPrint('⚠️ API SERVICE: Offline, cannot load products');
      onOffline?.call('You are offline. Please check your connection.');
      return [];
    }

    try {
      final response = await _dio.get('/products', queryParameters: {
        'page': page,
        'per_page': AppConstants.itemsPerPage,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      debugPrint(
          '📦 API SERVICE: Response received - Status: ${response.statusCode}');

      if (response.data['error'] == false) {
        final productsData = response.data['data']['products'] as List;
        debugPrint('📦 API SERVICE: Products count: ${productsData.length}');

        if (productsData.isNotEmpty) {
          debugPrint(
              '📦 API SERVICE: First product data: ${productsData.first}');
        }

        final products =
            productsData.map((json) => Product.fromJson(json)).toList();

        debugPrint('✅ API SERVICE: Products parsed successfully');
        return products;
      } else {
        debugPrint(
            '❌ API SERVICE: Error in response - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: getProducts error: $e');
      rethrow;
    }
  }

  Future<Product?> scanBarcode(String barcode) async {
    debugPrint('📷 API SERVICE: scanBarcode called - Barcode: "$barcode"');

    if (!_isOnline) {
      debugPrint('⚠️ API SERVICE: Offline, cannot scan barcode');
      onOffline?.call('You are offline. Please check your connection.');
      return null;
    }

    try {
      final response = await _dio.post('/products/scan-barcode', data: {
        'barcode': barcode,
      });

      if (response.data['error'] == false &&
          response.data['data']['product'] != null) {
        debugPrint('✅ API SERVICE: Product found by barcode');
        return Product.fromJson(response.data['data']['product']);
      }

      debugPrint('⚠️ API SERVICE: Product not found');
      return null;
    } catch (e) {
      debugPrint('❌ API SERVICE: Barcode scan error: $e');
      return null;
    }
  }

  /// Get single product with full variant details
  Future<Product?> getProductDetails(int productId) async {
    debugPrint('📦 API SERVICE: getProductDetails called - ID: $productId');

    try {
      final response = await _dio.get('/products/$productId');

      if (response.data['error'] == false) {
        final productData = response.data['data']['product'];
        debugPrint('📦 API SERVICE: Product details: $productData');
        return Product.fromJson(productData);
      }

      debugPrint('⚠️ API SERVICE: Product not found');
      return null;
    } catch (e) {
      debugPrint('❌ API SERVICE: getProductDetails error: $e');
      return null;
    }
  }

  Future<List<ProductCategory>> getCategories() async {
    debugPrint('📂 API SERVICE: getCategories called');

    try {
      final response = await _dio.get('/products/categories');

      if (response.data['error'] == false) {
        final categories = (response.data['data']['categories'] as List)
            .map((json) => ProductCategory.fromJson(json))
            .toList();

        debugPrint(
            '✅ API SERVICE: Categories loaded - Count: ${categories.length}');
        return categories;
      }

      return [];
    } catch (e) {
      debugPrint('❌ API SERVICE: Get categories error: $e');
      return [];
    }
  }

  // Cart APIs
  Future<Cart> addToCart(
    int productId, {
    int quantity = 1,
    Map<int, int>? variants,
  }) async {
    debugPrint('🛒 API SERVICE: addToCart called');
    debugPrint('🛒 API SERVICE: Product ID: $productId');
    debugPrint('🛒 API SERVICE: Quantity: $quantity');
    debugPrint('🛒 API SERVICE: Variants: $variants');

    try {
      final requestData = {
        'product_id': productId, // ✅ Changed from 'id' to 'product_id'
        'quantity': quantity, // ✅ Changed from 'qty' to 'quantity'
        if (variants != null)
          'attributes': variants, // ✅ Changed from 'variants' to 'attributes'
      };

      debugPrint('🛒 API SERVICE: Request data: $requestData');

      final response = await _dio.post('/cart/add', data: requestData);

      debugPrint(
          '🛒 API SERVICE: Response received - Status: ${response.statusCode}');
      debugPrint('🛒 API SERVICE: Response data: ${response.data}');

      if (response.data['error'] == false) {
        debugPrint('🛒 API SERVICE: Parsing cart from response...');

        final cartData = response.data['data'];
        debugPrint('🛒 API SERVICE: Cart data: $cartData');

        final cart = Cart.fromJson(cartData);

        debugPrint(
            '✅ API SERVICE: Cart parsed - Items: ${cart.items.length}, Total: ${cart.total}');

        if (cart.items.isNotEmpty) {
          debugPrint(
              '✅ API SERVICE: First cart item: ${cart.items.first.name} (qty: ${cart.items.first.quantity})');
        }

        return cart;
      } else {
        debugPrint(
            '❌ API SERVICE: Error response - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: addToCart error: $e');
      debugPrint('❌ API SERVICE: Error type: ${e.runtimeType}');

      if (e is DioException) {
        debugPrint(
            '❌ API SERVICE: DioException - Response: ${e.response?.data}');
      }

      throw Exception('Failed to add to cart: ${e.toString()}');
    }
  }

  Future<Cart> updateCart(int productId, int quantity) async {
    debugPrint(
        '🔄 API SERVICE: updateCart called - ID: $productId, Qty: $quantity');

    try {
      final response = await _dio.post('/cart/update', data: {
        'product_id': productId,
        'quantity': quantity,
      });

      if (response.data['error'] == false) {
        final cart = Cart.fromJson(response.data['data']);
        debugPrint('✅ API SERVICE: Cart updated - Items: ${cart.items.length}');
        return cart;
      } else {
        debugPrint(
            '❌ API SERVICE: Update cart error - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: updateCart exception: $e');
      throw Exception('Failed to update cart: ${e.toString()}');
    }
  }

  Future<Cart> removeFromCart(int productId) async {
    debugPrint('🗑️ API SERVICE: removeFromCart called - ID: $productId');

    try {
      final response = await _dio.post('/cart/remove', data: {
        'product_id': productId,
      });

      if (response.data['error'] == false) {
        final cart = Cart.fromJson(response.data['data']);
        debugPrint('✅ API SERVICE: Item removed - Items: ${cart.items.length}');
        return cart;
      } else {
        debugPrint('❌ API SERVICE: Remove error - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: removeFromCart exception: $e');
      throw Exception('Failed to remove from cart: ${e.toString()}');
    }
  }

  Future<void> clearCart() async {
    debugPrint('🗑️ API SERVICE: clearCart called');

    try {
      await _dio.post('/cart/clear');
      debugPrint('✅ API SERVICE: Cart cleared');
    } catch (e) {
      debugPrint('❌ API SERVICE: clearCart error: $e');
      throw Exception('Failed to clear cart: ${e.toString()}');
    }
  }

  Future<Cart> updatePaymentMethod(String method) async {
    debugPrint('💳 API SERVICE: updatePaymentMethod called - Method: $method');

    try {
      final response = await _dio.post('/cart/update-payment-method', data: {
        'payment_method': method,
      });

      if (response.data['error'] == false) {
        debugPrint('✅ API SERVICE: Payment method updated');
        return Cart.fromJson(response.data['data']);
      } else {
        debugPrint(
            '❌ API SERVICE: Update payment error - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: updatePaymentMethod exception: $e');
      throw Exception('Failed to update payment method: ${e.toString()}');
    }
  }

  // Customer APIs
  Future<List<Customer>> searchCustomers(String query) async {
    debugPrint('👥 API SERVICE: searchCustomers called - Query: "$query"');

    try {
      final response = await _dio.get('/customers/search', queryParameters: {
        'keyword': query,
      });

      if (response.data['error'] == false) {
        final customers = (response.data['data']['customers'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();

        debugPrint(
            '✅ API SERVICE: Customers found - Count: ${customers.length}');
        return customers;
      }

      return [];
    } catch (e) {
      debugPrint('❌ API SERVICE: searchCustomers error: $e');
      return [];
    }
  }

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    debugPrint('👤 API SERVICE: createCustomer called');

    try {
      final response = await _dio.post('/customers', data: data);

      if (response.data['error'] == false) {
        debugPrint('✅ API SERVICE: Customer created');
        return Customer.fromJson(response.data['data']['customer']);
      } else {
        debugPrint(
            '❌ API SERVICE: Create customer error - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: createCustomer exception: $e');
      throw Exception('Failed to create customer: ${e.toString()}');
    }
  }

  Future<List<CustomerAddress>> getCustomerAddresses(int customerId) async {
    debugPrint('📍 API SERVICE: getCustomerAddresses for customer $customerId');
    try {
      final response = await _dio.get('/customers/$customerId/addresses');
      if (response.data['error'] == false) {
        final addresses = (response.data['data']['addresses'] as List)
            .map((json) => CustomerAddress.fromJson(json))
            .toList();
        debugPrint('✅ API SERVICE: Found ${addresses.length} addresses');
        return addresses;
      } else {
        debugPrint('❌ API SERVICE: Error getting addresses');
        return [];
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: getCustomerAddresses error: $e');
      return [];
    }
  }

  Future<CustomerAddress> createCustomerAddress(int customerId, Map<String, dynamic> data) async {
    debugPrint('📍 API SERVICE: createCustomerAddress for customer $customerId');
    try {
      final response = await _dio.post('/customers/$customerId/addresses', data: data);
      if (response.data['error'] == false) {
        final address = CustomerAddress.fromJson(response.data['data']['address']);
        debugPrint('✅ API SERVICE: Created address ${address.id}');
        return address;
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: createCustomerAddress error: $e');
      throw Exception('Failed to create address: ${e.toString()}');
    }
  }

  // Order APIs
  /// Checkout with cart items sent directly (no server-side cart sync)
  Future<Order> checkoutDirect({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? paymentDetails,
    Map<String, dynamic>? paymentMetadata,
    int? customerId,
    // Discount parameters
    int? discountId,
    String? couponCode,
    double discountAmount = 0,
    String? discountDescription,
    // Shipping
    double shippingAmount = 0,
    String deliveryType = 'pickup', // 'pickup' or 'ship'
    // Tax
    double? taxAmount,
    // Customer info for invoice
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    // Address info (for delivery_type = 'ship')
    int? addressId,
    String? customerAddress,
  }) async {
    debugPrint('💳 API SERVICE: ========== CHECKOUT DIRECT ==========');
    debugPrint('💳 API SERVICE: Items: ${items.length}');
    debugPrint('💳 API SERVICE: Payment method: $paymentMethod');
    debugPrint('💳 API SERVICE: Tax amount: $taxAmount');
    debugPrint('💳 API SERVICE: Discount amount: $discountAmount (coupon: $couponCode)');
    debugPrint('💳 API SERVICE: Shipping amount: $shippingAmount');
    debugPrint('💳 API SERVICE: Delivery type: $deliveryType');
    debugPrint('💳 API SERVICE: Customer ID: $customerId');
    debugPrint('💳 API SERVICE: Address ID: $addressId');

    if (!_isOnline) {
      debugPrint('❌ API SERVICE: Cannot checkout while offline');
      onOffline?.call('You are offline. Cannot complete checkout.');
      throw Exception('Cannot checkout while offline');
    }

    try {

      // Build request data explicitly to debug what's being sent
      final requestData = {
        'items': items,
        'payment_method': paymentMethod,
        // Always send tax, discount, shipping (even if 0) so backend gets explicit values
        'tax_amount': taxAmount ?? 0,
        'discount_amount': discountAmount,
        'shipping_amount': shippingAmount,
        'delivery_type': deliveryType,
      };

      // Add optional fields
      if (paymentDetails != null) requestData['payment_details'] = paymentDetails;
      if (paymentMetadata != null) requestData['payment_metadata'] = paymentMetadata;
      if (customerId != null) requestData['customer_id'] = customerId;
      if (discountId != null) requestData['discount_id'] = discountId;
      if (couponCode != null) requestData['coupon_code'] = couponCode;
      if (discountDescription != null) requestData['discount_description'] = discountDescription;
      if (customerName != null) requestData['customer_name'] = customerName;
      if (customerEmail != null) requestData['customer_email'] = customerEmail;
      if (customerPhone != null) requestData['customer_phone'] = customerPhone;
      if (addressId != null) requestData['address_id'] = addressId;
      if (customerAddress != null) requestData['customer_address'] = customerAddress;

      debugPrint('💳 API SERVICE: Request data: $requestData');
      debugPrint('💳 API SERVICE: Request data (tax_amount): ${requestData['tax_amount']}');
      debugPrint('💳 API SERVICE: Request data (discount_amount): ${requestData['discount_amount']}');
      debugPrint('💳 API SERVICE: Request data (shipping_amount): ${requestData['shipping_amount']}');

      final response = await _dio.post('/orders', data: requestData);

      if (response.data['error'] == false) {
        final order = Order.fromJson(response.data['data']['order']);
        debugPrint(
            '✅ API SERVICE: Order created - ID: ${order.id}, Code: ${order.code}');
        return order;
      } else {
        debugPrint(
            '❌ API SERVICE: Checkout error - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: checkoutDirect exception: $e');
      throw Exception('Checkout failed: ${e.toString()}');
    }
  }

  /// @deprecated Use checkoutDirect instead
  Future<Order> checkout({String? paymentDetails}) async {
    debugPrint('💳 API SERVICE: checkout called (deprecated)');
    throw Exception('Use checkoutDirect instead');
  }

  /// Checkout via Laravel API (proxied through Node.js)
  /// This uses Laravel's order processing with POS_API_TOKEN authentication
  Future<Order> checkoutViaLaravel({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required double subtotal,
    required double total,
    double taxAmount = 0,
    List<Map<String, dynamic>>? taxDetails,
    double discountAmount = 0,
    double shippingAmount = 0,
    String? couponCode,
    int? customerId,
    Map<String, dynamic>? customer,
    Map<String, dynamic>? address,
    String deliveryOption = 'pickup',
    String? notes,
    double? cashReceived,
  }) async {
    debugPrint('💳 API SERVICE: ========== CHECKOUT VIA LARAVEL ==========');
    debugPrint('💳 API SERVICE: Items: ${items.length}');
    debugPrint('💳 API SERVICE: Payment method: $paymentMethod');
    debugPrint('💳 API SERVICE: Subtotal: $subtotal, Tax: $taxAmount, Total: $total');

    if (!_isOnline) {
      debugPrint('❌ API SERVICE: Cannot checkout while offline');
      onOffline?.call('You are offline. Cannot complete checkout.');
      throw Exception('Cannot checkout while offline');
    }

    try {
      // Build Laravel-compatible cart payload
      final cartPayload = {
        'items': items.map((item) => {
          'id': item['product_id'] ?? item['id'],
          'name': item['name'],
          'sku': item['sku'],
          'image': item['image'],
          'price': item['price'],
          'quantity': item['quantity'],
          'tax_rate': item['tax_rate'] ?? 0,
          'attributes': item['attributes'] ?? item['options'],
          'image_url': item['image_url'],
        }).toList(),
        'subtotal': subtotal,
        'subtotal_formatted': '',
        'coupon_code': couponCode,
        'coupon_discount': 0,
        'coupon_discount_formatted': '',
        'coupon_discount_type': null,
        'manual_discount': discountAmount,
        'manual_discount_value': discountAmount,
        'manual_discount_type': 'fixed',
        'manual_discount_formatted': '',
        'manual_discount_description': '',
        'tax': taxAmount,
        'tax_formatted': '',
        'tax_details': taxDetails ?? [],
        'shipping_amount': shippingAmount,
        'shipping_amount_formatted': '',
        'total': total,
        'total_formatted': '',
        'count': items.length,
        'customer_id': customerId,
        'customer': customer,
        'payment_method': paymentMethod,
        'payment_method_enum': paymentMethod == 'card' ? 'pos_card' : 'pos_cash',
      };

      final requestData = {
        'customer_id': customerId,
        'address': address ?? {
          'address_id': 'new',
          'name': 'Guest',
          'email': 'guest@example.com',
          'phone': 'N/A',
          'country': 'SC',
          'state': null,
          'city': null,
          'address': 'Pickup at Store',
          'zip_code': null,
        },
        'delivery_option': deliveryOption,
        'payment_method': paymentMethod,
        'notes': notes,
        'cash_received': cashReceived,
        'cart': cartPayload,
      };

      debugPrint('💳 API SERVICE: Sending to Laravel checkout: $requestData');

      final response = await _dio.post('/orders/laravel-checkout', data: requestData);

      if (response.data['error'] == false) {
        final order = Order.fromJson(response.data['data']['order']);
        debugPrint(
            '✅ API SERVICE: Laravel Order created - ID: ${order.id}, Code: ${order.code}');
        return order;
      } else {
        debugPrint(
            '❌ API SERVICE: Laravel Checkout error - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      debugPrint('❌ API SERVICE: checkoutViaLaravel DioException: $e');

      // Extract friendly error message
      String friendlyMessage = 'Checkout failed. Please try again.';

      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          // Try to get message from response
          if (data['message'] != null) {
            final message = data['message'].toString().toLowerCase();
            // Map common errors to friendly messages
            if (message.contains('token') || message.contains('unauthorized')) {
              friendlyMessage = 'Authentication error. Please log in again.';
            } else if (message.contains('network') || message.contains('connection')) {
              friendlyMessage = 'Network error. Please check your connection.';
            } else if (message.contains('timeout')) {
              friendlyMessage = 'Request timed out. Please try again.';
            } else if (message.contains('certificate')) {
              friendlyMessage = 'Server connection error. Please contact support.';
            } else {
              // Use the message if it's not too technical
              final msg = data['message'].toString();
              if (msg.length < 100 && !msg.contains('Exception') && !msg.contains('Error:')) {
                friendlyMessage = msg;
              }
            }
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        friendlyMessage = 'Connection timed out. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        friendlyMessage = 'Unable to connect to server. Please check your network.';
      }

      throw Exception(friendlyMessage);
    } catch (e) {
      debugPrint('❌ API SERVICE: checkoutViaLaravel exception: $e');
      throw Exception('Checkout failed. Please try again.');
    }
  }

  Future<String> getReceipt(int orderId) async {
    debugPrint('🧾 API SERVICE: getReceipt called - Order ID: $orderId');

    try {
      final response = await _dio.get('/orders/$orderId/receipt');
      debugPrint('✅ API SERVICE: Receipt retrieved');
      return response.data['data']['receipt_html'];
    } catch (e) {
      debugPrint('❌ API SERVICE: getReceipt error: $e');
      throw Exception('Failed to get receipt: ${e.toString()}');
    }
  }

  /// Get recent orders for reprinting
  Future<List<Order>> getRecentOrders({
    int limit = 100,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    debugPrint('📋 API SERVICE: getRecentOrders called - Limit: $limit, Search: $search');
    debugPrint('📋 API SERVICE: Date range: $fromDate to $toDate');

    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (fromDate != null) 'from_date': fromDate.toIso8601String().split('T')[0],
        if (toDate != null) 'to_date': toDate.toIso8601String().split('T')[0],
      };

      final response = await _dio.get('/orders', queryParameters: queryParams);

      if (response.data['error'] == false) {
        final ordersData = response.data['data']['orders'] as List;
        final orders = ordersData.map((json) => Order.fromJson(json)).toList();
        debugPrint('✅ API SERVICE: Recent orders loaded - Count: ${orders.length}');
        return orders;
      }

      return [];
    } catch (e) {
      debugPrint('❌ API SERVICE: getRecentOrders error: $e');
      return [];
    }
  }

  /// Get single order by ID
  Future<Order?> getOrderById(int orderId) async {
    debugPrint('📋 API SERVICE: getOrderById called - ID: $orderId');

    try {
      final response = await _dio.get('/orders/$orderId');

      if (response.data['error'] == false) {
        final order = Order.fromJson(response.data['data']['order']);
        debugPrint('✅ API SERVICE: Order loaded - Code: ${order.code}');
        return order;
      }

      return null;
    } catch (e) {
      debugPrint('❌ API SERVICE: getOrderById error: $e');
      return null;
    }
  }

  // Denomination APIs
  Future<List<Denomination>> getDenominations({String currency = 'USD'}) async {
    debugPrint('💵 API SERVICE: getDenominations called - Currency: $currency');

    try {
      final response = await _dio.get('/denominations', queryParameters: {
        'currency': currency,
      });

      if (response.data['error'] == false) {
        final denominations = (response.data['data']['denominations'] as List)
            .map((json) => Denomination.fromJson(json))
            .toList();

        debugPrint(
            '✅ API SERVICE: Denominations loaded - Count: ${denominations.length}');
        return denominations;
      }

      return [];
    } catch (e) {
      debugPrint('❌ API SERVICE: getDenominations error: $e');
      return [];
    }
  }

  // Session APIs
  Future<List<dynamic>> getCashRegisters() async {
    debugPrint('🏪 API SERVICE: getCashRegisters called');

    try {
      final response = await _dio.get('/cash-registers');

      if (response.data['error'] == false) {
        final registers =
            response.data['data']['cash_registers'] as List<dynamic>;
        debugPrint(
            '✅ API SERVICE: Cash registers loaded - Count: ${registers.length}');
        return registers;
      } else {
        debugPrint(
            '❌ API SERVICE: Get registers error - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: getCashRegisters exception: $e');
      throw Exception('Failed to get cash registers: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    debugPrint('📊 API SERVICE: getActiveSession called');

    try {
      final response = await _dio.get('/sessions/active');

      if (response.data['error'] == false) {
        final session =
            response.data['data']['session'] as Map<String, dynamic>;
        debugPrint(
            '✅ API SERVICE: Active session found - ID: ${session['id']}');
        return session;
      }

      debugPrint('⚠️ API SERVICE: No active session');
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        debugPrint('⚠️ API SERVICE: 404 - No active session (expected)');
        return null;
      }

      debugPrint('❌ API SERVICE: getActiveSession error: $e');
      throw Exception('Failed to get active session: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> openSession({
    required double openingCash,
    String? notes,
  }) async {
    debugPrint('📂 API SERVICE: openSession called');
    debugPrint('📂 API SERVICE: Opening cash: $openingCash');

    try {
      final response = await _dio.post('/sessions/open', data: {
        'opening_cash': openingCash,
        if (notes != null) 'opening_notes': notes,
      });

      if (response.data['error'] == false) {
        final session =
            response.data['data']['session'] as Map<String, dynamic>;
        debugPrint('✅ API SERVICE: Session opened - ID: ${session['id']}');
        return session;
      } else {
        debugPrint(
            '❌ API SERVICE: Open session error - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: openSession exception: $e');

      if (e is DioException && e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }

      throw Exception('Failed to open session: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> closeSession({
    required int sessionId,
    required double closingCash,
    Map<String, int>? denominations,
    String? notes,
  }) async {
    debugPrint('📂 API SERVICE: closeSession called');
    debugPrint('📂 API SERVICE: Session ID: $sessionId');
    debugPrint('📂 API SERVICE: Closing cash: $closingCash');

    try {
      final response = await _dio.post('/sessions/close', data: {
        'session_id': sessionId,
        'closing_cash': closingCash,
        if (denominations != null) 'closing_denominations': denominations,
        if (notes != null) 'closing_notes': notes,
      });

      if (response.data['error'] == false) {
        final session =
            response.data['data']['session'] as Map<String, dynamic>;
        debugPrint('✅ API SERVICE: Session closed - ID: ${session['id']}');
        return session;
      } else {
        debugPrint(
            '❌ API SERVICE: Close session error - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: closeSession exception: $e');
      throw Exception('Failed to close session: ${e.toString()}');
    }
  }

  // Settings APIs
  /// Get POS settings including currency
  Future<Map<String, dynamic>?> getSettings() async {
    debugPrint('⚙️ API SERVICE: getSettings called');

    try {
      final response = await _dio.get('/settings');

      if (response.data['error'] == false) {
        final settings = response.data['data']['settings'] as Map<String, dynamic>;
        debugPrint('✅ API SERVICE: Settings loaded');
        return settings;
      }

      return null;
    } catch (e) {
      debugPrint('❌ API SERVICE: getSettings error: $e');
      return null;
    }
  }

  // Discount APIs
  /// Validate a coupon code
  Future<Map<String, dynamic>?> validateCoupon({
    required String code,
    required double subtotal,
    required List<Map<String, dynamic>> items,
    int? customerId,
  }) async {
    debugPrint('🎟️ API SERVICE: validateCoupon called - Code: "$code"');
    debugPrint('🎟️ API SERVICE: Subtotal: $subtotal');
    debugPrint('🎟️ API SERVICE: Items: ${items.length}');

    try {
      final response = await _dio.post('/discounts/validate', data: {
        'code': code,
        'subtotal': subtotal,
        'items': items,
        if (customerId != null) 'customer_id': customerId,
      });

      if (response.data['error'] == false) {
        debugPrint('✅ API SERVICE: Coupon validated successfully');
        return response.data['data'] as Map<String, dynamic>;
      } else {
        debugPrint('❌ API SERVICE: Coupon validation failed - ${response.data['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: validateCoupon error: $e');
      if (e is DioException && e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      return null;
    }
  }

  // Reports APIs

  /// Get orders report with date filtering
  /// Backend endpoint: GET /reports/orders?from_date=YYYY-MM-DD&to_date=YYYY-MM-DD
  Future<Map<String, dynamic>> getOrdersReport({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    debugPrint('📊 API SERVICE: getOrdersReport called');
    debugPrint('📊 API SERVICE: Date range: $fromDate to $toDate');

    try {
      final queryParams = <String, dynamic>{
        if (fromDate != null) 'from_date': fromDate.toIso8601String().split('T')[0],
        if (toDate != null) 'to_date': toDate.toIso8601String().split('T')[0],
      };

      final response = await _dio.get('/reports/orders', queryParameters: queryParams);

      if (response.data['error'] == false) {
        debugPrint('✅ API SERVICE: Orders report loaded');
        return response.data['data'] as Map<String, dynamic>;
      }

      return {
        'orders': <Map<String, dynamic>>[],
        'summary': <String, dynamic>{},
      };
    } catch (e) {
      debugPrint('❌ API SERVICE: getOrdersReport error: $e');
      return {
        'orders': <Map<String, dynamic>>[],
        'summary': <String, dynamic>{},
      };
    }
  }

  /// Get products sold report with date filtering
  /// Backend endpoint: GET /reports/products?from_date=YYYY-MM-DD&to_date=YYYY-MM-DD&sort_by=quantity&sort_order=desc
  Future<Map<String, dynamic>> getProductsReport({
    DateTime? fromDate,
    DateTime? toDate,
    String? sortBy, // 'quantity', 'revenue', 'name'
    String? sortOrder, // 'asc', 'desc'
  }) async {
    debugPrint('📊 API SERVICE: getProductsReport called');
    debugPrint('📊 API SERVICE: Date range: $fromDate to $toDate');

    try {
      final queryParams = <String, dynamic>{
        if (fromDate != null) 'from_date': fromDate.toIso8601String().split('T')[0],
        if (toDate != null) 'to_date': toDate.toIso8601String().split('T')[0],
        if (sortBy != null) 'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
      };

      final response = await _dio.get('/reports/products', queryParameters: queryParams);

      if (response.data['error'] == false) {
        debugPrint('✅ API SERVICE: Products report loaded');
        return response.data['data'] as Map<String, dynamic>;
      }

      return {
        'products': <Map<String, dynamic>>[],
        'summary': <String, dynamic>{},
      };
    } catch (e) {
      debugPrint('❌ API SERVICE: getProductsReport error: $e');
      return {
        'products': <Map<String, dynamic>>[],
        'summary': <String, dynamic>{},
      };
    }
  }

  /// Calculate manual discount
  Future<Map<String, dynamic>?> calculateDiscount({
    required String type,
    required double value,
    required double subtotal,
  }) async {
    debugPrint('💰 API SERVICE: calculateDiscount called - Type: $type, Value: $value');

    try {
      final response = await _dio.post('/discounts/calculate', data: {
        'type': type,
        'value': value,
        'subtotal': subtotal,
      });

      if (response.data['error'] == false) {
        debugPrint('✅ API SERVICE: Discount calculated successfully');
        return response.data['data'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('❌ API SERVICE: calculateDiscount error: $e');
      return null;
    }
  }

  // Update APIs

  /// Check for app updates
  Future<Map<String, dynamic>?> checkForUpdate(String currentVersion) async {
    debugPrint('📦 API SERVICE: checkForUpdate called - Version: $currentVersion');

    try {
      final response = await _dio.post('/updates/check', data: {
        'version': currentVersion,
      });

      if (response.data['error'] == false) {
        debugPrint('✅ API SERVICE: Update check successful');
        return response.data['data'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('❌ API SERVICE: checkForUpdate error: $e');
      return null;
    }
  }
}
