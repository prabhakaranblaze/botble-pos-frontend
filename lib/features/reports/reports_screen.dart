import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import '../../core/api/api_service.dart';
import '../../core/utils/file_helper.dart';
import '../../shared/constants/app_constants.dart';
import '../session/session_provider.dart';
import '../../l10n/generated/app_localizations.dart';

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

  // Session data
  List<dynamic> _sessionOrders = [];
  bool _sessionLoading = false;
  String _sessionPaymentFilter = 'all'; // all, cash, card

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadSessionOrders(); // Load session orders first (default tab)
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        _loadSessionOrders();
        break;
      case 1:
        _loadOrdersReport();
        break;
      case 2:
        _loadProductsReport();
        break;
    }
  }

  Future<void> _loadSessionOrders() async {
    setState(() => _sessionLoading = true);

    try {
      final sessionProvider = context.read<SessionProvider>();
      final activeSession = sessionProvider.activeSession;

      if (activeSession == null) {
        setState(() {
          _sessionOrders = [];
          _sessionLoading = false;
        });
        return;
      }

      // Get orders for current session using session time range
      final api = context.read<ApiService>();
      final openedAt = DateTime.parse(activeSession['opened_at'] as String);

      final data = await api.getOrdersReport(
        fromDate: openedAt,
        toDate: DateTime.now(),
      );

      setState(() {
        _sessionOrders = data['orders'] as List<dynamic>? ?? [];
        _sessionLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading session orders: $e');
      setState(() => _sessionLoading = false);
    }
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedDateFilter) {
      case 'today':
        return (today, today);
      case 'yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return (yesterday, yesterday);
      case 'this_week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return (startOfWeek, today);
      case 'this_month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return (startOfMonth, today);
      case 'custom':
        if (_customFromDate != null && _customToDate != null) {
          return (_customFromDate!, _customToDate!);
        }
        return (today, today);
      default:
        return (today, today);
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
    switch (_tabController.index) {
      case 0:
        _loadSessionOrders();
        break;
      case 1:
        _loadOrdersReport();
        break;
      case 2:
        _loadProductsReport();
        break;
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

      // Save and open file
      final dateStr = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final filename = 'orders_report_$dateStr.csv';
      final success = await FileHelper.saveCsvAndOpen(filename, csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Exported: $filename' : 'Export failed')),
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

      // Save and open file
      final dateStr = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final filename = 'products_report_$dateStr.csv';
      final success = await FileHelper.saveCsvAndOpen(filename, csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Exported: $filename' : 'Export failed')),
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
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(
                            l10n?.reports ?? 'Reports',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      // Export button (hide for Session tab for now)
                      if (_tabController.index != 0)
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return ElevatedButton.icon(
                              onPressed: _tabController.index == 1
                                  ? _exportOrdersToExcel
                                  : _exportProductsToExcel,
                              icon: const Icon(Icons.download, size: 18),
                              label: Text(l10n?.exportCsv ?? 'Export CSV'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      // Refresh button for Session tab
                      if (_tabController.index == 0)
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return ElevatedButton.icon(
                              onPressed: _loadSessionOrders,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text(l10n?.refresh ?? 'Refresh'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Date filters (hide for Session tab)
                if (_tabController.index != 0)
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            _buildDateFilterChip(l10n?.today ?? 'Today', 'today'),
                            const SizedBox(width: 8),
                            _buildDateFilterChip(l10n?.yesterday ?? 'Yesterday', 'yesterday'),
                            const SizedBox(width: 8),
                            _buildDateFilterChip(l10n?.thisWeek ?? 'This Week', 'this_week'),
                            const SizedBox(width: 8),
                            _buildDateFilterChip(l10n?.thisMonth ?? 'This Month', 'this_month'),
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
                                    : (l10n?.customDate ?? 'Custom'),
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
                      );
                    },
                  ),

                if (_tabController.index != 0) const SizedBox(height: 16),

                // Tabs
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: [
                        Tab(text: l10n?.session ?? 'Session'),
                        Tab(text: l10n?.orders ?? 'Orders'),
                        Tab(text: l10n?.products ?? 'Products Sold'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSessionTab(),
                _buildOrdersTab(),
                _buildProductsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTab() {
    final sessionProvider = context.watch<SessionProvider>();
    final activeSession = sessionProvider.activeSession;

    // Filter orders based on payment filter
    final filteredOrders = _sessionPaymentFilter == 'all'
        ? _sessionOrders
        : _sessionOrders.where((order) {
            final method = order['payment_method']?.toString() ?? '';
            if (_sessionPaymentFilter == 'cash') {
              return method.contains('cash');
            } else {
              return method.contains('card');
            }
          }).toList();

    // Calculate stats
    final totalOrders = filteredOrders.length;
    final cashOrders = _sessionOrders.where((o) =>
        (o['payment_method']?.toString() ?? '').contains('cash')).toList();
    final cardOrders = _sessionOrders.where((o) =>
        (o['payment_method']?.toString() ?? '').contains('card')).toList();
    final cashTotal = cashOrders.fold<double>(
        0, (sum, o) => sum + ((o['amount'] as num?)?.toDouble() ?? 0));
    final cardTotal = cardOrders.fold<double>(
        0, (sum, o) => sum + ((o['amount'] as num?)?.toDouble() ?? 0));

    return Column(
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.05),
          child: Row(
            children: [
              _buildSummaryItem(
                AppLocalizations.of(context)?.totalOrders ?? 'Total Orders',
                '$totalOrders',
                Icons.receipt_long,
              ),
              const SizedBox(width: 32),
              _buildSummaryItem(
                AppLocalizations.of(context)?.cash ?? 'Cash',
                AppCurrency.format(cashTotal),
                Icons.money,
              ),
              const SizedBox(width: 32),
              _buildSummaryItem(
                AppLocalizations.of(context)?.card ?? 'Card',
                AppCurrency.format(cardTotal),
                Icons.credit_card,
              ),
              const Spacer(),
              // Payment filter
              Row(
                children: [
                  Text('${AppLocalizations.of(context)?.filter ?? 'Filter'}: ', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context)?.all ?? 'All'),
                    selected: _sessionPaymentFilter == 'all',
                    onSelected: (selected) {
                      if (selected) setState(() => _sessionPaymentFilter = 'all');
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _sessionPaymentFilter == 'all' ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context)?.cash ?? 'Cash'),
                    selected: _sessionPaymentFilter == 'cash',
                    onSelected: (selected) {
                      if (selected) setState(() => _sessionPaymentFilter = 'cash');
                    },
                    selectedColor: AppColors.success,
                    labelStyle: TextStyle(
                      color: _sessionPaymentFilter == 'cash' ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context)?.card ?? 'Card'),
                    selected: _sessionPaymentFilter == 'card',
                    onSelected: (selected) {
                      if (selected) setState(() => _sessionPaymentFilter = 'card');
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _sessionPaymentFilter == 'card' ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Session orders list
        Expanded(
          child: activeSession == null
              ? _buildEmptyState(AppLocalizations.of(context)?.noActiveSessionMessage ?? 'No active session')
              : _sessionLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredOrders.isEmpty
                      ? _buildEmptyState(AppLocalizations.of(context)?.noTransactionsYet ?? 'No transactions yet')
                      : _buildSessionOrdersList(filteredOrders),
        ),
      ],
    );
  }

  Widget _buildSessionOrdersList(List<dynamic> orders) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.surface),
        columns: [
          DataColumn(label: Text(l10n?.orderNumber ?? 'Order #')),
          DataColumn(label: Text(l10n?.customer ?? 'Customer')),
          DataColumn(label: Text(l10n?.total ?? 'Total'), numeric: true),
          DataColumn(label: Text(l10n?.mode ?? 'Mode')),
          DataColumn(label: Text(l10n?.status ?? 'Status')),
        ],
        rows: orders.map((order) {
          return DataRow(
            cells: [
              DataCell(Text(
                order['code']?.toString() ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
              DataCell(Text(order['customer_name']?.toString() ?? (AppLocalizations.of(context)?.walkIn ?? 'Walk-in'))),
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
                AppLocalizations.of(context)?.orders ?? 'Orders',
                '${_ordersSummary['total_orders'] ?? _orders.length}',
                Icons.receipt_long,
              ),
              _buildSummaryItem(
                AppLocalizations.of(context)?.revenue ?? 'Revenue',
                AppCurrency.format((_ordersSummary['total_revenue'] as num?)?.toDouble() ?? 0),
                Icons.attach_money,
              ),
              _buildSummaryItem(
                AppLocalizations.of(context)?.avgOrder ?? 'Avg Order',
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
                  ? _buildEmptyState(AppLocalizations.of(context)?.noOrdersFound ?? 'No orders found')
                  : _buildOrdersList(),
        ),
      ],
    );
  }

  Widget _buildOrdersList() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.surface),
        columns: [
          DataColumn(label: Text(l10n?.orderNumber ?? 'Order #')),
          DataColumn(label: Text(l10n?.dateTime ?? 'Date/Time')),
          DataColumn(label: Text(l10n?.customer ?? 'Customer')),
          DataColumn(label: Text(l10n?.items ?? 'Items'), numeric: true),
          DataColumn(label: Text(l10n?.total ?? 'Total'), numeric: true),
          DataColumn(label: Text(l10n?.payment ?? 'Payment')),
          DataColumn(label: Text(l10n?.status ?? 'Status')),
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
              DataCell(Text(order['customer_name']?.toString() ?? (AppLocalizations.of(context)?.walkIn ?? 'Walk-in'))),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Summary bar with sort
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.05),
          child: Row(
            children: [
              _buildSummaryItem(
                l10n?.products ?? 'Products',
                '${_productsSummary['total_products'] ?? _products.length}',
                Icons.inventory,
              ),
              const SizedBox(width: 24),
              _buildSummaryItem(
                l10n?.unitsSold ?? 'Units Sold',
                '${_productsSummary['total_quantity'] ?? 0}',
                Icons.shopping_cart,
              ),
              const SizedBox(width: 24),
              _buildSummaryItem(
                l10n?.revenue ?? 'Revenue',
                AppCurrency.format((_productsSummary['total_revenue'] as num?)?.toDouble() ?? 0),
                Icons.attach_money,
              ),
              const Spacer(),
              // Sort dropdown
              Row(
                children: [
                  Text('${l10n?.sortBy ?? 'Sort by'}: ', style: TextStyle(color: AppColors.textSecondary)),
                  DropdownButton<String>(
                    value: _productsSortBy,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'quantity', child: Text(l10n?.quantity ?? 'Quantity')),
                      DropdownMenuItem(value: 'revenue', child: Text(l10n?.revenue ?? 'Revenue')),
                      DropdownMenuItem(value: 'name', child: Text(l10n?.name ?? 'Name')),
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
                    tooltip: _productsSortOrder == 'desc' ? (l10n?.descending ?? 'Descending') : (l10n?.ascending ?? 'Ascending'),
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
                  ? _buildEmptyState(l10n?.noProductsSold ?? 'No products sold')
                  : _buildProductsList(),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.surface),
        columns: [
          DataColumn(label: Text(l10n?.product ?? 'Product')),
          DataColumn(label: Text(l10n?.sku ?? 'SKU')),
          DataColumn(label: Text(l10n?.variation ?? 'Variation')),
          DataColumn(label: Text(l10n?.qtySold ?? 'Qty Sold'), numeric: true),
          DataColumn(label: Text(l10n?.revenue ?? 'Revenue'), numeric: true),
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
