import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../shared/constants/app_constants.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../models/customer.dart';
import '../models/session.dart';
import '../database/database_service.dart';
import '../services/storage_service.dart';

class ApiService {
  late final Dio _dio;
  final DatabaseService _db;
  final StorageService _storage;
  bool _isOnline = true;

  ApiService(this._db, this._storage) {
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

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
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
      if (_isOnline) {
        _syncPendingData();
      }
    });
  }

  bool get isOnline => _isOnline;

  // Auth APIs
  Future<AuthResponse> login(
      String username, String password, String deviceName) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
        'device_name': deviceName,
      });

      if (response.data['error'] == false) {
        return AuthResponse.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return User.fromJson(response.data['data']['user']);
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore errors on logout
    }
  }

  // Product APIs
  Future<List<Product>> getProducts({int page = 1, String? search}) async {
    try {
      print('🔵 API SERVICE: Fetching products, page=$page, search=$search');
      print('🔵 ONLINE STATUS: $_isOnline');
      if (!_isOnline) {
        // Return from local database
        return await _db.getProducts(
            search: search, limit: AppConstants.itemsPerPage);
      }

      final response = await _dio.get('/products', queryParameters: {
        'page': page,
        'per_page': AppConstants.itemsPerPage,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      print('📥 RESPONSE: ${response.data}');

      if (response.data['error'] == false) {
        final products = (response.data['data']['products'] as List)
            .map((json) => Product.fromJson(json))
            .toList();

        // Save to local database
        await _db.saveProducts(products);
        return products;
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      // If online request fails, try local database
      return await _db.getProducts(
          search: search, limit: AppConstants.itemsPerPage);
    }
  }

  Future<Product?> scanBarcode(String barcode) async {
    try {
      if (!_isOnline) {
        return await _db.getProductByBarcode(barcode);
      }

      final response = await _dio.post('/products/scan-barcode', data: {
        'barcode': barcode,
      });

      if (response.data['error'] == false &&
          response.data['data']['product'] != null) {
        return Product.fromJson(response.data['data']['product']);
      }
      return null;
    } catch (e) {
      return await _db.getProductByBarcode(barcode);
    }
  }

  Future<List<ProductCategory>> getCategories() async {
    try {
      final response = await _dio.get('/products/categories');

      if (response.data['error'] == false) {
        return (response.data['data']['categories'] as List)
            .map((json) => ProductCategory.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Cart APIs
  Future<Cart> addToCart(int productId, {int quantity = 1}) async {
    try {
      final response = await _dio.post('/cart/add', data: {
        'id': productId,
        'qty': quantity,
      });

      if (response.data['error'] == false) {
        return Cart.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to add to cart: ${e.toString()}');
    }
  }

  Future<Cart> updateCart(int productId, int quantity) async {
    try {
      final response = await _dio.post('/cart/update', data: {
        'id': productId,
        'qty': quantity,
      });

      if (response.data['error'] == false) {
        return Cart.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to update cart: ${e.toString()}');
    }
  }

  Future<Cart> removeFromCart(int productId) async {
    try {
      final response = await _dio.post('/cart/remove', data: {
        'id': productId,
      });

      if (response.data['error'] == false) {
        return Cart.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to remove from cart: ${e.toString()}');
    }
  }

  Future<void> clearCart() async {
    try {
      await _dio.post('/cart/clear');
    } catch (e) {
      throw Exception('Failed to clear cart: ${e.toString()}');
    }
  }

  Future<Cart> updatePaymentMethod(String method) async {
    try {
      final response = await _dio.post('/cart/update-payment-method', data: {
        'payment_method': method,
      });

      if (response.data['error'] == false) {
        return Cart.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to update payment method: ${e.toString()}');
    }
  }

  // Customer APIs
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final response = await _dio.get('/customers/search', queryParameters: {
        'keyword': query,
      });

      if (response.data['error'] == false) {
        return (response.data['data']['customers'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/customers', data: data);

      if (response.data['error'] == false) {
        return Customer.fromJson(response.data['data']['customer']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to create customer: ${e.toString()}');
    }
  }

  // Order APIs
  Future<Order> checkout({String? paymentDetails}) async {
    try {
      if (!_isOnline) {
        throw Exception('Cannot checkout while offline');
      }

      final response = await _dio.post('/orders', data: {
        if (paymentDetails != null) 'payment_details': paymentDetails,
      });

      if (response.data['error'] == false) {
        return Order.fromJson(response.data['data']['order']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Checkout failed: ${e.toString()}');
    }
  }

  Future<String> getReceipt(int orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/receipt');
      return response.data['data']['receipt_html'];
    } catch (e) {
      throw Exception('Failed to get receipt: ${e.toString()}');
    }
  }

  // Cash Register APIs
  Future<List<CashRegister>> getCashRegisters() async {
    try {
      final response = await _dio.get('/cash-registers');

      if (response.data['error'] == false) {
        return (response.data['data']['cash_registers'] as List)
            .map((json) => CashRegister.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Session APIs
  Future<PosSession?> getActiveSession() async {
    try {
      if (!_isOnline) {
        return await _db.getActiveSession();
      }

      final response = await _dio.get('/sessions/active');

      if (response.data['error'] == false &&
          response.data['data']['session'] != null) {
        final session = PosSession.fromJson(response.data['data']['session']);
        await _db.saveSession(session);
        return session;
      }
      return null;
    } catch (e) {
      return await _db.getActiveSession();
    }
  }

  Future<PosSession> openSession({
    required int cashRegisterId,
    required double openingCash,
    Map<String, int>? denominations,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/sessions/open', data: {
        'cash_register_id': cashRegisterId,
        'opening_cash': openingCash,
        if (denominations != null) 'opening_denominations': denominations,
        if (notes != null) 'opening_notes': notes,
      });

      if (response.data['error'] == false) {
        final session = PosSession.fromJson(response.data['data']['session']);
        await _db.saveSession(session);
        return session;
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to open session: ${e.toString()}');
    }
  }

  Future<PosSession> closeSession({
    required int sessionId,
    required double closingCash,
    Map<String, int>? denominations,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/sessions/close', data: {
        'session_id': sessionId,
        'closing_cash': closingCash,
        if (denominations != null) 'closing_denominations': denominations,
        if (notes != null) 'closing_notes': notes,
      });

      if (response.data['error'] == false) {
        final session = PosSession.fromJson(response.data['data']['session']);
        await _db.saveSession(session);
        return session;
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to close session: ${e.toString()}');
    }
  }

  // Denomination APIs
  Future<List<Denomination>> getDenominations({String currency = 'USD'}) async {
    try {
      final response = await _dio.get('/denominations', queryParameters: {
        'currency': currency,
      });

      if (response.data['error'] == false) {
        return (response.data['data']['denominations'] as List)
            .map((json) => Denomination.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Sync pending data when back online
  Future<void> _syncPendingData() async {
    try {
      final pendingOrders = await _db.getPendingOrders();

      for (var order in pendingOrders) {
        try {
          // Try to sync order
          await _dio.post('/orders', data: order);
          await _db.markOrderAsSynced(order['id'] as int);
        } catch (e) {
          // Continue with next order
          continue;
        }
      }
    } catch (e) {
      // Ignore sync errors
    }
  }
}
