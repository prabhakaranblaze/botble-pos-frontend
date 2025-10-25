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

  SalesProvider(this._apiService, this._audioService) {
    debugPrint('🟢 SALES PROVIDER: Constructor called');
  }

  // Getters
  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  Cart get cart {
    debugPrint(
        '📊 SALES PROVIDER: get cart called - Items: ${_cart.items.length}, Total: ${_cart.total}');
    return _cart;
  }

  Customer? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  AudioService get audioService => _audioService;

  // Load products
  Future<void> loadProducts({bool refresh = false}) async {
    debugPrint(
        '🔵 SALES PROVIDER: loadProducts called - refresh: $refresh, page: $_currentPage, search: "$_searchQuery"');

    if (refresh) {
      _currentPage = 1;
      _products.clear();
      debugPrint('🔵 SALES PROVIDER: Clearing products for refresh');
    }

    _isLoading = refresh;
    _isLoadingMore = !refresh;
    _error = null;

    if (refresh) {
      notifyListeners();
    }

    try {
      debugPrint(
          '🔵 SALES PROVIDER: Calling API - getProducts(page: $_currentPage, search: "$_searchQuery")');

      final newProducts = await _apiService.getProducts(
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      debugPrint(
          '✅ SALES PROVIDER: Products loaded - Count: ${newProducts.length}');

      if (newProducts.isNotEmpty) {
        debugPrint(
            '✅ SALES PROVIDER: First product: ${newProducts.first.name} (ID: ${newProducts.first.id})');
      }

      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _currentPage++;
      _error = null;

      debugPrint(
          '✅ SALES PROVIDER: Total products in memory: ${_products.length}');
    } catch (e) {
      debugPrint('❌ SALES PROVIDER: Error loading products: $e');
      debugPrint('❌ SALES PROVIDER: Stack trace: ${StackTrace.current}');
      _error = e.toString();
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  // Load categories
  Future<void> loadCategories() async {
    debugPrint('🔵 SALES PROVIDER: loadCategories called');

    try {
      _categories = await _apiService.getCategories();
      debugPrint(
          '✅ SALES PROVIDER: Categories loaded - Count: ${_categories.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ SALES PROVIDER: Error loading categories (ignoring): $e');
    }
  }

  // Search products
  void searchProducts(String query) {
    debugPrint('🔍 SALES PROVIDER: searchProducts called - query: "$query"');
    _searchQuery = query;
    loadProducts(refresh: true);
  }

  // Scan barcode
  Future<void> scanBarcode(String barcode) async {
    debugPrint('📷 SALES PROVIDER: scanBarcode called - barcode: "$barcode"');

    try {
      final product = await _apiService.scanBarcode(barcode);

      if (product != null) {
        debugPrint(
            '✅ SALES PROVIDER: Product found by barcode - ${product.name}');
        await addToCart(product.id);
        await _audioService.playBeep();
      } else {
        debugPrint('⚠️ SALES PROVIDER: Product not found by barcode');
        await _audioService.playError();
        _error = 'Product not found';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ SALES PROVIDER: Error scanning barcode: $e');
      await _audioService.playError();
      _error = e.toString();
      notifyListeners();
    }
  }

  // Cart operations
  Future<void> addToCart(
    int productId, {
    int quantity = 1,
    Map<int, int>? variants,
  }) async {
    debugPrint('➕ SALES PROVIDER: addToCart called');
    debugPrint('➕ SALES PROVIDER: Product ID: $productId');
    debugPrint('➕ SALES PROVIDER: Quantity: $quantity');
    debugPrint('➕ SALES PROVIDER: Variants: $variants');
    debugPrint('➕ SALES PROVIDER: Current cart items: ${_cart.items.length}');

    try {
      debugPrint('🔵 SALES PROVIDER: Calling API - addToCart');

      final updatedCart = await _apiService.addToCart(
        productId,
        quantity: quantity,
        variants: variants,
      );

      debugPrint('✅ SALES PROVIDER: API response received');
      debugPrint(
          '✅ SALES PROVIDER: Updated cart items: ${updatedCart.items.length}');
      debugPrint('✅ SALES PROVIDER: Updated cart total: ${updatedCart.total}');

      if (updatedCart.items.isNotEmpty) {
        debugPrint(
            '✅ SALES PROVIDER: First item in cart: ${updatedCart.items.first.name} (qty: ${updatedCart.items.first.quantity})');
      }

      _cart = updatedCart;

      debugPrint(
          '✅ SALES PROVIDER: Cart updated in provider - Items: ${_cart.items.length}');

      await _audioService.playBeep();
      debugPrint('🔊 SALES PROVIDER: Beep sound played');

      notifyListeners();
      debugPrint('📢 SALES PROVIDER: notifyListeners called');
    } catch (e) {
      debugPrint('❌ SALES PROVIDER: Error adding to cart: $e');
      debugPrint('❌ SALES PROVIDER: Error type: ${e.runtimeType}');
      debugPrint('❌ SALES PROVIDER: Stack trace: ${StackTrace.current}');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCartItem(int productId, int quantity) async {
    debugPrint('🔄 SALES PROVIDER: updateCartItem called');
    debugPrint('🔄 SALES PROVIDER: Product ID: $productId');
    debugPrint('🔄 SALES PROVIDER: New quantity: $quantity');

    try {
      if (quantity <= 0) {
        debugPrint('🗑️ SALES PROVIDER: Quantity is 0, removing item');
        await removeFromCart(productId);
      } else {
        debugPrint('🔵 SALES PROVIDER: Calling API - updateCart');

        _cart = await _apiService.updateCart(productId, quantity);

        debugPrint(
            '✅ SALES PROVIDER: Cart updated - Items: ${_cart.items.length}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ SALES PROVIDER: Error updating cart item: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeFromCart(int productId) async {
    debugPrint(
        '🗑️ SALES PROVIDER: removeFromCart called - Product ID: $productId');

    try {
      debugPrint('🔵 SALES PROVIDER: Calling API - removeFromCart');

      _cart = await _apiService.removeFromCart(productId);

      debugPrint(
          '✅ SALES PROVIDER: Item removed - Cart items: ${_cart.items.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ SALES PROVIDER: Error removing from cart: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    debugPrint('🗑️ SALES PROVIDER: clearCart called');

    try {
      debugPrint('🔵 SALES PROVIDER: Calling API - clearCart');

      await _apiService.clearCart();

      _cart = Cart.empty();
      _selectedCustomer = null;

      debugPrint('✅ SALES PROVIDER: Cart cleared');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ SALES PROVIDER: Error clearing cart: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // Customer operations
  void selectCustomer(Customer customer) {
    debugPrint('👤 SALES PROVIDER: selectCustomer called - ${customer.name}');
    _selectedCustomer = customer;
    notifyListeners();
  }

  void clearCustomer() {
    debugPrint('👤 SALES PROVIDER: clearCustomer called');
    _selectedCustomer = null;
    notifyListeners();
  }

  // Payment
  Future<void> updatePaymentMethod(String method) async {
    debugPrint(
        '💳 SALES PROVIDER: updatePaymentMethod called - Method: $method');

    try {
      _cart = await _apiService.updatePaymentMethod(method);
      debugPrint('✅ SALES PROVIDER: Payment method updated');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ SALES PROVIDER: Error updating payment method: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // Checkout
  Future<Order?> checkout({String? paymentDetails}) async {
    debugPrint('💳 SALES PROVIDER: checkout called');
    debugPrint('💳 SALES PROVIDER: Cart items: ${_cart.items.length}');
    debugPrint('💳 SALES PROVIDER: Cart total: ${_cart.total}');
    debugPrint('💳 SALES PROVIDER: Payment details: $paymentDetails');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔵 SALES PROVIDER: Calling API - checkout');

      final order = await _apiService.checkout(paymentDetails: paymentDetails);

      debugPrint('✅ SALES PROVIDER: Order created successfully');
      debugPrint('✅ SALES PROVIDER: Order ID: ${order.id}');
      debugPrint('✅ SALES PROVIDER: Order code: ${order.code}');

      // Clear cart after successful checkout
      _cart = Cart.empty();
      _selectedCustomer = null;

      await _audioService.playSuccess();

      _isLoading = false;
      notifyListeners();

      return order;
    } catch (e) {
      debugPrint('❌ SALES PROVIDER: Checkout error: $e');
      debugPrint('❌ SALES PROVIDER: Stack trace: ${StackTrace.current}');

      await _audioService.playError();
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    debugPrint('🔵 SALES PROVIDER: clearError called');
    _error = null;
    notifyListeners();
  }
}
