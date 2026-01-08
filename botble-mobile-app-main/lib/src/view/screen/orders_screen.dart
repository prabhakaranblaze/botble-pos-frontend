import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/service/order_service.dart';
import 'package:martfury/src/model/order.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/view/screen/order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final String? initialFilter;

  const OrdersScreen({super.key, this.initialFilter});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';
  String _selectedSort = 'newest';

  @override
  void initState() {
    super.initState();
    // Set initial filter if provided
    if (widget.initialFilter != null) {
      _selectedFilter = widget.initialFilter!;
    }
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _orderService.getOrders();

      setState(() {
        _orders = orders;
        _filteredOrders = orders;
        _isLoading = false;
      });
      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    List<Order> filtered = List.from(_orders);

    // Apply filter
    if (_selectedFilter != 'all') {
      filtered =
          filtered
              .where(
                (order) =>
                    order.status.value.toLowerCase() ==
                    _selectedFilter.toLowerCase(),
              )
              .toList();
    }

    // Apply sort
    switch (_selectedSort) {
      case 'newest':
        filtered.sort(
          (a, b) => DateTime.parse(
            b.createdAt,
          ).compareTo(DateTime.parse(a.createdAt)),
        );
        break;
      case 'oldest':
        filtered.sort(
          (a, b) => DateTime.parse(
            a.createdAt,
          ).compareTo(DateTime.parse(b.createdAt)),
        );
        break;
      case 'amount_high':
        filtered.sort(
          (a, b) => double.parse(b.amount).compareTo(double.parse(a.amount)),
        );
        break;
      case 'amount_low':
        filtered.sort(
          (a, b) => double.parse(a.amount).compareTo(double.parse(b.amount)),
        );
        break;
    }

    setState(() {
      _filteredOrders = filtered;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFB800);
      case 'processing':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'canceled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orders.status_pending'.tr();
      case 'processing':
        return 'orders.status_processing'.tr();
      case 'completed':
        return 'orders.status_completed'.tr();
      case 'canceled':
        return 'orders.status_cancelled'.tr();
      default:
        return status;
    }
  }

  String _getRelativeDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('dd MMM yyyy').format(date);
    } else if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'orders.time_days_ago_single'.tr();
      } else {
        return 'orders.time_days_ago_multiple'.tr(
          namedArgs: {'count': difference.inDays.toString()},
        );
      }
    } else if (difference.inHours > 0) {
      if (difference.inHours == 1) {
        return 'orders.time_hours_ago_single'.tr();
      } else {
        return 'orders.time_hours_ago_multiple'.tr(
          namedArgs: {'count': difference.inHours.toString()},
        );
      }
    } else if (difference.inMinutes > 0) {
      if (difference.inMinutes == 1) {
        return 'orders.time_minutes_ago_single'.tr();
      } else {
        return 'orders.time_minutes_ago_multiple'.tr(
          namedArgs: {'count': difference.inMinutes.toString()},
        );
      }
    } else {
      return 'orders.time_just_now'.tr();
    }
  }

  String _getItemCountText(int count) {
    if (count == 1) {
      return 'orders.item_count_single'.tr();
    } else {
      return 'orders.item_count_multiple'.tr(
        namedArgs: {'count': count.toString()},
      );
    }
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'orders.filter_all'.tr()},
      {'key': 'pending', 'label': 'orders.filter_pending'.tr()},
      {'key': 'processing', 'label': 'orders.filter_processing'.tr()},
      {'key': 'completed', 'label': 'orders.filter_completed'.tr()},
      {'key': 'canceled', 'label': 'orders.filter_canceled'.tr()},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key']!;
                });
                _applyFiltersAndSort();
              },
              backgroundColor: AppColors.getBackgroundColor(context),
              selectedColor: AppColors.primary.withAlpha(50),
              labelStyle: kAppTextStyle(
                color:
                    isSelected
                        ? AppColors.primary
                        : AppColors.getSecondaryTextColor(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color:
                    isSelected
                        ? AppColors.primary
                        : AppColors.getBorderColor(context),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _selectedSort = value;
        });
        _applyFiltersAndSort();
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'newest',
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'orders.sort_newest'.tr(),
                      style: kAppTextStyle(
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'oldest',
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 20,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'orders.sort_oldest'.tr(),
                      style: kAppTextStyle(
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'amount_high',
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 20,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'orders.sort_amount_high'.tr(),
                      style: kAppTextStyle(
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'amount_low',
              child: Row(
                children: [
                  Icon(
                    Icons.trending_down,
                    size: 20,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'orders.sort_amount_low'.tr(),
                      style: kAppTextStyle(
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 20, color: Colors.black),
            const SizedBox(width: 4),
            Text(
              'orders.sort'.tr(),
              style: kAppTextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildFilterChips(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) => _buildShimmerCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.getSkeletonColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.getBorderColor(context), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with order number and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getBackgroundColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 100,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 70,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 90,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppColors.getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'orders.title'.tr(),
          style: kAppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildSortButton(),
          ),
        ],
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'orders.error_title'.tr(),
                      style: kAppTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: kAppTextStyle(
                        fontSize: 14,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadOrders,
                      icon: const Icon(Icons.refresh),
                      label: Text('common.retry'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : _orders.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.getBackgroundColor(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'orders.no_orders'.tr(),
                      style: kAppTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'orders.no_orders_description'.tr(),
                      textAlign: TextAlign.center,
                      style: kAppTextStyle(
                        fontSize: 14,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              )
              : _filteredOrders.isEmpty
              ? Column(
                children: [
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.getBackgroundColor(context),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.filter_list_off,
                              size: 64,
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'orders.no_filtered_orders'.tr(),
                            style: kAppTextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getPrimaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'orders.no_filtered_orders_description'.tr(),
                            textAlign: TextAlign.center,
                            style: kAppTextStyle(
                              fontSize: 14,
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
              : Column(
                children: [
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                  // Orders count
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'orders.orders_count'.tr(
                        namedArgs: {'count': _filteredOrders.length.toString()},
                      ),
                      style: kAppTextStyle(
                        fontSize: 13,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.getCardBackgroundColor(context),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.getSkeletonColor(
                                    context,
                                  ).withValues(alpha: 0.1),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: _getStatusColor(
                                  order.status.value,
                                ).withAlpha(50),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            OrderDetailScreen(order: order),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with order number and status
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'orders.order_number'.tr(
                                                  namedArgs: {'id': order.code},
                                                ),
                                                style: kAppTextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppColors.getPrimaryTextColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _getRelativeDate(
                                                  order.createdAt,
                                                ),
                                                style: kAppTextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppColors.getSecondaryTextColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              order.status.value,
                                            ).withAlpha(30),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getStatusIcon(
                                                  order.status.value,
                                                ),
                                                size: 14,
                                                color: _getStatusColor(
                                                  order.status.value,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getStatusText(
                                                  order.status.value,
                                                ),
                                                style: kAppTextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getStatusColor(
                                                    order.status.value,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Order details
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.getBackgroundColor(
                                          context,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.shopping_bag_outlined,
                                                size: 16,
                                                color:
                                                    AppColors.getSecondaryTextColor(
                                                      context,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _getItemCountText(
                                                  order.productsCount,
                                                ),
                                                style: kAppTextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      AppColors.getSecondaryTextColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                order.amountFormatted,
                                                style: kAppTextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.payment,
                                                size: 16,
                                                color:
                                                    AppColors.getSecondaryTextColor(
                                                      context,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                order.paymentMethod.label,
                                                style: kAppTextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppColors.getSecondaryTextColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Icon(
                                                Icons.local_shipping,
                                                size: 16,
                                                color:
                                                    AppColors.getSecondaryTextColor(
                                                      context,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                order.shippingMethod.label,
                                                style: kAppTextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppColors.getSecondaryTextColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Action buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          OrderDetailScreen(
                                                            order: order,
                                                          ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.visibility_outlined,
                                              size: 16,
                                            ),
                                            label: Text(
                                              'orders.view_details'.tr(),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.getSecondaryTextColor(
                                                    context,
                                                  ),
                                              side: BorderSide(
                                                color: AppColors.getBorderColor(
                                                  context,
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
