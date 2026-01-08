import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../core/api/api_service.dart';
import '../../shared/constants/app_constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Date filter
  String _selectedDateFilter = 'today';
  DateTime? _customFromDate;
  DateTime? _customToDate;

  // Orders data
  List<dynamic> _orders = [];
  Map<String, dynamic> _ordersSummary = {};
  bool _ordersLoading = false;

  // Products data
  List<dynamic> _products = [];
  Map<String, dynamic> _productsSummary = {};
  bool _productsLoading = false;
  String _productsSortBy = 'quantity';
  String _productsSortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadOrdersReport();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      _loadOrdersReport();
    } else {
      _loadProductsReport();
    }
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedDateFilter) {
      case 'today':
        return (today, today.add(const Duration(days: 1)));
      case 'yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return (yesterday, today);
      case 'this_week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return (startOfWeek, today.add(const Duration(days: 1)));
      case 'this_month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return (startOfMonth, today.add(const Duration(days: 1)));
      case 'custom':
        if (_customFromDate != null && _customToDate != null) {
          return (_customFromDate!, _customToDate!.add(const Duration(days: 1)));
        }
        return (today, today.add(const Duration(days: 1)));
      default:
        return (today, today.add(const Duration(days: 1)));
    }
  }

  Future<void> _loadOrdersReport() async {
    setState(() => _ordersLoading = true);

    try {
      final api = context.read<ApiService>();
      final (fromDate, toDate) = _getDateRange();

      final data = await api.getOrdersReport(
        fromDate: fromDate,
        toDate: toDate,
      );

      setState(() {
        _orders = data['orders'] as List<dynamic>? ?? [];
        _ordersSummary = data['summary'] as Map<String, dynamic>? ?? {};
        _ordersLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading orders report: $e');
      setState(() => _ordersLoading = false);
    }
  }

  Future<void> _loadProductsReport() async {
    setState(() => _productsLoading = true);

    try {
      final api = context.read<ApiService>();
      final (fromDate, toDate) = _getDateRange();

      final data = await api.getProductsReport(
        fromDate: fromDate,
        toDate: toDate,
        sortBy: _productsSortBy,
        sortOrder: _productsSortOrder,
      );

      setState(() {
        _products = data['products'] as List<dynamic>? ?? [];
        _productsSummary = data['summary'] as Map<String, dynamic>? ?? {};
        _productsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products report: $e');
      setState(() => _productsLoading = false);
    }
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customFromDate != null && _customToDate != null
          ? DateTimeRange(start: _customFromDate!, end: _customToDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateFilter = 'custom';
        _customFromDate = picked.start;
        _customToDate = picked.end;
      });
      _refreshCurrentTab();
    }
  }

  void _refreshCurrentTab() {
    if (_tabController.index == 0) {
      _loadOrdersReport();
    } else {
      _loadProductsReport();
    }
  }

  Future<void> _exportOrdersToExcel() async {
    if (_orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No orders to export')),
      );
      return;
    }

    try {
      final List<List<dynamic>> rows = [];

      // Header row
      rows.add([
        'Order #',
        'Date',
        'Customer',
        'Items',
        'Subtotal',
        'Tax',
        'Discount',
        'Total',
        'Payment',
        'Status',
      ]);

      // Data rows
      for (final order in _orders) {
        rows.add([
          order['code']?.toString() ?? '',
          order['created_at']?.toString() ?? '',
          order['customer_name']?.toString() ?? 'Walk-in',
          order['items_count'] ?? 0,
          (order['sub_total'] as num?)?.toDouble() ?? 0,
          (order['tax_amount'] as num?)?.toDouble() ?? 0,
          (order['discount_amount'] as num?)?.toDouble() ?? 0,
          (order['amount'] as num?)?.toDouble() ?? 0,
          order['payment_method']?.toString() ?? '',
          order['status']?.toString() ?? '',
        ]);
      }

      // Summary rows
      rows.add([]);
      rows.add(['Total Orders:', _ordersSummary['total_orders'] ?? _orders.length]);
      rows.add(['Total Revenue:', (_ordersSummary['total_revenue'] as num?)?.toDouble() ?? 0]);

      // Convert to CSV
      final csv = const ListToCsvConverter().convert(rows);

      // Save file
      final dir = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/orders_report_$dateStr.csv');
      await file.writeAsString(csv);

      await OpenFile.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportProductsToExcel() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products to export')),
      );
      return;
    }

    try {
      final List<List<dynamic>> rows = [];

      // Header row
      rows.add([
        'Product',
        'SKU',
        'Variation',
        'Qty Sold',
        'Revenue',
      ]);

      // Data rows
      for (final product in _products) {
        rows.add([
          product['name']?.toString() ?? '',
          product['sku']?.toString() ?? '',
          product['variation']?.toString() ?? '-',
          product['quantity'] ?? 0,
          (product['revenue'] as num?)?.toDouble() ?? 0,
        ]);
      }

      // Summary rows
      rows.add([]);
      rows.add(['Total Products:', _productsSummary['total_products'] ?? _products.length]);
      rows.add(['Total Units Sold:', _productsSummary['total_quantity'] ?? 0]);
      rows.add(['Total Revenue:', (_productsSummary['total_revenue'] as num?)?.toDouble() ?? 0]);

      // Convert to CSV
      final csv = const ListToCsvConverter().convert(rows);

      // Save file
      final dir = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/products_report_$dateStr.csv');
      await file.writeAsString(csv);

      await OpenFile.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with tabs
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                // Title and Export button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Export button
                      ElevatedButton.icon(
                        onPressed: _tabController.index == 0
                            ? _exportOrdersToExcel
                            : _exportProductsToExcel,
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Export CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Date filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildDateFilterChip('Today', 'today'),
                      const SizedBox(width: 8),
                      _buildDateFilterChip('Yesterday', 'yesterday'),
                      const SizedBox(width: 8),
                      _buildDateFilterChip('This Week', 'this_week'),
                      const SizedBox(width: 8),
                      _buildDateFilterChip('This Month', 'this_month'),
                      const SizedBox(width: 8),
                      // Custom date range
                      ActionChip(
                        avatar: Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: _selectedDateFilter == 'custom'
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        label: Text(
                          _selectedDateFilter == 'custom' &&
                                  _customFromDate != null &&
                                  _customToDate != null
                              ? '${DateFormat('MMM d').format(_customFromDate!)} - ${DateFormat('MMM d').format(_customToDate!)}'
                              : 'Custom',
                          style: TextStyle(
                            color: _selectedDateFilter == 'custom'
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        backgroundColor: _selectedDateFilter == 'custom'
                            ? AppColors.primary
                            : AppColors.background,
                        onPressed: _selectCustomDateRange,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Orders'),
                    Tab(text: 'Products Sold'),
                  ],
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(),
                _buildProductsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip(String label, String value) {
    final isSelected = _selectedDateFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedDateFilter = value);
          _refreshCurrentTab();
        }
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Orders',
                '${_ordersSummary['total_orders'] ?? _orders.length}',
                Icons.receipt_long,
              ),
              _buildSummaryItem(
                'Revenue',
                AppCurrency.format((_ordersSummary['total_revenue'] as num?)?.toDouble() ?? 0),
                Icons.attach_money,
              ),
              _buildSummaryItem(
                'Avg Order',
                AppCurrency.format((_ordersSummary['average_order'] as num?)?.toDouble() ?? 0),
                Icons.trending_up,
              ),
            ],
          ),
        ),

        // Orders list
        Expanded(
          child: _ordersLoading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
                  ? _buildEmptyState('No orders found')
                  : _buildOrdersList(),
        ),
      ],
    );
  }

  Widget _buildOrdersList() {
    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.surface),
        columns: const [
          DataColumn(label: Text('Order #')),
          DataColumn(label: Text('Date/Time')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Items'), numeric: true),
          DataColumn(label: Text('Total'), numeric: true),
          DataColumn(label: Text('Payment')),
          DataColumn(label: Text('Status')),
        ],
        rows: _orders.map((order) {
          final createdAt = order['created_at'] != null
              ? DateTime.tryParse(order['created_at'].toString())
              : null;

          return DataRow(
            cells: [
              DataCell(Text(
                order['code']?.toString() ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
              DataCell(Text(
                createdAt != null
                    ? DateFormat('MMM d, HH:mm').format(createdAt)
                    : '-',
              )),
              DataCell(Text(order['customer_name']?.toString() ?? 'Walk-in')),
              DataCell(Text('${order['items_count'] ?? 0}')),
              DataCell(Text(
                AppCurrency.format((order['amount'] as num?)?.toDouble() ?? 0),
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
              DataCell(_buildPaymentBadge(order['payment_method']?.toString())),
              DataCell(_buildStatusBadge(order['status']?.toString())),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        // Summary bar with sort
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.05),
          child: Row(
            children: [
              _buildSummaryItem(
                'Products',
                '${_productsSummary['total_products'] ?? _products.length}',
                Icons.inventory,
              ),
              const SizedBox(width: 24),
              _buildSummaryItem(
                'Units Sold',
                '${_productsSummary['total_quantity'] ?? 0}',
                Icons.shopping_cart,
              ),
              const SizedBox(width: 24),
              _buildSummaryItem(
                'Revenue',
                AppCurrency.format((_productsSummary['total_revenue'] as num?)?.toDouble() ?? 0),
                Icons.attach_money,
              ),
              const Spacer(),
              // Sort dropdown
              Row(
                children: [
                  Text('Sort by: ', style: TextStyle(color: AppColors.textSecondary)),
                  DropdownButton<String>(
                    value: _productsSortBy,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'quantity', child: Text('Quantity')),
                      DropdownMenuItem(value: 'revenue', child: Text('Revenue')),
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _productsSortBy = value);
                        _loadProductsReport();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _productsSortOrder == 'desc'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _productsSortOrder =
                            _productsSortOrder == 'desc' ? 'asc' : 'desc';
                      });
                      _loadProductsReport();
                    },
                    tooltip: _productsSortOrder == 'desc' ? 'Descending' : 'Ascending',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Products list
        Expanded(
          child: _productsLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? _buildEmptyState('No products sold')
                  : _buildProductsList(),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.surface),
        columns: const [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('SKU')),
          DataColumn(label: Text('Variation')),
          DataColumn(label: Text('Qty Sold'), numeric: true),
          DataColumn(label: Text('Revenue'), numeric: true),
        ],
        rows: _products.map((product) {
          return DataRow(
            cells: [
              DataCell(Text(
                product['name']?.toString() ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
              DataCell(Text(product['sku']?.toString() ?? '-')),
              DataCell(Text(product['variation']?.toString() ?? '-')),
              DataCell(Text(
                '${product['quantity'] ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
              DataCell(Text(
                AppCurrency.format((product['revenue'] as num?)?.toDouble() ?? 0),
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentBadge(String? method) {
    final isCard = method?.contains('card') ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCard
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method == 'pos_cash' ? 'Cash' : method == 'pos_card' ? 'Card' : method ?? '-',
        style: TextStyle(
          fontSize: 12,
          color: isCard ? AppColors.primary : AppColors.success,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    switch (status?.toLowerCase()) {
      case 'completed':
        color = AppColors.success;
        break;
      case 'pending':
        color = AppColors.warning;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status ?? '-',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
