import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../sales/sales_provider.dart';
import '../sales/payment_dialog.dart';
import '../sales/receipt_dialog.dart';
import '../../core/models/product.dart';
import '../../core/models/cart.dart';
import '../../shared/constants/app_constants.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  final currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();

    // Load data AFTER the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _barcodeFocusNode.requestFocus();
    });
  }

  Future<void> _loadData() async {
    print('🔵 SALES SCREEN: Loading data...');
    final salesProvider = context.read<SalesProvider>();

    try {
      print('🔵 SALES SCREEN: Loading categories...');
      await salesProvider.loadCategories();
      print('✅ SALES SCREEN: Categories loaded');

      print('🔵 SALES SCREEN: Loading products...');
      await salesProvider.loadProducts(refresh: true);
      print(
          '✅ SALES SCREEN: Products loaded - Count: ${salesProvider.products.length}');
    } catch (e) {
      print('❌ SALES SCREEN: Error loading data: $e');
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _searchController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeSubmit(String barcode) async {
    if (barcode.isEmpty) return;

    final salesProvider = context.read<SalesProvider>();
    await salesProvider.scanBarcode(barcode);

    _barcodeController.clear();

    if (salesProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProvider.error!),
          backgroundColor: AppColors.error,
        ),
      );
      salesProvider.clearError();
    }

    // Refocus barcode scanner
    _barcodeFocusNode.requestFocus();
  }

  void _handleCheckout() async {
    final salesProvider = context.read<SalesProvider>();

    if (salesProvider.cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    // Show payment dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(cart: salesProvider.cart),
    );

    if (result == null) return;

    // Process checkout
    final order = await salesProvider.checkout(
      paymentDetails: result['payment_details'],
    );

    if (order != null && mounted) {
      // Show receipt
      await showDialog(
        context: context,
        builder: (context) => ReceiptDialog(order: order),
      );

      _barcodeFocusNode.requestFocus();
    } else if (salesProvider.error != null && mounted) {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Side - Products (70%)
          Expanded(
            flex: 7,
            child: Column(
              children: [
                // Search Bar and Barcode Scanner
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      // Barcode Scanner Input
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _barcodeController,
                          focusNode: _barcodeFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Scan barcode or enter code...',
                            prefixIcon:
                                const Icon(Icons.qr_code_scanner_rounded),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _barcodeController.clear();
                                _barcodeFocusNode.requestFocus();
                              },
                            ),
                          ),
                          onSubmitted: _handleBarcodeSubmit,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Search Input
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _searchController.clear();
                                      context
                                          .read<SalesProvider>()
                                          .searchProducts('');
                                      setState(() {}); // Trigger rebuild
                                      _barcodeFocusNode.requestFocus();
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            context.read<SalesProvider>().searchProducts(value);
                            setState(() {}); // Trigger rebuild
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Product Grid
                Expanded(
                  child: Consumer<SalesProvider>(
                    builder: (context, sales, _) {
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

                      // ✅ THIS IS THE MISSING CODE (lines 235-390)
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: sales.products.length,
                        itemBuilder: (context, index) {
                          final product = sales.products[index];
                          return _buildProductCard(product, sales);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right Side - Cart (30%)
          Expanded(
            flex: 3,
            child: _buildCartPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, SalesProvider sales) {
    return Card(
      child: InkWell(
        onTap: () {
          sales.addToCart(product.id);
          _barcodeFocusNode.requestFocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Placeholder
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

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
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear Cart?'),
                              content:
                                  const Text('Remove all items from cart?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    sales.clearCart();
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
                        },
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
                              'Cart is empty',
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
                          return _buildCartItem(item, sales);
                        },
                      ),
              ),

              // Cart Summary
              if (cart.items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                          'Subtotal', currencyFormat.format(cart.subtotal)),
                      if (cart.discount > 0)
                        _buildSummaryRow(
                          'Discount',
                          '-${currencyFormat.format(cart.discount)}',
                          color: AppColors.success,
                        ),
                      if (cart.tax > 0)
                        _buildSummaryRow(
                            'Tax', currencyFormat.format(cart.tax)),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        'Total',
                        currencyFormat.format(cart.total),
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),

                      // Checkout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleCheckout,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: AppColors.success,
                          ),
                          child: const Text(
                            'Checkout',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildCartItem(CartItem item, SalesProvider sales) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)} each',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    sales.updateCartItem(item.productId, item.quantity - 1);
                  },
                  iconSize: 24,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    sales.updateCartItem(item.productId, item.quantity + 1);
                  },
                  iconSize: 24,
                ),
              ],
            ),

            // Total
            Text(
              '\$${item.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
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
            value,
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
}
