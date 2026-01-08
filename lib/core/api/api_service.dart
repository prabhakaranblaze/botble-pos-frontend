import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart'; // ← ADD THIS
import 'package:cookie_jar/cookie_jar.dart'; // ← ADD THIS
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../shared/constants/app_constants.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';
import '../models/session.dart';
import '../database/database_service.dart';
import '../services/storage_service.dart';

class ApiService {
  late final Dio _dio;
  final DatabaseService _db;
  final StorageService _storage;
  final CookieJar _cookieJar = CookieJar(); // ← ADD THIS
  bool _isOnline = true;

  ApiService(this._db, this._storage) {
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

    _dio.interceptors.add(CookieManager(_cookieJar));
    debugPrint('🍪 API SERVICE: Cookie manager added');

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

        // 🍪 ADD THIS: Check cookies being sent
        try {
          final cookies = await _cookieJar.loadForRequest(options.uri);
          if (cookies.isNotEmpty) {
            debugPrint('🍪 SENDING ${cookies.length} COOKIE(S):');
            for (var cookie in cookies) {
              debugPrint(
                  '  🍪 ${cookie.name} = ${cookie.value.substring(0, 20)}...');
            }
          } else {
            debugPrint('🍪 NO COOKIES TO SEND');
          }
        } catch (e) {
          debugPrint('⚠️ Cookie check error: $e');
        }

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
        return handler.next(error);
      },
    ));

    // Check connectivity
    Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      debugPrint('🌐 API SERVICE: Connectivity changed - Online: $_isOnline');
      if (_isOnline) {
        _syncPendingData();
      }
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
      await _cookieJar.deleteAll(); // ← Cookies cleared here
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

    try {
      if (!_isOnline) {
        debugPrint('⚠️ API SERVICE: Offline, loading from database');
        return await _db.getProducts(
            search: search, limit: AppConstants.itemsPerPage);
      }

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

        // Save to local database
        await _db.saveProducts(products);
        debugPrint('✅ API SERVICE: Products saved to database');

        return products;
      } else {
        debugPrint(
            '❌ API SERVICE: Error in response - ${response.data['message']}');
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: getProducts error: $e');
      debugPrint('❌ API SERVICE: Attempting to load from database');

      // If online request fails, try local database
      return await _db.getProducts(
          search: search, limit: AppConstants.itemsPerPage);
    }
  }

  Future<Product?> scanBarcode(String barcode) async {
    debugPrint('📷 API SERVICE: scanBarcode called - Barcode: "$barcode"');

    try {
      if (!_isOnline) {
        debugPrint('⚠️ API SERVICE: Offline, searching database');
        return await _db.getProductByBarcode(barcode);
      }

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
      return await _db.getProductByBarcode(barcode);
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

    try {
      if (!_isOnline) {
        debugPrint('❌ API SERVICE: Cannot checkout while offline');
        throw Exception('Cannot checkout while offline');
      }

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

  // Sync pending data when back online
  Future<void> _syncPendingData() async {
    debugPrint('🔄 API SERVICE: _syncPendingData called');

    try {
      final pendingOrders = await _db.getPendingOrders();
      debugPrint('🔄 API SERVICE: Pending orders: ${pendingOrders.length}');

      for (var order in pendingOrders) {
        try {
          await _dio.post('/orders', data: order);
          await _db.markOrderAsSynced(order['id'] as int);
          debugPrint('✅ API SERVICE: Order synced - ID: ${order['id']}');
        } catch (e) {
          debugPrint('⚠️ API SERVICE: Failed to sync order ${order['id']}: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('❌ API SERVICE: _syncPendingData error: $e');
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

      return {'orders': [], 'summary': {}};
    } catch (e) {
      debugPrint('❌ API SERVICE: getOrdersReport error: $e');
      return {'orders': [], 'summary': {}};
    }
  }

  /// Get products sold report with date filtering
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

      return {'products': [], 'summary': {}};
    } catch (e) {
      debugPrint('❌ API SERVICE: getProductsReport error: $e');
      return {'products': [], 'summary': {}};
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
}
