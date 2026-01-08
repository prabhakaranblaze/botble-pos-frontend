import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_service.dart';
import '../../core/models/cart.dart';
import '../../core/services/thermal_print_service.dart';
import '../../core/services/auto_print_service.dart';
import '../../shared/constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';

/// Dialog to display recent bills for reprinting
class RecentBillsDialog extends StatefulWidget {
  const RecentBillsDialog({super.key});

  @override
  State<RecentBillsDialog> createState() => _RecentBillsDialogState();
}

class _RecentBillsDialogState extends State<RecentBillsDialog> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ThermalPrintService _printService = ThermalPrintService();

  @override
  void initState() {
    super.initState();
    _loadRecentOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentOrders() async {
    setState(() => _isLoading = true);

    try {
      final apiService = context.read<ApiService>();
      final orders = await apiService.getRecentOrders(
        limit: 20,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reprintOrder(Order order) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Check if we have a default printer
      final autoPrintService = AutoPrintService();
      final hasPrinter = await autoPrintService.hasDefaultPrinter();

      if (!hasPrinter) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          _showError('No printer configured. Please set up a printer in Settings.');
        }
        return;
      }

      // Print the receipt
      final result = await autoPrintService.autoPrint(order);

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result.didPrint) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Receipt printed for ${order.code}'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          _showError(result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showError('Print failed: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _loadRecentOrders();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  l10n?.orders ?? 'Recent Bills',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n?.searchByOrderCode ?? 'Search by order code...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onSubmitted: _onSearch,
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == _searchController.text) {
                    _onSearch(value);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Orders List Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n?.orderCode ?? 'Order Code',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n?.orderDate ?? 'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      l10n?.amount ?? 'Amount',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 80), // Space for action button
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Orders List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n?.noResults ?? 'No orders found',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            return _buildOrderRow(order, dateFormat, l10n);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(Order order, DateFormat dateFormat, AppLocalizations? l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showOrderDetails(order),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Order Code
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.code,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Date
                Expanded(
                  flex: 2,
                  child: Text(
                    dateFormat.format(order.createdAt),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                // Amount
                Expanded(
                  flex: 1,
                  child: Text(
                    AppCurrency.format(order.amount),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                // Reprint Button
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print, size: 16),
                  label: Text(l10n?.printReceipt ?? 'Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => _reprintOrder(order),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Order ${order.code}'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Info
              _buildDetailRow(l10n?.orderDate ?? 'Date', dateFormat.format(order.createdAt)),
              _buildDetailRow(l10n?.paymentMethod ?? 'Payment', _formatPaymentMethod(order.paymentMethod)),
              const Divider(height: 24),

              // Items
              Text(
                '${l10n?.items ?? 'Items'} (${order.items.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.name),
                    ),
                    Text('x${item.quantity}'),
                    const SizedBox(width: 16),
                    Text(AppCurrency.format(item.total)),
                  ],
                ),
              )),

              const Divider(height: 24),

              // Totals
              _buildDetailRow(l10n?.subtotal ?? 'Subtotal', AppCurrency.format(order.subTotal)),
              if (order.taxAmount > 0)
                _buildDetailRow(l10n?.tax ?? 'Tax', AppCurrency.format(order.taxAmount)),
              if (order.discountAmount > 0)
                _buildDetailRow(l10n?.discount ?? 'Discount', '-${AppCurrency.format(order.discountAmount)}'),
              if (order.shippingAmount > 0)
                _buildDetailRow(l10n?.shipping ?? 'Shipping', AppCurrency.format(order.shippingAmount)),
              const Divider(height: 16),
              _buildDetailRow(
                l10n?.total ?? 'Total',
                AppCurrency.format(order.amount),
                isBold: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.close ?? 'Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: Text(l10n?.printReceipt ?? 'Print Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _reprintOrder(order);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    final l10n = AppLocalizations.of(context);
    switch (method.toLowerCase()) {
      case 'pos_cash':
      case 'cash':
        return l10n?.cash ?? 'Cash';
      case 'pos_card':
      case 'card':
        return l10n?.card ?? 'Card';
      default:
        return method;
    }
  }
}
