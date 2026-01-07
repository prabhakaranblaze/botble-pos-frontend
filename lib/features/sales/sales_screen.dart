import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../sales/sales_provider.dart';
import '../sales/variant_selection_dialog.dart';
import '../sales/cart_item_widget.dart';
import '../sales/payment_dialog.dart';
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
      _searchFocusNode.requestFocus();
    });
  }

  Future<void> _loadData() async {
    debugPrint('🔵 SALES SCREEN: _loadData() started');
    final salesProvider = context.read<SalesProvider>();

    try {
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

  // ⭐ UNIFIED SEARCH LOGIC (local filtering for autocomplete)
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

    // ✅ Only filter locally - don't call API (to prevent clearing products)
    final results = salesProvider.products.where((p) {
      final searchLower = query.toLowerCase();
      final matchName = p.name.toLowerCase().contains(searchLower);
      final matchSku = p.sku?.toLowerCase().contains(searchLower) ?? false;
      final matchBarcode =
          p.barcode?.toLowerCase().contains(searchLower) ?? false;

      return matchName || matchSku || matchBarcode;
    }).toList();

    debugPrint('🔍 SEARCH: Found ${results.length} results');

    // ✅ Always show dropdown for text search (user can select from list)
    setState(() {
      _searchResults = results;
      _showSearchDropdown = results.isNotEmpty;
      _selectedIndex = results.isNotEmpty ? 0 : -1; // Select first item by default
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

    final salesProvider = context.read<SalesProvider>();

    try {
      if (product.hasVariants) {
        debugPrint('➕ ADD TO CART: Product has variants, showing dialog...');

        // Show variant selection dialog
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => VariantSelectionDialog(product: product),
        );

        debugPrint('➕ ADD TO CART: Dialog result: $result');

        if (result != null) {
          debugPrint('➕ ADD TO CART: Adding with variants...');
          debugPrint('➕ ADD TO CART: Quantity: ${result['quantity']}');
          debugPrint('➕ ADD TO CART: Variants: ${result['variants']}');

          await salesProvider.addToCart(product.id,
              quantity: result['quantity']);

          debugPrint('✅ ADD TO CART: Product added with variants');

          // Play beep sound
          try {
            await salesProvider.audioService.playBeep();
            debugPrint('🔊 ADD TO CART: Beep played');
          } catch (e) {
            debugPrint('⚠️ ADD TO CART: Could not play beep: $e');
          }
        } else {
          debugPrint('⚠️ ADD TO CART: User cancelled variant selection');
        }
      } else {
        debugPrint('➕ ADD TO CART: Product has no variants, direct add...');

        await salesProvider.addToCart(product.id, quantity: 1);

        debugPrint('✅ ADD TO CART: Product added directly');

        // Play beep sound
        try {
          await salesProvider.audioService.playBeep();
          debugPrint('🔊 ADD TO CART: Beep played');
        } catch (e) {
          debugPrint('⚠️ ADD TO CART: Could not play beep: $e');
        }
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
            child: Container(
              color: AppColors.surface,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cart content with top padding for search bar
                  Padding(
                    padding: const EdgeInsets.only(top: 88),
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

                  // Search bar on top (in Stack to allow dropdown overflow)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildSearchBar(),
                  ),
                ],
              ),
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
                                child: product.image != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          product.image!,
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
              child: item.image != null && item.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.image!,
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

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppCurrency.format(item.price),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      item.quantity == 1
                          ? Icons.delete_outline
                          : Icons.remove,
                      color: item.quantity == 1
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                    onPressed: () {
                      if (item.quantity == 1) {
                        sales.removeFromCart(item.productId);
                      } else {
                        sales.updateCartItem(item.productId, item.quantity - 1);
                      }
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: AppColors.primary),
                    onPressed: () {
                      sales.updateCartItem(item.productId, item.quantity + 1);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Line Total
            SizedBox(
              width: 100,
              child: Text(
                AppCurrency.format(item.lineTotal),
                style: TextStyle(
                  fontSize: 16,
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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.checkout ?? 'Checkout',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (cart.items.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => _showClearCartDialog(),
                        tooltip: 'Clear cart',
                      ),
                  ],
                ),
              ),

              // Customer Selection (placeholder)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Walk-in Customer',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Order Summary
              if (cart.items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
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
                      if (cart.tax > 0)
                        _buildSummaryRow(l10n?.tax ?? 'Tax', cart.tax),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        l10n?.total ?? 'Total',
                        cart.total,
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),

                      // Hold Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleSaveCart,
                          icon: const Icon(Icons.pause_circle_outline),
                          label: Text(l10n?.saveCart ?? 'Hold'),
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
        '🎨 BUILD: Product card - ${product.name}, Image: ${product.image}');

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
                    child: product.image != null && product.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.image!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint(
                                    '⚠️ IMAGE: Failed to load ${product.image}');
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
                      if (cart.tax > 0) _buildSummaryRow(l10n?.tax ?? 'Tax', cart.tax),
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
}
