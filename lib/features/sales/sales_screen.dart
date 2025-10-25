import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../sales/sales_provider.dart';
import '../sales/variant_selection_dialog.dart';
import '../sales/customer_search_widget.dart';
import '../sales/cart_item_widget.dart';
import '../sales/payment_dialog.dart';
import '../sales/receipt_dialog.dart';
import '../../core/models/product.dart';
import '../../core/models/cart.dart';
import '../../core/models/customer.dart';
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
  final currencyFormat = NumberFormat.currency(symbol: '\$');

  List<Product> _searchResults = [];
  bool _showSearchDropdown = false;

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

  // ⭐ UNIFIED SEARCH LOGIC
  Future<void> _handleSearch(String query) async {
    debugPrint('🔍 SEARCH: _handleSearch called with query: "$query"');

    if (query.isEmpty) {
      debugPrint('🔍 SEARCH: Query empty, clearing results');
      setState(() {
        _searchResults = [];
        _showSearchDropdown = false;
      });

      // Reload all products
      context.read<SalesProvider>().searchProducts('');
      return;
    }

    debugPrint('🔍 SEARCH: Searching for: "$query"');
    final salesProvider = context.read<SalesProvider>();
    salesProvider.searchProducts(query);

    // For the dropdown, filter current products
    final results = salesProvider.products.where((p) {
      final searchLower = query.toLowerCase();
      final matchName = p.name.toLowerCase().contains(searchLower);
      final matchSku = p.sku?.toLowerCase().contains(searchLower) ?? false;
      final matchBarcode =
          p.barcode?.toLowerCase().contains(searchLower) ?? false;

      return matchName || matchSku || matchBarcode;
    }).toList();

    debugPrint('🔍 SEARCH: Found ${results.length} results');

    setState(() {
      _searchResults = results;
      _showSearchDropdown = true;
    });

    // If exact 1 match, add to cart
    if (results.length == 1) {
      debugPrint('🔍 SEARCH: Exactly 1 result found, auto-adding...');
      await _addProductToCart(results.first);
      _clearSearch();
    } else {
      debugPrint(
          '🔍 SEARCH: Multiple results (${results.length}), showing dropdown');
    }
  }

  void _clearSearch() {
    debugPrint('🔍 SEARCH: _clearSearch called');
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showSearchDropdown = false;
    });
    _searchFocusNode.requestFocus();
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

      // Show receipt
      await showDialog(
        context: context,
        builder: (context) => ReceiptDialog(order: order),
      );

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

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 BUILD: SalesScreen build called');

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
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText:
                                    'Scan barcode, SKU, or search products...',
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
                              onSubmitted: _handleSearch,
                              onChanged: (value) {
                                setState(() {});
                                if (value.isEmpty) {
                                  _handleSearch('');
                                }
                              },
                            ),

                            // Search Results Dropdown
                            if (_showSearchDropdown &&
                                _searchResults.isNotEmpty)
                              Positioned(
                                top: 60,
                                left: 0,
                                right: 0,
                                child: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(maxHeight: 300),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _searchResults.length,
                                      itemBuilder: (context, index) {
                                        final product = _searchResults[index];
                                        return ListTile(
                                          leading: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppColors.background,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.inventory_2_outlined,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          title: Text(product.name),
                                          subtitle: Text(
                                            '${product.sku ?? ''} - ${currencyFormat.format(product.finalPrice)}',
                                          ),
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
                    ],
                  ),
                ),

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
                    currencyFormat.format(product.finalPrice),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (product.salePrice != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      currencyFormat.format(product.price),
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
                      'Cart (${cart.items.length})',
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
                        tooltip: 'Save Cart',
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
                              'Your cart is empty',
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
                      _buildSummaryRow('Subtotal', cart.subtotal),
                      if (cart.discount > 0)
                        _buildSummaryRow(
                          'Discount',
                          -cart.discount,
                          color: AppColors.success,
                        ),
                      if (cart.tax > 0) _buildSummaryRow('Tax', cart.tax),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        'Total',
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
                            'Checkout - ${currencyFormat.format(cart.total)}',
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
            currencyFormat.format(value),
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
