import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/models/product.dart';
import '../../core/models/cart.dart';
import '../../core/models/customer.dart';
import '../../core/models/saved_cart.dart';
import '../../core/api/api_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/database/saved_cart_database.dart';

class SalesProvider with ChangeNotifier {
  final ApiService _apiService;
  final AudioService _audioService;
  final SavedCartDatabase _savedCartDb = SavedCartDatabase();
  final Uuid _uuid = const Uuid();

  List<Product> _products = [];
  List<ProductCategory> _categories = [];

  // ✅ Client-side cart (local memory)
  final List<SavedCartItem> _cartItems = [];
  Customer? _selectedCustomer;
  String _paymentMethod = 'cash';

  // ✅ Saved carts
  List<SavedCart> _savedCarts = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 1;

  SalesProvider(this._apiService, this._audioService);

  // Getters
  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  List<SavedCart> get savedCarts => _savedCarts;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  AudioService get audioService => _audioService;

  // ✅ Build cart from local items
  Cart get cart {
    if (_cartItems.isEmpty) return Cart.empty();

    final subtotal =
        _cartItems.fold<double>(0, (sum, item) => sum + item.total);
    final tax = _cartItems.fold<double>(
        0, (sum, item) => sum + (item.total * (item.taxRate / 100)));
    final total = subtotal + tax;

    return Cart(
      items: _cartItems
          .map((item) => CartItem(
                productId: item.productId,
                name: item.name,
                price: item.price,
                quantity: item.quantity,
                image: item.image,
              ))
          .toList(),
      subtotal: subtotal,
      discount: 0,
      shipping: 0,
      tax: tax,
      total: total,
      customer: _selectedCustomer,
      paymentMethod: _paymentMethod,
    );
  }

  // Load products
  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _products.clear();
    }

    _isLoading = refresh;
    _isLoadingMore = !refresh;
    _error = null;

    if (refresh) notifyListeners();

    debugPrint(
        '🔵 LOADING PRODUCTS: page=$_currentPage, search="$_searchQuery"');

    try {
      final newProducts = await _apiService.getProducts(
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      debugPrint('✅ PRODUCTS LOADED: ${newProducts.length} products');

      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _currentPage++;
      _error = null;
    } catch (e) {
      debugPrint('❌ PRODUCTS ERROR: $e');
      _error = e.toString();
    }

    _isLoading = false;
    _isLoadingMore = false;
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

  // ✅ CLIENT-SIDE: Add to cart
  Future<void> addToCart(int productId, {int quantity = 1}) async {
    try {
      debugPrint('🛒 CLIENT CART: Adding product $productId (qty: $quantity)');

      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      );

      final existingIndex =
          _cartItems.indexWhere((item) => item.productId == productId);

      if (existingIndex >= 0) {
        final existing = _cartItems[existingIndex];
        _cartItems[existingIndex] = existing.copyWith(
          quantity: existing.quantity + quantity,
        );
        debugPrint('✅ Updated qty: ${_cartItems[existingIndex].quantity}');
      } else {
        _cartItems.add(SavedCartItem(
          productId: product.id,
          name: product.name,
          price: product.finalPrice,
          quantity: quantity,
          image: product.image,
          taxRate: 0.0,
        ));
        debugPrint('✅ Added new item');
      }

      await _audioService.playBeep();
      debugPrint('✅ CLIENT CART: Total items: ${_cartItems.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ CLIENT CART: Add error: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // ✅ CLIENT-SIDE: Update cart item
  Future<void> updateCartItem(int productId, int quantity) async {
    try {
      debugPrint(
          '🔄 CLIENT CART: Updating product $productId to qty: $quantity');

      if (quantity <= 0) {
        await removeFromCart(productId);
        return;
      }

      final index =
          _cartItems.indexWhere((item) => item.productId == productId);

      if (index >= 0) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
        debugPrint('✅ CLIENT CART: Updated successfully');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ CLIENT CART: Update error: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // ✅ CLIENT-SIDE: Remove from cart
  Future<void> removeFromCart(int productId) async {
    try {
      debugPrint('🗑️ CLIENT CART: Removing product $productId');
      _cartItems.removeWhere((item) => item.productId == productId);
      debugPrint('✅ CLIENT CART: Removed successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ CLIENT CART: Remove error: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // ✅ CLIENT-SIDE: Clear cart
  Future<void> clearCart() async {
    try {
      debugPrint('🗑️ CLIENT CART: Clearing cart');
      _cartItems.clear();
      _selectedCustomer = null;
      _paymentMethod = 'cash';
      debugPrint('✅ CLIENT CART: Cleared successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ CLIENT CART: Clear error: $e');
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

  void updatePaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // ✅ CHECKOUT: Create order
  Future<Order?> checkout({String? paymentDetails}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('💳 CHECKOUT: Starting...');
      debugPrint('💳 CHECKOUT: Items: ${_cartItems.length}');

      // Build cart for API
      final cartData = {
        'items': _cartItems
            .map((item) => {
                  'product_id': item.productId,
                  'name': item.name,
                  'quantity': item.quantity,
                  'price': item.price,
                })
            .toList(),
        'payment_method': _paymentMethod,
        if (paymentDetails != null) 'payment_details': paymentDetails,
        if (_selectedCustomer != null) 'customer_id': _selectedCustomer!.id,
      };

      // First sync cart to backend
      await _apiService.clearCart();
      for (var item in _cartItems) {
        await _apiService.addToCart(item.productId, quantity: item.quantity);
      }

      // Then checkout
      final order = await _apiService.checkout(paymentDetails: paymentDetails);

      _cartItems.clear();
      _selectedCustomer = null;
      _paymentMethod = 'cash';

      await _audioService.playSuccess();

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ CHECKOUT: Complete - Order #${order.code}');
      return order;
    } catch (e) {
      debugPrint('❌ CHECKOUT: Error: $e');
      await _audioService.playError();
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ========== SAVED CART OPERATIONS ==========

  /// Save current cart
  Future<bool> saveCart({
    required String name,
    required int userId,
    required String userName,
    bool saveOnline = false,
  }) async {
    if (_cartItems.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return false;
    }

    try {
      debugPrint('💾 SAVE CART: Saving "$name"');

      final savedCart = SavedCart(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        name: name,
        savedAt: DateTime.now(),
        customerId: _selectedCustomer?.id.toString(),
        customerName: _selectedCustomer?.name,
        items: List.from(_cartItems),
        subtotal: cart.subtotal,
        tax: cart.tax,
        total: cart.total,
        isOnline: saveOnline,
      );

      await _savedCartDb.saveCart(savedCart);

      // Clear active cart
      _cartItems.clear();
      _selectedCustomer = null;

      debugPrint('✅ SAVE CART: Saved successfully');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ SAVE CART: Error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load saved carts for user
  Future<void> loadSavedCarts(int userId) async {
    try {
      debugPrint('📋 LOAD SAVED CARTS: User $userId');
      _savedCarts = await _savedCartDb.getSavedCartsByUser(userId);
      debugPrint('✅ LOAD SAVED CARTS: Found ${_savedCarts.length} carts');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ LOAD SAVED CARTS: Error: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load a saved cart into active cart
  Future<bool> loadCart(String cartId, int userId) async {
    try {
      debugPrint('📂 LOAD CART: Loading $cartId');

      final savedCart = await _savedCartDb.getCartById(cartId, userId);

      if (savedCart == null) {
        debugPrint('❌ LOAD CART: Cart not found in database');
        _error = 'Cart not found';
        notifyListeners();
        return false;
      }

      debugPrint(
          '📂 LOAD CART: Found cart with ${savedCart.items.length} items');

      // Load items into active cart
      _cartItems.clear();
      _cartItems.addAll(savedCart.items);

      debugPrint('📂 LOAD CART: Items copied to active cart');

      // Load customer if exists
      if (savedCart.customerName != null) {
        _selectedCustomer = Customer(
          id: int.tryParse(savedCart.customerId ?? '0') ?? 0,
          name: savedCart.customerName!,
        );
        debugPrint('📂 LOAD CART: Customer loaded: ${savedCart.customerName}');
      }

      // Delete the saved cart (one-time use)
      debugPrint('📂 LOAD CART: Deleting saved cart from database...');
      await _savedCartDb.deleteCart(cartId, userId);
      debugPrint('📂 LOAD CART: Saved cart deleted');

      debugPrint('✅ LOAD CART: Loaded successfully, calling notifyListeners');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ LOAD CART: Error: $e');
      debugPrint('❌ LOAD CART: Stack trace: ${StackTrace.current}');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProducts() async {
    _searchQuery = '';
    await loadProducts(refresh: true);
  }

  /// Delete a saved cart
  Future<bool> deleteSavedCart(String cartId, int userId) async {
    try {
      debugPrint('🗑️ DELETE CART: Deleting $cartId');

      await _savedCartDb.deleteCart(cartId, userId);

      _savedCarts.removeWhere((cart) => cart.id == cartId);

      debugPrint('✅ DELETE CART: Deleted successfully');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ DELETE CART: Error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get auto-generated cart name
  String getAutoCartName() {
    final now = DateTime.now();
    final formatter = DateFormat('MM/dd/yyyy, hh:mm:ss a');
    return 'Cart - ${formatter.format(now)}';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
