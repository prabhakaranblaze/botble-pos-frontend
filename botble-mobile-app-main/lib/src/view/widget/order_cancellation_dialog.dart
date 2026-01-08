import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';

class OrderCancellationDialog extends StatefulWidget {
  final Function(String reason, String? description) onConfirm;

  const OrderCancellationDialog({super.key, required this.onConfirm});

  @override
  State<OrderCancellationDialog> createState() =>
      _OrderCancellationDialogState();
}

class _OrderCancellationDialogState extends State<OrderCancellationDialog> {
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, String>> _cancellationReasons = [
    {'key': 'change-mind', 'label': 'orders.cancellation_reason_change_mind'},
    {
      'key': 'found-better-price',
      'label': 'orders.cancellation_reason_found_better_price',
    },
    {'key': 'out-of-stock', 'label': 'orders.cancellation_reason_out_of_stock'},
    {
      'key': 'shipping-delays',
      'label': 'orders.cancellation_reason_shipping_delays',
    },
    {
      'key': 'incorrect-address',
      'label': 'orders.cancellation_reason_incorrect_address',
    },
    {
      'key': 'customer-requested',
      'label': 'orders.cancellation_reason_customer_requested',
    },
    {
      'key': 'not-as-described',
      'label': 'orders.cancellation_reason_not_as_described',
    },
    {
      'key': 'payment-issues',
      'label': 'orders.cancellation_reason_payment_issues',
    },
    {
      'key': 'unforeseen-circumstances',
      'label': 'orders.cancellation_reason_unforeseen_circumstances',
    },
    {
      'key': 'technical-issues',
      'label': 'orders.cancellation_reason_technical_issues',
    },
    {'key': 'other', 'label': 'orders.cancellation_reason_other'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleConfirm() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('orders.cancellation_reason_required'.tr()),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onConfirm(
        _selectedReason!,
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.8; // 80% of screen height

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 350, maxHeight: maxDialogHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        color: Color(0xFFF44336),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'orders.cancel_order_confirmation'.tr(),
                          style: kAppTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimaryTextColor(context),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.getSecondaryTextColor(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Confirmation message
                  Text(
                    'orders.cancel_order_confirmation_message'.tr(),
                    style: kAppTextStyle(
                      fontSize: 13,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cancellation reason selection
                    Text(
                      'orders.cancellation_reason'.tr(),
                      style: kAppTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Reason dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedReason,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.getBorderColor(context),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.getBorderColor(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      hint: Text(
                        'orders.cancellation_reason_required'.tr(),
                        style: kAppTextStyle(
                          fontSize: 13,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                      ),
                      items:
                          _cancellationReasons.map((reason) {
                            return DropdownMenuItem<String>(
                              value: reason['key'],
                              child: Text(
                                reason['label']!.tr(),
                                style: kAppTextStyle(
                                  fontSize: 13,
                                  color: AppColors.getPrimaryTextColor(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged:
                          _isLoading
                              ? null
                              : (value) {
                                setState(() {
                                  _selectedReason = value;
                                });
                              },
                      style: kAppTextStyle(
                        fontSize: 13,
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                      dropdownColor: AppColors.getCardBackgroundColor(context),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                      isExpanded: true,
                      menuMaxHeight: 200,
                    ),
                    const SizedBox(height: 16),

                    // Additional description
                    Text(
                      'orders.cancellation_description'.tr(),
                      style: kAppTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _descriptionController,
                      enabled: !_isLoading,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'orders.cancellation_description_placeholder'.tr(),
                        hintStyle: kAppTextStyle(
                          fontSize: 13,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.getBorderColor(context),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.getBorderColor(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        isDense: true,
                      ),
                      style: kAppTextStyle(
                        fontSize: 13,
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(
                                color: AppColors.getBorderColor(context),
                              ),
                            ),
                            child: Text(
                              'common.cancel'.tr(),
                              style: kAppTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF44336),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'orders.cancel_order'.tr(),
                                      style: kAppTextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
          ],
        ),
      ),
    );
  }
}
