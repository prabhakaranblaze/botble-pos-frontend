import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../sales/sales_provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/constants/app_constants.dart';

class SavedCartsScreen extends StatefulWidget {
  final VoidCallback? onCartLoaded;

  const SavedCartsScreen({super.key, this.onCartLoaded});

  @override
  State<SavedCartsScreen> createState() => _SavedCartsScreenState();
}

class _SavedCartsScreenState extends State<SavedCartsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedCarts();
    });
  }

  Future<void> _loadSavedCarts() async {
    final authProvider = context.read<AuthProvider>();
    final salesProvider = context.read<SalesProvider>();

    if (authProvider.user != null) {
      await salesProvider.loadSavedCarts(authProvider.user!.id);
    }
  }

  Future<void> _handleLoadCart(String cartId) async {
    debugPrint('🔵 SAVED CARTS: _handleLoadCart called with cartId: $cartId');

    // Check if active cart has items
    final salesProvider = context.read<SalesProvider>();

    debugPrint(
        '🔵 SAVED CARTS: Current cart items: ${salesProvider.cart.items.length}');

    if (salesProvider.cart.items.isNotEmpty) {
      debugPrint('⚠️ SAVED CARTS: Cart has items, showing confirmation dialog');

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Load Cart?'),
          content: const Text(
            'You have items in your current cart. Loading a saved cart will clear them. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Load Cart'),
            ),
          ],
        ),
      );

      debugPrint('🔵 SAVED CARTS: Confirmation result: $confirm');

      if (confirm != true) {
        debugPrint('❌ SAVED CARTS: User cancelled, aborting');
        return;
      }
    }

    debugPrint('🔵 SAVED CARTS: Getting auth provider...');
    final authProvider = context.read<AuthProvider>();

    debugPrint('🔵 SAVED CARTS: User ID: ${authProvider.user?.id}');
    debugPrint('🔵 SAVED CARTS: Calling loadCart...');

    final success = await salesProvider.loadCart(
      cartId,
      authProvider.user!.id,
    );

    debugPrint('🔵 SAVED CARTS: loadCart returned: $success');

    if (!mounted) {
      debugPrint('⚠️ SAVED CARTS: Widget not mounted, aborting');
      return;
    }

    debugPrint('🔵 SAVED CARTS: Widget still mounted, showing result');

    if (success) {
      debugPrint('✅ SAVED CARTS: Cart loaded successfully');
      debugPrint(
          '🔵 SAVED CARTS: New cart items: ${salesProvider.cart.items.length}');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart loaded! Switch to Sale tab to checkout'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );

      debugPrint('✅ SAVED CARTS: Success message shown');

      // Switch to Sale tab
      if (widget.onCartLoaded != null) {
        debugPrint('🔵 SAVED CARTS: Calling onCartLoaded callback');
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          widget.onCartLoaded!();
          debugPrint('✅ SAVED CARTS: Tab switch triggered');
        }
      }
    } else {
      debugPrint('❌ SAVED CARTS: Failed to load cart');
      debugPrint('❌ SAVED CARTS: Error: ${salesProvider.error}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProvider.error ?? 'Failed to load cart'),
          backgroundColor: AppColors.error,
        ),
      );

      debugPrint('❌ SAVED CARTS: Error message shown');
    }

    debugPrint('🔵 SAVED CARTS: _handleLoadCart completed');
  }

  Future<void> _handleDeleteCart(String cartId, String cartName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cart?'),
        content: Text('Delete "$cartName"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authProvider = context.read<AuthProvider>();
    final salesProvider = context.read<SalesProvider>();

    final success = await salesProvider.deleteSavedCart(
      cartId,
      authProvider.user!.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProvider.error ?? 'Failed to delete cart'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, sales, _) {
        if (sales.savedCarts.isEmpty) {
          return Center(
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
                  'No saved carts',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Save a cart from the sales screen',
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
          itemCount: sales.savedCarts.length,
          itemBuilder: (context, index) {
            final cart = sales.savedCarts[index];
            return _buildCartCard(cart);
          },
        );
      },
    );
  }

  Widget _buildCartCard(cart) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          cart.isOnline ? Icons.cloud_done : Icons.storage,
          color: cart.isOnline ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                cart.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (cart.isOnline)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${cart.onlineId}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  cart.userName,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (cart.customerName != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${cart.customerName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            Text(
              dateFormat.format(cart.savedAt),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Items
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} x ${item.quantity}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            AppCurrency.format(item.total),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )),

                const Divider(height: 24),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sub Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppCurrency.format(cart.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleDeleteCart(cart.id, cart.name),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleLoadCart(cart.id),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Continue Checkout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
