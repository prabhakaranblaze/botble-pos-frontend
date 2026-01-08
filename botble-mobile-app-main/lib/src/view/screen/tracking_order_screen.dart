import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/service/order_service.dart';
import 'package:martfury/src/service/profile_service.dart';
import 'package:martfury/src/service/token_service.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';

class TrackingOrderScreen extends StatefulWidget {
  const TrackingOrderScreen({super.key});

  @override
  State<TrackingOrderScreen> createState() => _TrackingOrderScreenState();
}

class _TrackingOrderScreenState extends State<TrackingOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _orderService = OrderService();
  final _profileService = ProfileService();
  bool _isLoading = false;
  bool _isLoadingProfile = false;
  String? _error;
  Map<String, dynamic>? _trackingInfo;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Check if user is authenticated
      final token = await TokenService.getToken();
      if (token != null) {
        setState(() {
          _isLoadingProfile = true;
        });

        // Get user profile data
        final profileData = await _profileService.getProfile();

        // Prefill email if available
        if (profileData['email'] != null && profileData['email'].isNotEmpty) {
          _emailController.text = profileData['email'];
        }

        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      // Silently handle errors - user might not be logged in or network issues
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _trackOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _trackingInfo = null;
    });

    try {
      final trackingInfo = await _orderService.trackOrder(
        code: _orderCodeController.text,
        email: _emailController.text,
      );

      setState(() {
        _trackingInfo = trackingInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _orderCodeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'orders.track_order'.tr(),
          style: kAppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              color: AppColors.getCardBackgroundColor(context),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'orders.track_order'.tr(),
                    style: kAppTextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getPrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'orders.track_order_description'.tr(),
                    style: kAppTextStyle(
                      fontSize: 16,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Form Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getCardBackgroundColor(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.getSkeletonColor(
                      context,
                    ).withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'common.enter_details'.tr(),
                      style: kAppTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _orderCodeController,
                      style: kAppTextStyle(
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                      decoration: InputDecoration(
                        labelText: 'orders.order_code'.tr(),
                        labelStyle: kAppTextStyle(
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                        hintText: 'e.g. #SF-10000049',
                        hintStyle: kAppTextStyle(
                          color: AppColors.getHintTextColor(context),
                        ),
                        prefixIcon: Icon(
                          Icons.receipt_long,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getBorderColor(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.getBackgroundColor(context),
                        helperStyle: kAppTextStyle(
                          fontSize: 12,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'orders.order_code_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      style: kAppTextStyle(
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                      decoration: InputDecoration(
                        labelText: 'common.email'.tr(),
                        labelStyle: kAppTextStyle(
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                        hintText: 'your-email@company.com',
                        hintStyle: kAppTextStyle(
                          color: AppColors.getHintTextColor(context),
                        ),
                        prefixIcon:
                            _isLoadingProfile
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.getSecondaryTextColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                : Icon(
                                  Icons.email_outlined,
                                  color: AppColors.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getBorderColor(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.getBackgroundColor(context),
                        helperText:
                            'Use the email from your order confirmation',
                        helperStyle: kAppTextStyle(
                          fontSize: 12,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'common.email_required'.tr();
                        }
                        if (!value.contains('@')) {
                          return 'orders.invalid_email'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _trackOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.search,
                                      size: 20,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'orders.track'.tr(),
                                      style: kAppTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Help Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue[900]!.withValues(alpha: 0.2)
                        : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue[700]!
                          : Colors.blue[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.blue[300]
                                : Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'orders.tracking_help_title'.tr(),
                        style: kAppTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.blue[300]
                                  : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'orders.tracking_help_description'.tr(),
                    style: kAppTextStyle(
                      fontSize: 12,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue[400]
                              : Colors.blue[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• For testing: Use "#SF-10000049" as order code\n• Use "customer@botble.com" as email\n• Check your email for order confirmation details',
                    style: kAppTextStyle(
                      fontSize: 12,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue[400]
                              : Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Error State
            if (_error != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.red[900]!.withValues(alpha: 0.2)
                          : Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.red[700]!
                            : Colors.red[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.red[800]!.withValues(alpha: 0.3)
                                : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.red[300]
                                : Colors.red[700],
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'common.error_occurred'.tr(),
                      style: kAppTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.red[300]
                                : Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: kAppTextStyle(
                        fontSize: 14,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.red[400]
                                : Colors.red[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _error = null;
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text('common.try_again'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.red[700]
                                : Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Tracking Information
            if (_trackingInfo != null) ...[
              const SizedBox(height: 16),

              // Success Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'orders.order_found'.tr(),
                            style: kAppTextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'orders.tracking_details_below'.tr(),
                            style: kAppTextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Order Status Timeline
              if (_trackingInfo!['order'] != null) _buildOrderTimeline(),

              // Order Information Card
              if (_trackingInfo!['order'] != null) _buildOrderInfoCard(),

              // Shipping Information Card
              if (_trackingInfo!['shipment'] != null) _buildShippingInfoCard(),

              // Payment Information Card
              if (_trackingInfo!['payment'] != null) _buildPaymentInfoCard(),

              // Order Items Card
              if (_trackingInfo!['order'] != null &&
                  _trackingInfo!['order']['products'] != null)
                _buildOrderItemsCard(),

              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimeline() {
    final order = _trackingInfo!['order'];
    final status =
        order['status']?['value']?.toString().toLowerCase() ?? 'pending';

    final steps = [
      {
        'key': 'pending',
        'title': 'orders.status_pending'.tr(),
        'icon': Icons.receipt_long,
        'description': 'orders.status_pending_desc'.tr(),
      },
      {
        'key': 'processing',
        'title': 'orders.status_processing'.tr(),
        'icon': Icons.inventory_2,
        'description': 'orders.status_processing_desc'.tr(),
      },
      {
        'key': 'shipped',
        'title': 'orders.status_shipped'.tr(),
        'icon': Icons.local_shipping,
        'description': 'orders.status_shipped_desc'.tr(),
      },
      {
        'key': 'delivered',
        'title': 'orders.status_delivered'.tr(),
        'icon': Icons.check_circle,
        'description': 'orders.status_delivered_desc'.tr(),
      },
    ];

    final currentStepIndex = steps.indexWhere((step) => step['key'] == status);
    final activeStepIndex = currentStepIndex >= 0 ? currentStepIndex : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getSkeletonColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'orders.order_progress'.tr(),
                style: kAppTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = index <= activeStepIndex;
            final isCurrent = index == activeStepIndex;

            return _buildTimelineStep(
              step: step,
              isActive: isActive,
              isCurrent: isCurrent,
              isLast: index == steps.length - 1,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required Map<String, dynamic> step,
    required bool isActive,
    required bool isCurrent,
    required bool isLast,
  }) {
    final color = isActive ? AppColors.primary : Colors.grey[400]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? color : AppColors.getBackgroundColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                step['icon'] as IconData,
                color:
                    isActive
                        ? Colors.white
                        : AppColors.getSecondaryTextColor(context),
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isActive ? color : AppColors.getBorderColor(context),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'] as String,
                  style: kAppTextStyle(
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color:
                        isActive
                            ? AppColors.getPrimaryTextColor(context)
                            : AppColors.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step['description'] as String,
                  style: kAppTextStyle(
                    fontSize: 14,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
                if (isCurrent)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'orders.current_status'.tr(),
                      style: kAppTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfoCard() {
    final order = _trackingInfo!['order'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getSkeletonColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'orders.order_information'.tr(),
                style: kAppTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'orders.order_number_label'.tr(),
            order['code'] ?? 'N/A',
            icon: Icons.tag,
            copyable: true,
          ),
          _buildInfoRow(
            'orders.order_date_label'.tr(),
            _formatDate(order['created_at']),
            icon: Icons.calendar_today,
          ),
          _buildInfoRow(
            'orders.total_amount_label'.tr(),
            order['amount_formatted'] ?? order['amount']?.toString() ?? 'N/A',
            icon: Icons.attach_money,
            highlight: true,
          ),
          if (order['tax_amount'] != null)
            _buildInfoRow(
              'orders.tax_amount_label'.tr(),
              order['tax_amount_formatted'] ??
                  order['tax_amount']?.toString() ??
                  'N/A',
              icon: Icons.receipt,
            ),
          if (order['shipping_amount'] != null)
            _buildInfoRow(
              'orders.shipping_amount_label'.tr(),
              order['shipping_amount_formatted'] ??
                  order['shipping_amount']?.toString() ??
                  'N/A',
              icon: Icons.local_shipping,
            ),
        ],
      ),
    );
  }

  Widget _buildShippingInfoCard() {
    final shipment = _trackingInfo!['shipment'];
    final order = _trackingInfo!['order'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getSkeletonColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'orders.shipping_information'.tr(),
                style: kAppTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (shipment['tracking_id'] != null)
            _buildInfoRow(
              'orders.tracking_id'.tr(),
              shipment['tracking_id'],
              icon: Icons.qr_code,
              copyable: true,
            ),
          if (shipment['shipping_company_name'] != null)
            _buildInfoRow(
              'orders.shipping_company'.tr(),
              shipment['shipping_company_name'],
              icon: Icons.business,
            ),
          if (order['shipping_method'] != null)
            _buildInfoRow(
              'orders.shipping_method'.tr(),
              order['shipping_method']['label'] ?? 'N/A',
              icon: Icons.delivery_dining,
            ),
          if (shipment['estimate_date_shipped'] != null)
            _buildInfoRow(
              'orders.estimated_delivery'.tr(),
              _formatDate(shipment['estimate_date_shipped']),
              icon: Icons.schedule,
              highlight: true,
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    final payment = _trackingInfo!['payment'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getSkeletonColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payment, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'orders.payment_information'.tr(),
                style: kAppTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (payment['payment_channel'] != null)
            _buildInfoRow(
              'orders.payment_method'.tr(),
              payment['payment_channel']['label'] ?? 'N/A',
              icon: Icons.credit_card,
            ),
          if (payment['status'] != null)
            _buildStatusRow(
              'orders.payment_status'.tr(),
              payment['status']['label'] ?? 'N/A',
              payment['status']['value'] ?? 'pending',
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    final products = _trackingInfo!['order']['products'] as List;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getSkeletonColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'orders.order_items'.tr(),
                style: kAppTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryTextColor(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getBackgroundColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${products.length} ${'common.items'.tr()}',
                  style: kAppTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...products.map((product) => _buildProductItem(product)).toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.getSkeletonColor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                product['product_image'] != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product['product_image'],
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.image_not_supported,
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                      ),
                    )
                    : Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['product_name'] ?? 'N/A',
                  style: kAppTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getPrimaryTextColor(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'common.qty'.tr(),
                      style: kAppTextStyle(
                        fontSize: 12,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                    Text(
                      ': ${product['qty'] ?? 0}',
                      style: kAppTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      product['price_formatted'] ??
                          product['price']?.toString() ??
                          'N/A',
                      style: kAppTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    bool copyable = false,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: AppColors.getSecondaryTextColor(context),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: kAppTextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: kAppTextStyle(
                      fontSize: 14,
                      fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                      color:
                          highlight
                              ? AppColors.primary
                              : AppColors.getPrimaryTextColor(context),
                    ),
                  ),
                ),
                if (copyable)
                  GestureDetector(
                    onTap: () => _copyToClipboard(value),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
      case 'delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'processing':
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'cancelled':
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.payment,
            size: 16,
            color: AppColors.getSecondaryTextColor(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: kAppTextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: kAppTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('common.copied_to_clipboard'.tr()),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
}
