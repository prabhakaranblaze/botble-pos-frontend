import 'package:flutter/foundation.dart';
import '../../core/models/product.dart';
import '../../core/models/cart.dart';
import '../../core/models/customer.dart';
import '../../core/api/api_service.dart';
import '../../core/services/audio_service.dart';

class SalesProvider with ChangeNotifier {
  final ApiService _apiService;
  final AudioService _audioService;

  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  Cart _cart = Cart.empty();
  Customer? _selectedCustomer;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 1;

  SalesProvider(this._apiService, this._audioService);

  // Getters
  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  Cart get cart => _cart;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Load products
  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _products.clear();
    }

    _isLoading = refresh;
    _isLoadingMore = !refresh;
    _error = null;

    // Only notify once at the beginning
    if (refresh) {
      notifyListeners();
    }

    print('🔵 LOADING PRODUCTS: page=$_currentPage, search="$_searchQuery"');

    try {
      final newProducts = await _apiService.getProducts(
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      print('✅ PRODUCTS LOADED: ${newProducts.length} products');

      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _currentPage++;
      _error = null;
    } catch (e) {
      print('❌ PRODUCTS ERROR: $e');
      _error = e.toString();
    }

    _isLoading = false;
    _isLoadingMore = false;

    // Notify once at the end
    notifyListeners();
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (e) {
      // Ignore category errors
    }
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    loadProducts(refresh: true);
  }

  // Scan barcode
  Future<void> scanBarcode(String barcode) async {
    try {
      final product = await _apiService.scanBarcode(barcode);

      if (product != null) {
        await addToCart(product.id);
        await _audioService.playBeep();
      } else {
        await _audioService.playError();
        _error = 'Product not found';
        notifyListeners();
      }
    } catch (e) {
      await _audioService.playError();
      _error = e.toString();
      notifyListeners();
    }
  }

  // Cart operations
  Future<void> addToCart(int productId, {int quantity = 1}) async {
    try {
      _cart = await _apiService.addToCart(productId, quantity: quantity);
      await _audioService.playBeep();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCartItem(int productId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(productId);
      } else {
        _cart = await _apiService.updateCart(productId, quantity);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeFromCart(int productId) async {
    try {
      _cart = await _apiService.removeFromCart(productId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    try {
      await _apiService.clearCart();
      _cart = Cart.empty();
      _selectedCustomer = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Customer operations
  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void clearCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }

  // Payment
  Future<void> updatePaymentMethod(String method) async {
    try {
      _cart = await _apiService.updatePaymentMethod(method);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Checkout
  Future<Order?> checkout({String? paymentDetails}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _apiService.checkout(paymentDetails: paymentDetails);

      // Clear cart after successful checkout
      _cart = Cart.empty();
      _selectedCustomer = null;

      await _audioService.playSuccess();
      _isLoading = false;
      notifyListeners();

      return order;
    } catch (e) {
      await _audioService.playError();
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
