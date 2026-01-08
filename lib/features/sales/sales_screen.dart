import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../sales/sales_provider.dart';
import '../sales/variant_selection_dialog.dart';
import '../sales/cart_item_widget.dart';
import '../sales/payment_dialog.dart';
import '../sales/apply_coupon_dialog.dart';
import '../sales/apply_discount_dialog.dart';
import '../sales/update_shipping_dialog.dart';
import '../sales/customer_search_widget.dart';
import '../sales/add_customer_dialog.dart';
import '../sales/delivery_address_widget.dart';
import '../sales/add_address_dialog.dart';
import '../auth/auth_provider.dart';
import '../../core/models/product.dart';
import '../../core/services/auto_print_service.dart';
import '../../core/providers/pos_mode_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/constants/app_constants.dart';
import '../sales/save_cart_dialog.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();

  List<Product> _searchResults = [];
  bool _showSearchDropdown = false;
  int _selectedIndex = -1; // For keyboard navigation

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 SALES SCREEN: initState called');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🟢 SALES SCREEN: Post frame callback - loading data');
      _loadData();
      _loadSavedCarts();
      _searchFocusNode.requestFocus();
    });
  }

  Future<void> _loadSavedCarts() async {
    final authProvider = context.read<AuthProvider>();
    final salesProvider = context.read<SalesProvider>();

    if (authProvider.user != null) {
      await salesProvider.loadSavedCarts(authProvider.user!.id);
    }
  }

  Future<void> _loadData() async {
    debugPrint('🔵 SALES SCREEN: _loadData() started');
    final salesProvider = context.read<SalesProvider>();

    try {
      // Load settings first (for default tax rate)
      debugPrint('🔵 SALES SCREEN: Loading settings...');
      await salesProvider.loadSettings();
      debugPrint('✅ SALES SCREEN: Settings loaded (default tax: ${salesProvider.defaultTaxRate}%)');

      debugPrint('🔵 SALES SCREEN: Loading categories...');
      await salesProvider.loadCategories();
      debugPrint('✅ SALES SCREEN: Categories loaded');

      debugPrint('🔵 SALES SCREEN: Loading products...');
      await salesProvider.loadProducts(refresh: true);
      debugPrint(
          '✅ SALES SCREEN: Products loaded - Count: ${salesProvider.products.length}');
    } catch (e) {
      debugPrint('❌ SALES SCREEN: Error loading data: $e');
      debugPrint('❌ SALES SCREEN: Stack trace: ${StackTrace.current}');
    }
  }

  @override
  void dispose() {
    debugPrint('🔴 SALES SCREEN: dispose called');
    _searchController.dispose();
    _searchFocusNode.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    debugPrint('📱 BARCODE: Scanning $barcode');

    final salesProvider = context.read<SalesProvider>();

    // Use the scanBarcode API which returns the product directly
    try {
      final product = await salesProvider.scanBarcode(barcode);

      if (product != null) {
        debugPrint('📱 BARCODE: Found ${product.name}');
        await _addProductToCart(product);
        _searchController.clear();
        _searchFocusNode.requestFocus();
      } else {
        debugPrint('📱 BARCODE: Product not found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found')),
        );
      }
    } catch (e) {
      debugPrint('📱 BARCODE: Error - $e');
    }
  }

  // ⭐ UNIFIED SEARCH LOGIC (API-first when online, local when offline)
  Future<void> _handleSearch(String query) async {
    debugPrint('🔍 SEARCH: _handleSearch called with query: "$query"');

    if (query.isEmpty) {
      debugPrint('🔍 SEARCH: Query empty, clearing results');
      setState(() {
        _searchResults = [];
        _showSearchDropdown = false;
        _selectedIndex = -1;
      });
      return;
    }

    debugPrint('🔍 SEARCH: Searching for: "$query"');
    final salesProvider = context.read<SalesProvider>();

    List<Product> results = [];

    // API-first approach when online (for queries >= 2 chars)
    if (salesProvider.isOnline && query.length >= 2) {
      debugPrint('🔍 SEARCH: Online - using API search (auto-syncs to DB)');
      results = await salesProvider.searchProductsOnline(query);
      debugPrint('🔍 SEARCH: API found ${results.length} results');
    } else {
      // Offline: search local database only
      debugPrint('🔍 SEARCH: Offline - using local search');
      results = salesProvider.products.where((p) {
        final searchLower = query.toLowerCase();
        final matchName = p.name.toLowerCase().contains(searchLower);
        final matchSku = p.sku?.toLowerCase().contains(searchLower) ?? false;
        final matchBarcode =
            p.barcode?.toLowerCase().contains(searchLower) ?? false;

        return matchName || matchSku || matchBarcode;
      }).toList();
      debugPrint('🔍 SEARCH: Local found ${results.length} results');
    }

    // Update state with results
    setState(() {
      _searchResults = results;
      _showSearchDropdown = results.isNotEmpty;
      _selectedIndex = results.isNotEmpty ? 0 : -1;
    });

    debugPrint(
        '🔍 SEARCH: ${results.length} results, showing dropdown: ${results.isNotEmpty}');
  }

  Future<void> _handleRefresh() async {
    debugPrint('🔄 REFRESH: Manual refresh triggered');

    // Clear search state
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showSearchDropdown = false;
    });

    // Refresh products from server
    final salesProvider = context.read<SalesProvider>();
    await salesProvider.refreshProducts();

    // Refocus search
    _searchFocusNode.requestFocus();

    debugPrint('✅ REFRESH: Complete');
  }

  void _clearSearch() {
    debugPrint('🔍 SEARCH: _clearSearch called');
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showSearchDropdown = false;
      _selectedIndex = -1;
    });
    _searchFocusNode.requestFocus();
  }

  /// Handle keyboard events for search dropdown navigation
  KeyEventResult _handleSearchKeyEvent(KeyEvent event) {
    if (!_showSearchDropdown || _searchResults.isEmpty) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _searchResults.length;
        });
        debugPrint('⬇️ KEYBOARD: Selected index: $_selectedIndex');
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _searchResults.length) % _searchResults.length;
        });
        debugPrint('⬆️ KEYBOARD: Selected index: $_selectedIndex');
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _clearSearch();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // ⭐ UNIFIED ADD TO CART LOGIC
  Future<void> _addProductToCart(Product product) async {
    debugPrint('➕ ADD TO CART: _addProductToCart called');
    debugPrint('➕ ADD TO CART: Product ID: ${product.id}');
    debugPrint('➕ ADD TO CART: Product Name: ${product.name}');
    debugPrint('➕ ADD TO CART: Has Variants: ${product.hasVariants}');
    debugPrint(
        '➕ ADD TO CART: Has Selectable Variants: ${product.hasSelectableVariants}');

    final salesProvider = context.read<SalesProvider>();

    try {
      // Determine which product to use for variant dialog
      Product productForCart = product;

      // If product has variants flag but no selectable options, fetch full details
      if (product.hasVariants && !product.hasSelectableVariants) {
        debugPrint(
            '➕ ADD TO CART: Product has variants flag but no options, fetching details...');

        final fullProduct =
            await salesProvider.getProductDetails(product.id);
        if (fullProduct != null) {
          debugPrint(
              '➕ ADD TO CART: Got full product, hasSelectableVariants: ${fullProduct.hasSelectableVariants}');
          productForCart = fullProduct;
        }
      }

      // Now check if we should show variant dialog
      if (productForCart.hasSelectableVariants) {
        debugPrint('➕ ADD TO CART: Product has variants, showing dialog...');

        // Show variant selection dialog
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) =>
              VariantSelectionDialog(product: productForCart),
        );

        debugPrint('➕ ADD TO CART: Dialog result: $result');

        if (result != null) {
          debugPrint('➕ ADD TO CART: Adding with variants...');
          debugPrint('➕ ADD TO CART: Quantity: ${result['quantity']}');
          debugPrint('➕ ADD TO CART: Variants: ${result['variants']}');
          debugPrint('➕ ADD TO CART: Total Price: ${result['price']}');

          // Calculate unit price from total (dialog returns total = unit * qty)
          final int qty = result['quantity'] as int;
          final double totalPrice = result['price'] as double;
          final double unitPrice = totalPrice / qty;
          final String? optionsStr = result['options'] as String?;
          debugPrint('➕ ADD TO CART: Unit Price: $unitPrice');
          debugPrint('➕ ADD TO CART: Options: $optionsStr');

          await salesProvider.addProductToCart(productForCart,
              quantity: qty, priceOverride: unitPrice, options: optionsStr);

          debugPrint('✅ ADD TO CART: Product added with variants');
        } else {
          debugPrint('⚠️ ADD TO CART: User cancelled variant selection');
        }
      } else {
        debugPrint('➕ ADD TO CART: Product has no variants, direct add...');

        await salesProvider.addProductToCart(productForCart, quantity: 1);

        debugPrint('✅ ADD TO CART: Product added directly');
      }
    } catch (e) {
      debugPrint('❌ ADD TO CART: Error adding product: $e');
      debugPrint('❌ ADD TO CART: Stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    _searchFocusNode.requestFocus();
  }

  void _handleSaveCart() async {
    final salesProvider = context.read<SalesProvider>();

    if (salesProvider.cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    // Show save cart dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const SaveCartDialog(),
    );

    if (result == true && mounted) {
      _barcodeFocusNode.requestFocus();
    }
  }

  /// Quick hold cart without dialog (auto-generated name)
  Future<void> _handleQuickHold() async {
    final salesProvider = context.read<SalesProvider>();
    final authProvider = context.read<AuthProvider>();

    if (salesProvider.cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final success = await salesProvider.quickSaveCart(
      userId: authProvider.user!.id,
      userName: authProvider.user!.name,
    );

    if (!mounted) return;

    if (success) {
      // Reload saved carts list
      await salesProvider.loadSavedCarts(authProvider.user!.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart held successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      _searchFocusNode.requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProvider.error ?? 'Failed to hold cart'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Quick load a saved cart (auto-saves current cart if not empty)
  Future<void> _handleQuickLoad(String cartId) async {
    final salesProvider = context.read<SalesProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final success = await salesProvider.loadCart(
      cartId,
      authProvider.user!.id,
      userName: authProvider.user!.name,
      autoSaveCurrentCart: true,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart loaded!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      _searchFocusNode.requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProvider.error ?? 'Failed to load cart'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleCheckout() async {
    debugPrint('💳 CHECKOUT: _handleCheckout called');
    final salesProvider = context.read<SalesProvider>();

    if (salesProvider.cart.items.isEmpty) {
      debugPrint('⚠️ CHECKOUT: Cart is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    debugPrint('💳 CHECKOUT: Showing payment dialog...');

    // Show payment dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(cart: salesProvider.cart),
    );

    debugPrint('💳 CHECKOUT: Payment dialog result: $result');

    if (result == null) {
      debugPrint('⚠️ CHECKOUT: Payment cancelled');
      return;
    }

    debugPrint('💳 CHECKOUT: Processing checkout...');

    // Process checkout
    final order = await salesProvider.checkout(
      paymentDetails: result['payment_details'],
    );

    if (order != null && mounted) {
      debugPrint(
          '✅ CHECKOUT: Order created successfully - ID: ${order.id}, Code: ${order.code}');

      // Show success toast immediately
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Order ${order.code} completed! Printing...'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );

      // Auto-print in background (don't wait for it)
      _autoPrintReceipt(order);

      // Refresh for new order
      _searchFocusNode.requestFocus();
    } else if (salesProvider.error != null && mounted) {
      debugPrint('❌ CHECKOUT: Error during checkout: ${salesProvider.error}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProvider.error!),
          backgroundColor: AppColors.error,
        ),
      );
      salesProvider.clearError();
    }
  }

  /// Auto-print receipt in background
  Future<void> _autoPrintReceipt(dynamic order) async {
    final autoPrintService = AutoPrintService();

    try {
      final result = await autoPrintService.autoPrint(order);

      if (mounted) {
        if (!result.success && result.didPrint == false) {
          // Show error only if printing was attempted but failed
          if (await autoPrintService.hasDefaultPrinter()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.print_disabled, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(result.message)),
                  ],
                ),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else if (result.didPrint) {
          debugPrint('🖨️ Receipt printed successfully');
        }
      }
    } catch (e) {
      debugPrint('🖨️ Auto-print error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 BUILD: SalesScreen build called');

    return Consumer<PosModeProvider>(
      builder: (context, modeProvider, _) {
        if (modeProvider.isKiosk) {
          return _buildKioskLayout();
        } else {
          return _buildQuickSelectLayout();
        }
      },
    );
  }

  /// Quick Select Mode - Product grid on left, cart on right
  Widget _buildQuickSelectLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // LEFT SIDE - Products (70%)
          Expanded(
            flex: 7,
            child: Column(
              children: [
                // Single Unified Search Bar
                _buildSearchBar(),

                // Product Grid
                Expanded(
                  child: Consumer<SalesProvider>(
                    builder: (context, sales, _) {
                      debugPrint(
                          '🎨 BUILD: Product grid - ${sales.products.length} products, loading: ${sales.isLoading}');

                      if (sales.isLoading && sales.products.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (sales.products.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: sales.products.length,
                        itemBuilder: (context, index) {
                          final product = sales.products[index];
                          return _buildProductCard(product);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // RIGHT SIDE - Cart (30%)
          Expanded(
            flex: 3,
            child: _buildCartPanel(),
          ),
        ],
      ),
    );
  }

  /// Kiosk Mode - Cart on left (scan-focused), checkout panel on right
  Widget _buildKioskLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // LEFT SIDE - Cart with Search (70%)
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                // Main content layer
                Container(
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      // Search bar (without dropdown - dropdown rendered separately)
                      _buildKioskSearchField(),

                      // Horizontal tabs for held carts
                      _buildHeldCartsTabs(),

                      // Cart content
                      Expanded(
                        child: Consumer<SalesProvider>(
                          builder: (context, sales, _) {
                            final cart = sales.cart;

                            if (cart.items.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner_rounded,
                                      size: 80,
                                      color: AppColors.primary.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Scan products to add to cart',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Use barcode scanner or search above',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: cart.items.length,
                              itemBuilder: (context, index) {
                                final item = cart.items[index];
                                return _buildKioskCartItem(item, sales);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Dropdown overlay layer (above everything)
                if (_showSearchDropdown && _searchResults.isNotEmpty)
                  Positioned(
                    top: 72, // Below search bar (16 padding + 56 textfield)
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final product = _searchResults[index];
                            final isSelected = index == _selectedIndex;
                            return InkWell(
                              onTap: () async {
                                debugPrint('🖱️ TAP: Search result tapped - ${product.name}');
                                await _addProductToCart(product);
                                _clearSearch();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Product image
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: product.fullImageUrl != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: Image.network(
                                                product.fullImageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Icon(
                                                  Icons.inventory_2_outlined,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.inventory_2_outlined,
                                              color: AppColors.primary,
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Product details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${product.sku ?? ''} - ${AppCurrency.format(product.finalPrice)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Selection indicator
                                    if (isSelected)
                                      Icon(
                                        Icons.keyboard_return,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // RIGHT SIDE - Checkout Panel (30%)
          Expanded(
            flex: 3,
            child: _buildKioskCheckoutPanel(),
          ),
        ],
      ),
    );
  }

  /// Kiosk search field only (dropdown rendered separately in overlay)
  Widget _buildKioskSearchField() {
    return Consumer<SalesProvider>(
      builder: (context, sales, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Row(
            children: [
              // Search field
              Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
                          _showSearchDropdown &&
                          _searchResults.isNotEmpty) {
                        setState(() {
                          _selectedIndex = (_selectedIndex + 1) % _searchResults.length;
                        });
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
                          _showSearchDropdown &&
                          _searchResults.isNotEmpty) {
                        setState(() {
                          _selectedIndex = (_selectedIndex - 1 + _searchResults.length) % _searchResults.length;
                        });
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                        _clearSearch();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Scan barcode, SKU, or search products...',
                      prefixIcon: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _clearSearch,
                            )
                          : null,
                    ),
                    onSubmitted: (value) async {
                      debugPrint('⏎ ENTER: Submitted with value: "$value"');

                      // If user has selected an item via keyboard, use that
                      if (_selectedIndex >= 0 && _selectedIndex < _searchResults.length) {
                        debugPrint('⏎ ENTER: Using keyboard-selected item at index $_selectedIndex');
                        await _addProductToCart(_searchResults[_selectedIndex]);
                        _clearSearch();
                        return;
                      }

                      if (value.isEmpty) return;

                      // Always try barcode/SKU API first
                      debugPrint('⏎ ENTER: Trying barcode/SKU API...');
                      final product = await context.read<SalesProvider>().scanBarcode(value);

                      if (product != null) {
                        debugPrint('⏎ ENTER: Product found via API: ${product.name}');
                        await _addProductToCart(product);
                        _clearSearch();
                      } else if (_searchResults.length == 1) {
                        debugPrint('⏎ ENTER: Not found via API, using local result');
                        await _addProductToCart(_searchResults.first);
                        _clearSearch();
                      } else if (_searchResults.isNotEmpty) {
                        debugPrint('⏎ ENTER: Multiple local results, use arrow keys to select');
                        if (_selectedIndex < 0) {
                          setState(() => _selectedIndex = 0);
                        }
                      } else {
                        debugPrint('⏎ ENTER: Product not found');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product not found')),
                        );
                      }
                    },
                    onChanged: (value) {
                      setState(() {});
                      _handleSearch(value);
                    },
                  ),
                ),
              ),
              // Delete cart icon (only show if cart has items)
              if (sales.cart.items.isNotEmpty) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _showClearCartDialog(),
                  tooltip: 'Clear cart',
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Horizontal tabs for held carts (Kiosk mode)
  Widget _buildHeldCartsTabs() {
    return Consumer<SalesProvider>(
      builder: (context, sales, _) {
        if (sales.savedCarts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // Current Cart tab (always shown, highlighted)
              _buildCartTab(
                label: 'Current',
                itemCount: sales.cart.items.length,
                isActive: true,
                onTap: null, // Already active
              ),

              const SizedBox(width: 8),

              // Held carts tabs (scrollable)
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sales.savedCarts.length,
                  itemBuilder: (context, index) {
                    final savedCart = sales.savedCarts[index];
                    // Extract short time from cart name
                    final shortName = _getShortCartName(savedCart.name);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildCartTab(
                        label: shortName,
                        itemCount: savedCart.items.length,
                        isActive: false,
                        onTap: () => _handleQuickLoad(savedCart.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Single cart tab widget
  Widget _buildCartTab({
    required String label,
    required int itemCount,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.shopping_cart : Icons.pause_circle_outline,
                size: 16,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$itemCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get short name from cart name (extract time)
  String _getShortCartName(String name) {
    // Cart name format: "Cart - 01/07/2026, 05:12:41 PM"
    // Extract just the time part
    final timeMatch = RegExp(r'(\d{1,2}:\d{2}:\d{2}\s*[AP]M)').firstMatch(name);
    if (timeMatch != null) {
      return timeMatch.group(1) ?? name;
    }
    // Fallback: truncate to 10 chars
    return name.length > 10 ? '${name.substring(0, 10)}...' : name;
  }

  /// Search bar widget (shared between modes)
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none, // Allow dropdown to overflow
              children: [
                Focus(
                  onKeyEvent: (node, event) => _handleSearchKeyEvent(event),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Scan barcode, SKU, or search products...',
                      prefixIcon: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _clearSearch,
                            )
                          : null,
                    ),
                    onSubmitted: (value) async {
                      debugPrint('⏎ ENTER: Submitted with value: "$value"');

                      // If user has selected an item via keyboard, use that
                      if (_selectedIndex >= 0 && _selectedIndex < _searchResults.length) {
                        debugPrint('⏎ ENTER: Using keyboard-selected item at index $_selectedIndex');
                        await _addProductToCart(_searchResults[_selectedIndex]);
                        _clearSearch();
                        return;
                      }

                      if (value.isEmpty) return;

                      // Always try barcode/SKU API first (for any input)
                      debugPrint('⏎ ENTER: Trying barcode/SKU API...');
                      final product = await context.read<SalesProvider>().scanBarcode(value);

                      if (product != null) {
                        debugPrint('⏎ ENTER: Product found via API: ${product.name}');
                        await _addProductToCart(product);
                        _clearSearch();
                      }
                      // If API didn't find it but we have single local result
                      else if (_searchResults.length == 1) {
                        debugPrint('⏎ ENTER: Not found via API, using local result');
                        await _addProductToCart(_searchResults.first);
                        _clearSearch();
                      }
                      // Multiple local results - keep dropdown open
                      else if (_searchResults.isNotEmpty) {
                        debugPrint('⏎ ENTER: Multiple local results, use arrow keys to select');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Use arrow keys to select product')),
                        );
                      }
                      // No results anywhere
                      else {
                        debugPrint('⏎ ENTER: Product not found');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product not found')),
                        );
                      }
                    },
                    onChanged: (value) {
                      setState(() {});
                      _handleSearch(value);
                    },
                  ),
                ),

                // Search Results Dropdown
                if (_showSearchDropdown && _searchResults.isNotEmpty)
                  Positioned(
                    top: 56,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final product = _searchResults[index];
                            final isSelected = index == _selectedIndex;
                            return ListTile(
                              tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                              selected: isSelected,
                              selectedTileColor: AppColors.primary.withOpacity(0.1),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: product.fullImageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          product.fullImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.inventory_2_outlined,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.inventory_2_outlined,
                                        color: AppColors.primary,
                                      ),
                              ),
                              title: Text(product.name),
                              subtitle: Text(
                                '${product.sku ?? ''} - ${AppCurrency.format(product.finalPrice)}',
                              ),
                              trailing: product.hasVariants
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Options',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () async {
                                debugPrint(
                                    '🖱️ UI: Search result tapped - ${product.name}');
                                await _addProductToCart(product);
                                _clearSearch();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Consumer<SalesProvider>(
            builder: (context, sales, _) {
              return IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: sales.isLoading
                      ? AppColors.textSecondary
                      : AppColors.primary,
                ),
                onPressed: sales.isLoading ? null : _handleRefresh,
                tooltip: 'Refresh products',
                iconSize: 28,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Large cart item card for Kiosk mode
  /// Layout: [Image] [SKU/Name/Options] [UnitPrice] [QtyControls] [Total]
  Widget _buildKioskCartItem(dynamic item, SalesProvider sales) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.fullImageUrl != null && item.fullImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.fullImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 32,
                    ),
            ),
            const SizedBox(width: 16),

            // Product Details (3 lines: SKU, Name, Options)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Line 1: SKU
                  if (item.sku != null && item.sku!.isNotEmpty)
                    Text(
                      'SKU: ${item.sku}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // Line 2: Product Name
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Line 3: Options/Variations
                  if (item.options != null && item.options!.isNotEmpty)
                    Text(
                      item.options!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Unit Price
            Text(
              AppCurrency.format(item.price),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(width: 12),

            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      item.quantity == 1
                          ? Icons.delete_outline
                          : Icons.remove,
                      color: item.quantity == 1
                          ? AppColors.error
                          : AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () {
                      if (item.quantity == 1) {
                        sales.removeFromCart(item.productId);
                      } else {
                        sales.updateCartItem(item.productId, item.quantity - 1);
                      }
                    },
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: AppColors.primary, size: 20),
                    onPressed: () {
                      sales.updateCartItem(item.productId, item.quantity + 1);
                    },
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Line Total
            SizedBox(
              width: 90,
              child: Text(
                AppCurrency.format(item.lineTotal),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Checkout panel for Kiosk mode
  Widget _buildKioskCheckoutPanel() {
    final l10n = AppLocalizations.of(context);

    return Consumer<SalesProvider>(
      builder: (context, sales, _) {
        final cart = sales.cart;

        return Container(
          color: AppColors.surface,
          child: Column(
            children: [
              // Scrollable top section (Customer, Delivery, Actions)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Customer Selection
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: CustomerSearchWidget(
                          selectedCustomer: sales.selectedCustomer,
                          onCustomerSelected: (customer) {
                            sales.selectCustomer(customer);
                          },
                          onCustomerRemoved: () {
                            sales.clearCustomer();
                          },
                          onAddNewCustomer: () {
                            _showAddCustomerDialog(sales);
                          },
                          onSearch: (query) async {
                            return await context.read<SalesProvider>().searchCustomers(query);
                          },
                        ),
                      ),

                      // Delivery & Address (only show when customer is selected)
                      if (sales.selectedCustomer != null)
                        DeliveryAddressWidget(
                          customer: sales.selectedCustomer!,
                          deliveryType: sales.deliveryType,
                          selectedAddress: sales.selectedAddress,
                          addresses: sales.customerAddresses,
                          isLoadingAddresses: sales.isLoadingAddresses,
                          onDeliveryTypeChanged: (type) {
                            sales.setDeliveryType(type);
                          },
                          onAddressSelected: (address) {
                            sales.selectAddress(address);
                          },
                          onAddNewAddress: () {
                            _showAddAddressDialog(sales);
                          },
                        ),

                    ],
                  ),
                ),
              ),

              // Fixed bottom section: Action tabs + Order Summary
              if (cart.items.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Action tabs (Coupon | Discount | Shipping)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            // Coupon tab
                            Expanded(
                              child: _buildActionTab(
                                icon: Icons.confirmation_number_outlined,
                                label: 'Coupon',
                                isActive: sales.hasCouponDiscount,
                                onTap: () => _showApplyCouponDialog(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Discount tab (only if no coupon)
                            if (!sales.hasCouponDiscount)
                              Expanded(
                                child: _buildActionTab(
                                  icon: Icons.percent_outlined,
                                  label: 'Discount',
                                  isActive: sales.hasManualDiscount,
                                  onTap: () => _showApplyDiscountDialog(),
                                ),
                              ),
                            if (!sales.hasCouponDiscount)
                              const SizedBox(width: 8),
                            // Shipping tab
                            Expanded(
                              child: _buildActionTab(
                                icon: Icons.local_shipping_outlined,
                                label: 'Shipping',
                                isActive: sales.shippingAmount > 0,
                                onTap: () => _showUpdateShippingDialog(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Order Summary
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Items count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${cart.items.length} ${cart.items.length == 1 ? 'item' : 'items'}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${cart.totalQuantity} units',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildSummaryRow(l10n?.subtotal ?? 'Subtotal', cart.subtotal),
                      if (cart.discount > 0)
                        _buildSummaryRow(
                          l10n?.discount ?? 'Discount',
                          -cart.discount,
                          color: AppColors.success,
                        ),
                      _buildSummaryRow(l10n?.tax ?? 'Tax', cart.tax),
                      if (cart.shipping > 0)
                        _buildSummaryRow('Shipping', cart.shipping),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        l10n?.total ?? 'Total',
                        cart.total,
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),

                      // Hold Button (Quick Save)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleQuickHold,
                          icon: const Icon(Icons.pause_circle_outline),
                          label: const Text('Hold'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Checkout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleCheckout,
                          icon: const Icon(Icons.payment),
                          label: Text(
                            '${l10n?.checkout ?? 'Pay'} - ${AppCurrency.format(cart.total)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Empty state for checkout panel
              if (cart.items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cart is empty',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    debugPrint(
        '🎨 BUILD: Product card - ${product.name}, Image: ${product.fullImageUrl}');

    return Card(
      child: InkWell(
        onTap: () {
          debugPrint('🖱️ UI: Product card tapped - ${product.name}');
          _addProductToCart(product);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: product.fullImageUrl != null && product.fullImageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.fullImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint(
                                    '⚠️ IMAGE: Failed to load ${product.fullImageUrl}');
                                return Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: AppColors.primary,
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Stock Badge & SKU
              if (product.sku != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.sku!,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 4),

              // Product Name
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Price
              Row(
                children: [
                  Text(
                    AppCurrency.format(product.finalPrice),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (product.salePrice != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      AppCurrency.format(product.price),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint(
                        '🖱️ UI: Add to Cart button pressed - ${product.name}');
                    _addProductToCart(product);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    product.hasVariants ? 'Select Options' : 'Add to Cart',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    final l10n = AppLocalizations.of(context);

    return Consumer<SalesProvider>(
      builder: (context, sales, _) {
        final cart = sales.cart;
        debugPrint('🎨 BUILD: Cart panel - ${cart.items.length} items');

        return Container(
          color: AppColors.surface,
          child: Column(
            children: [
              // Cart Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n?.cart ?? 'Cart'} (${cart.items.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (cart.items.isNotEmpty)
                      // Save Cart Button
                      IconButton(
                        icon: const Icon(Icons.save_outlined),
                        onPressed: _handleSaveCart,
                        tooltip: l10n?.saveCart ?? 'Save Cart',
                      ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => _showClearCartDialog(),
                    ),
                  ],
                ),
              ),

              // Cart Items
              Expanded(
                child: cart.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n?.emptyCart ?? 'Your cart is empty',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return CartItemWidget(
                            item: item,
                            onQuantityChanged: (newQty) {
                              debugPrint(
                                  '🛒 CART: Quantity changed for ${item.name} to $newQty');
                              sales.updateCartItem(item.productId, newQty);
                            },
                            onRemove: () {
                              debugPrint('🛒 CART: Removing ${item.name}');
                              sales.removeFromCart(item.productId);
                            },
                          );
                        },
                      ),
              ),

              // Discount/Coupon/Shipping Actions
              if (cart.items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Apply Coupon
                      _buildActionRow(
                        icon: Icons.local_offer_outlined,
                        label: sales.hasCouponDiscount
                            ? 'Coupon: ${sales.couponCode}'
                            : 'Apply Coupon',
                        value: sales.hasCouponDiscount
                            ? '-${AppCurrency.format(sales.couponDiscountAmount)}'
                            : null,
                        valueColor: AppColors.success,
                        onTap: () => _showApplyCouponDialog(),
                        onClear: sales.hasCouponDiscount
                            ? () => sales.clearCouponDiscount()
                            : null,
                      ),
                      // Apply Discount (only if no coupon)
                      if (!sales.hasCouponDiscount)
                        _buildActionRow(
                          icon: Icons.discount_outlined,
                          label: sales.hasManualDiscount
                              ? 'Discount${sales.discountDescription != null ? ': ${sales.discountDescription}' : ''}'
                              : 'Apply Discount',
                          value: sales.hasManualDiscount
                              ? '-${AppCurrency.format(sales.manualDiscountAmount)}'
                              : null,
                          valueColor: AppColors.success,
                          onTap: () => _showApplyDiscountDialog(),
                          onClear: sales.hasManualDiscount
                              ? () => sales.clearManualDiscount()
                              : null,
                        ),
                      // Shipping
                      _buildActionRow(
                        icon: Icons.local_shipping_outlined,
                        label: sales.shippingAmount > 0
                            ? 'Shipping'
                            : 'Add Shipping',
                        value: sales.shippingAmount > 0
                            ? AppCurrency.format(sales.shippingAmount)
                            : null,
                        onTap: () => _showUpdateShippingDialog(),
                        onClear: sales.shippingAmount > 0
                            ? () => sales.clearShippingAmount()
                            : null,
                      ),
                    ],
                  ),
                ),

              // Cart Summary & Checkout
              if (cart.items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(l10n?.subtotal ?? 'Subtotal', cart.subtotal),
                      if (cart.discount > 0)
                        _buildSummaryRow(
                          l10n?.discount ?? 'Discount',
                          -cart.discount,
                          color: AppColors.success,
                        ),
                      _buildSummaryRow(l10n?.tax ?? 'Tax', cart.tax),
                      if (cart.shipping > 0)
                        _buildSummaryRow('Shipping', cart.shipping),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        l10n?.total ?? 'Total',
                        cart.total,
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),

                      // Checkout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleCheckout,
                          icon: const Icon(Icons.payment),
                          label: Text(
                            '${l10n?.checkout ?? 'Checkout'} - ${AppCurrency.format(cart.total)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value, {
    Color? color,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            AppCurrency.format(value),
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    debugPrint('🛒 CART: Show clear cart dialog');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text(
            'Are you sure you want to remove all items from the cart?'),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🛒 CART: Clear cancelled');
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('🛒 CART: Clearing cart');
              context.read<SalesProvider>().clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(SalesProvider sales) {
    showDialog(
      context: context,
      builder: (context) => AddCustomerDialog(
        onSave: (name, phone, email) async {
          await sales.createCustomer(name, phone, email);
        },
      ),
    );
  }

  void _showAddAddressDialog(SalesProvider sales) {
    if (sales.selectedCustomer == null) return;

    showDialog(
      context: context,
      builder: (context) => AddAddressDialog(
        customer: sales.selectedCustomer!,
        onSave: (addressData) async {
          await sales.createCustomerAddress(addressData);
        },
      ),
    );
  }

  /// Compact action tab for discount/coupon/shipping
  Widget _buildActionTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Action row for discount/coupon/shipping (legacy - kept for cart panel)
  Widget _buildActionRow({
    required IconData icon,
    required String label,
    String? value,
    Color? valueColor,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
              ],
            ] else
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  /// Show Apply Coupon Dialog
  Future<void> _showApplyCouponDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ApplyCouponDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon applied successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show Apply Discount Dialog
  Future<void> _showApplyDiscountDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ApplyDiscountDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discount applied successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show Update Shipping Dialog
  Future<void> _showUpdateShippingDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const UpdateShippingDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipping updated!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
