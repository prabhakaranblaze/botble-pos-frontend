import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/models/product.dart';
import '../../core/models/cart.dart';
import '../../core/models/customer.dart';
import '../../core/models/customer_address.dart';
import '../../core/models/saved_cart.dart';
import '../../core/api/api_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/database/saved_cart_database.dart';
import 'delivery_address_widget.dart';

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
  String _paymentMethod = 'pos_cash'; // Laravel-style payment method

  // ✅ Default tax rate from settings (percentage, e.g., 15 for 15%)
  double _defaultTaxRate = 0.0;

  // ✅ Discount state
  int? _couponDiscountId;            // ID for usage tracking
  String? _couponCode;               // Applied coupon code
  double _couponDiscountAmount = 0;  // Coupon discount amount
  String? _manualDiscountType;       // 'percentage' or 'amount'
  double _manualDiscountValue = 0;   // The value entered
  double _manualDiscountAmount = 0;  // Calculated amount
  String? _discountDescription;      // Description for manual discount

  // ✅ Shipping state
  double _shippingAmount = 0;

  // ✅ Delivery & Address state
  DeliveryType _deliveryType = DeliveryType.pickup;
  List<CustomerAddress> _customerAddresses = [];
  CustomerAddress? _selectedAddress;
  bool _isLoadingAddresses = false;

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
  bool get isOnline => _apiService.isOnline;
  double get defaultTaxRate => _defaultTaxRate;

  // Discount getters
  int? get couponDiscountId => _couponDiscountId;
  String? get couponCode => _couponCode;
  double get couponDiscountAmount => _couponDiscountAmount;
  String? get manualDiscountType => _manualDiscountType;
  double get manualDiscountValue => _manualDiscountValue;
  double get manualDiscountAmount => _manualDiscountAmount;
  String? get discountDescription => _discountDescription;
  double get totalDiscountAmount => _couponDiscountAmount > 0 ? _couponDiscountAmount : _manualDiscountAmount;
  bool get hasCouponDiscount => _couponCode != null && _couponDiscountAmount > 0;
  bool get hasManualDiscount => _manualDiscountAmount > 0;
  bool get hasDiscount => hasCouponDiscount || hasManualDiscount;

  // Shipping getter
  double get shippingAmount => _shippingAmount;

  // Delivery & Address getters
  DeliveryType get deliveryType => _deliveryType;
  List<CustomerAddress> get customerAddresses => _customerAddresses;
  CustomerAddress? get selectedAddress => _selectedAddress;
  bool get isLoadingAddresses => _isLoadingAddresses;

  // ✅ Build cart from local items
  Cart get cart {
    if (_cartItems.isEmpty) return Cart.empty();

    final subtotal =
        _cartItems.fold<double>(0, (sum, item) => sum + item.total);
    final tax = _cartItems.fold<double>(
        0, (sum, item) => sum + (item.total * (item.taxRate / 100)));

    // Calculate total: subtotal + tax - discount + shipping
    final discount = totalDiscountAmount;
    final total = subtotal + tax - discount + _shippingAmount;

    return Cart(
      items: _cartItems
          .map((item) => CartItem(
                productId: item.productId,
                name: item.name,
                price: item.price,
                quantity: item.quantity,
                image: item.image,
                sku: item.sku,
                options: item.options,
              ))
          .toList(),
      subtotal: subtotal,
      discount: discount,
      shipping: _shippingAmount,
      tax: tax,
      total: total,
      customer: _selectedCustomer,
      paymentMethod: _paymentMethod,
    );
  }

  // Load settings (including default tax rate)
  Future<void> loadSettings() async {
    try {
      debugPrint('⚙️ SALES: Loading settings...');
      final settings = await _apiService.getSettings();
      if (settings != null) {
        // Extract default tax from settings
        final defaultTax = settings['default_tax'];
        if (defaultTax != null && defaultTax is Map<String, dynamic>) {
          _defaultTaxRate = (defaultTax['percentage'] as num?)?.toDouble() ?? 0.0;
          debugPrint('✅ SALES: Default tax rate loaded: $_defaultTaxRate%');
        } else {
          debugPrint('⚠️ SALES: No default tax in settings');
        }
      }
    } catch (e) {
      debugPrint('❌ SALES: Error loading settings: $e');
    }
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

  // Search products (updates main list)
  Future<void> searchProducts(String query) async {
    _searchQuery = query;
    await loadProducts(refresh: true);
  }

  /// Search products online without modifying the main products list
  /// Used for autocomplete when local cache is empty
  Future<List<Product>> searchProductsOnline(String query) async {
    if (query.isEmpty) return [];

    debugPrint('🔍 ONLINE SEARCH: Searching for "$query"');
    try {
      final results = await _apiService.getProducts(search: query);
      debugPrint('🔍 ONLINE SEARCH: Found ${results.length} results');
      return results;
    } catch (e) {
      debugPrint('❌ ONLINE SEARCH: Error - $e');
      return [];
    }
  }

  /// Get product details with full variant options
  /// Used when product.hasVariants but no options in the search result
  Future<Product?> getProductDetails(int productId) async {
    debugPrint('📦 PRODUCT DETAILS: Fetching product $productId');
    try {
      final product = await _apiService.getProductDetails(productId);
      if (product != null) {
        debugPrint(
            '📦 PRODUCT DETAILS: Got ${product.name}, variants: ${product.variants?.length ?? 0}');
      }
      return product;
    } catch (e) {
      debugPrint('❌ PRODUCT DETAILS: Error - $e');
      return null;
    }
  }

  // Scan barcode - just return the product, don't add to cart
  Future<Product?> scanBarcode(String barcode) async {
    try {
      final product = await _apiService.scanBarcode(barcode);

      if (product != null) {
        await _audioService.playBeep();
        return product; // ✅ Just return it
      } else {
        await _audioService.playError();
        _error = 'Product not found';
        notifyListeners();
        return null;
      }
    } catch (e) {
      await _audioService.playError();
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ✅ CLIENT-SIDE: Add to cart by product ID (looks up in _products)
  Future<void> addToCart(int productId, {int quantity = 1}) async {
    try {
      debugPrint('🛒 CLIENT CART: Adding product $productId (qty: $quantity)');

      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found in local cache'),
      );

      await addProductToCart(product, quantity: quantity);
    } catch (e) {
      debugPrint('❌ CLIENT CART: Add error: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // ✅ CLIENT-SIDE: Add to cart with full Product object (for API search results)
  // priceOverride: Use this for variant products where price comes from variant selection
  // options: Display string for selected options (e.g., "Size: Large • Color: Red")
  Future<void> addProductToCart(Product product,
      {int quantity = 1, double? priceOverride, String? options}) async {
    try {
      final unitPrice = priceOverride ?? product.finalPrice;
      debugPrint(
          '🛒 CLIENT CART: Adding "${product.name}" (qty: $quantity, price: $unitPrice)');

      // Validate price - API rejects items with price <= 0
      if (unitPrice <= 0) {
        debugPrint('❌ CLIENT CART: Invalid price $unitPrice');
        await _audioService.playError();
        throw Exception(
            'Cannot add "${product.name}" - price must be greater than 0');
      }

      final existingIndex =
          _cartItems.indexWhere((item) => item.productId == product.id);

      if (existingIndex >= 0) {
        final existing = _cartItems[existingIndex];
        _cartItems[existingIndex] = existing.copyWith(
          quantity: existing.quantity + quantity,
        );
        debugPrint('✅ Updated qty: ${_cartItems[existingIndex].quantity}');
      } else {
        // Get tax rate: product tax first, then default tax from settings
        final productTax = product.tax?.percentage ?? 0.0;
        final taxRate = productTax > 0 ? productTax : _defaultTaxRate;

        // Options string: only show if variants were selected (no "Default" fallback)
        final optionsDisplay = (options != null && options.isNotEmpty) ? options : null;

        _cartItems.add(SavedCartItem(
          productId: product.id,
          name: product.name,
          price: unitPrice,
          quantity: quantity,
          image: product.image,
          sku: product.sku,
          options: optionsDisplay,
          taxRate: taxRate,
        ));
        debugPrint('✅ Added new item with tax rate: $taxRate% (product: $productTax%, default: $_defaultTaxRate%)');
      }

      await _audioService.playBeep();
      debugPrint('✅ CLIENT CART: Total items: ${_cartItems.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ CLIENT CART: Add product error: $e');
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
      _paymentMethod = 'pos_cash';

      // Clear discount and shipping
      _couponDiscountId = null;
      _couponCode = null;
      _couponDiscountAmount = 0;
      _manualDiscountType = null;
      _manualDiscountValue = 0;
      _manualDiscountAmount = 0;
      _discountDescription = null;
      _shippingAmount = 0;

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
    // Use addresses from customer object (already loaded with customer)
    _customerAddresses = customer.addresses;
    _selectedAddress = customer.defaultAddress;
    _deliveryType = DeliveryType.pickup;
    notifyListeners();
  }

  void clearCustomer() {
    _selectedCustomer = null;
    _customerAddresses = [];
    _selectedAddress = null;
    _deliveryType = DeliveryType.pickup;
    notifyListeners();
  }

  // ========== DELIVERY & ADDRESS OPERATIONS ==========

  void setDeliveryType(DeliveryType type) {
    _deliveryType = type;
    // Clear address when switching to pickup
    if (type == DeliveryType.pickup) {
      _selectedAddress = null;
    } else if (_customerAddresses.isNotEmpty && _selectedAddress == null) {
      // Auto-select default address when switching to ship
      _selectedAddress = _customerAddresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => _customerAddresses.first,
      );
    }
    notifyListeners();
  }

  void selectAddress(CustomerAddress? address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> loadCustomerAddresses(int customerId) async {
    _isLoadingAddresses = true;
    notifyListeners();

    try {
      _customerAddresses = await _apiService.getCustomerAddresses(customerId);
      // Auto-select default address if available
      if (_customerAddresses.isNotEmpty) {
        _selectedAddress = _customerAddresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => _customerAddresses.first,
        );
      }
      debugPrint('✅ Loaded ${_customerAddresses.length} addresses');
    } catch (e) {
      debugPrint('❌ Error loading addresses: $e');
      _customerAddresses = [];
    } finally {
      _isLoadingAddresses = false;
      notifyListeners();
    }
  }

  Future<CustomerAddress> createCustomerAddress(Map<String, dynamic> data) async {
    if (_selectedCustomer == null) {
      throw Exception('No customer selected');
    }

    final address = await _apiService.createCustomerAddress(_selectedCustomer!.id, data);
    _customerAddresses.add(address);

    // Auto-select the new address
    _selectedAddress = address;
    notifyListeners();

    return address;
  }

  Future<Customer> createCustomer(String name, String phone, String? email) async {
    final customer = await _apiService.createCustomer({
      'name': name,
      'phone': phone,
      'email': email,
    });

    // Auto-select the new customer
    selectCustomer(customer);

    return customer;
  }

  Future<List<Customer>> searchCustomers(String query) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }
    return await _apiService.searchCustomers(query);
  }

  void updatePaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // ========== DISCOUNT OPERATIONS ==========

  /// Apply a validated coupon discount
  void applyCouponDiscount({
    required int discountId,
    required String code,
    required double discountAmount,
  }) {
    debugPrint('🎟️ DISCOUNT: Applying coupon "$code" with amount: $discountAmount');

    // Clear any manual discount first
    _manualDiscountType = null;
    _manualDiscountValue = 0;
    _manualDiscountAmount = 0;
    _discountDescription = null;

    // Apply coupon
    _couponDiscountId = discountId;
    _couponCode = code;
    _couponDiscountAmount = discountAmount;

    notifyListeners();
  }

  /// Clear coupon discount
  void clearCouponDiscount() {
    debugPrint('🎟️ DISCOUNT: Clearing coupon discount');
    _couponDiscountId = null;
    _couponCode = null;
    _couponDiscountAmount = 0;
    notifyListeners();
  }

  /// Apply a manual discount
  void applyManualDiscount({
    required String type, // 'percentage' or 'amount'
    required double value,
    required double discountAmount,
    String? description,
  }) {
    debugPrint('💰 DISCOUNT: Applying manual $type discount: $value (amount: $discountAmount)');

    // Clear any coupon discount first
    _couponDiscountId = null;
    _couponCode = null;
    _couponDiscountAmount = 0;

    // Apply manual discount
    _manualDiscountType = type;
    _manualDiscountValue = value;
    _manualDiscountAmount = discountAmount;
    _discountDescription = description;

    notifyListeners();
  }

  /// Clear manual discount
  void clearManualDiscount() {
    debugPrint('💰 DISCOUNT: Clearing manual discount');
    _manualDiscountType = null;
    _manualDiscountValue = 0;
    _manualDiscountAmount = 0;
    _discountDescription = null;
    notifyListeners();
  }

  /// Clear all discounts
  void clearAllDiscounts() {
    debugPrint('🗑️ DISCOUNT: Clearing all discounts');
    _couponDiscountId = null;
    _couponCode = null;
    _couponDiscountAmount = 0;
    _manualDiscountType = null;
    _manualDiscountValue = 0;
    _manualDiscountAmount = 0;
    _discountDescription = null;
    notifyListeners();
  }

  // ========== SHIPPING OPERATIONS ==========

  /// Set shipping amount
  void setShippingAmount(double amount) {
    debugPrint('🚚 SHIPPING: Setting shipping amount: $amount');
    _shippingAmount = amount;
    notifyListeners();
  }

  /// Clear shipping amount
  void clearShippingAmount() {
    debugPrint('🚚 SHIPPING: Clearing shipping amount');
    _shippingAmount = 0;
    notifyListeners();
  }

  /// Validate a coupon code with the API
  Future<Map<String, dynamic>?> validateCoupon(String code) async {
    try {
      debugPrint('🎟️ COUPON: Validating code "$code"');

      final subtotal = cart.subtotal;
      final items = _cartItems.map((item) => {
        'product_id': item.productId,
        'quantity': item.quantity,
        'price': item.price,
      }).toList();

      final result = await _apiService.validateCoupon(
        code: code,
        subtotal: subtotal,
        items: items,
        customerId: _selectedCustomer?.id,
      );

      debugPrint('🎟️ COUPON: Validation result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ COUPON: Validation error: $e');
      return null;
    }
  }

  // ✅ CHECKOUT: Create order - sends cart items directly to backend
  Future<Order?> checkout({String? paymentDetails}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('💳 CHECKOUT: Starting...');
      debugPrint('💳 CHECKOUT: Items: ${_cartItems.length}');
      debugPrint('💳 CHECKOUT: Payment method: $_paymentMethod');
      debugPrint('💳 CHECKOUT: Discount: $totalDiscountAmount (coupon: $_couponCode)');
      debugPrint('💳 CHECKOUT: Shipping: $_shippingAmount');
      debugPrint('💳 CHECKOUT: Cart tax: ${cart.tax}');
      for (var item in _cartItems) {
        debugPrint('💳 CHECKOUT: Item "${item.name}" taxRate: ${item.taxRate}%');
      }

      if (_cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Build items for direct checkout (include tax_rate, sku, and options)
      final items = _cartItems
          .map((item) => {
                'product_id': item.productId,
                'name': item.name,
                'quantity': item.quantity,
                'price': item.price,
                'image': item.image,
                'sku': item.sku,
                'options': item.options,
                'tax_rate': item.taxRate,
              })
          .toList();

      debugPrint('💳 CHECKOUT: Sending ${items.length} items to server...');

      // Build customer address string for invoice
      String? customerAddressStr;
      if (_deliveryType == DeliveryType.ship && _selectedAddress != null) {
        customerAddressStr = _selectedAddress!.displayText;
      }

      // Direct checkout with discount, shipping, and address
      final order = await _apiService.checkoutDirect(
        items: items,
        paymentMethod: _paymentMethod,
        paymentDetails: paymentDetails,
        customerId: _selectedCustomer?.id,
        // Discount parameters
        discountId: _couponDiscountId,
        couponCode: _couponCode,
        discountAmount: totalDiscountAmount,
        discountDescription: _discountDescription,
        // Shipping & Delivery
        shippingAmount: _shippingAmount,
        deliveryType: _deliveryType == DeliveryType.ship ? 'ship' : 'pickup',
        // Tax (calculated from cart)
        taxAmount: cart.tax,
        // Customer info for invoice
        customerName: _selectedCustomer?.name,
        customerEmail: _selectedCustomer?.email,
        customerPhone: _selectedCustomer?.phone,
        // Address info (for delivery)
        addressId: _selectedAddress?.id,
        customerAddress: customerAddressStr,
      );

      // Clear local cart and all state
      _cartItems.clear();
      _selectedCustomer = null;
      _paymentMethod = 'pos_cash';
      _couponDiscountId = null;
      _couponCode = null;
      _couponDiscountAmount = 0;
      _manualDiscountType = null;
      _manualDiscountValue = 0;
      _manualDiscountAmount = 0;
      _discountDescription = null;
      _shippingAmount = 0;
      _deliveryType = DeliveryType.pickup;
      _customerAddresses = [];
      _selectedAddress = null;

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

  /// Quick save current cart with auto-generated name (no dialog)
  Future<bool> quickSaveCart({
    required int userId,
    required String userName,
  }) async {
    if (_cartItems.isEmpty) {
      debugPrint('⚠️ QUICK SAVE: Cart is empty, nothing to save');
      return false;
    }

    final name = getAutoCartName();
    return await saveCart(
      name: name,
      userId: userId,
      userName: userName,
      saveOnline: false,
    );
  }

  /// Load a saved cart into active cart
  /// If autoSaveCurrentCart is true, saves current cart before loading
  Future<bool> loadCart(
    String cartId,
    int userId, {
    String? userName,
    bool autoSaveCurrentCart = true,
  }) async {
    try {
      debugPrint('📂 LOAD CART: Loading $cartId');

      // Auto-save current cart if it has items
      if (autoSaveCurrentCart && _cartItems.isNotEmpty && userName != null) {
        debugPrint('📂 LOAD CART: Auto-saving current cart first...');
        await quickSaveCart(userId: userId, userName: userName);
        debugPrint('📂 LOAD CART: Current cart auto-saved');
      }

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

      // Reload saved carts list
      await loadSavedCarts(userId);

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
