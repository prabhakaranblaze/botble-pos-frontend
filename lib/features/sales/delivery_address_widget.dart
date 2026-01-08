import 'package:flutter/material.dart';
import '../../shared/constants/app_constants.dart';
import '../../core/models/customer.dart';
import '../../core/models/customer_address.dart';

enum DeliveryType { pickup, ship }

class DeliveryAddressWidget extends StatefulWidget {
  final Customer customer;
  final DeliveryType deliveryType;
  final CustomerAddress? selectedAddress;
  final List<CustomerAddress> addresses;
  final bool isLoadingAddresses;
  final ValueChanged<DeliveryType> onDeliveryTypeChanged;
  final ValueChanged<CustomerAddress?> onAddressSelected;
  final VoidCallback onAddNewAddress;

  const DeliveryAddressWidget({
    super.key,
    required this.customer,
    required this.deliveryType,
    this.selectedAddress,
    required this.addresses,
    this.isLoadingAddresses = false,
    required this.onDeliveryTypeChanged,
    required this.onAddressSelected,
    required this.onAddNewAddress,
  });

  @override
  State<DeliveryAddressWidget> createState() => _DeliveryAddressWidgetState();
}

class _DeliveryAddressWidgetState extends State<DeliveryAddressWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with inline delivery type toggle
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Delivery',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Inline radio-style toggle (right-aligned)
                _buildInlineToggle(
                  label: 'Walk in',
                  isSelected: widget.deliveryType == DeliveryType.pickup,
                  onTap: () => widget.onDeliveryTypeChanged(DeliveryType.pickup),
                ),
                const SizedBox(width: 12),
                _buildInlineToggle(
                  label: 'Deliver',
                  isSelected: widget.deliveryType == DeliveryType.ship,
                  onTap: () => widget.onDeliveryTypeChanged(DeliveryType.ship),
                ),
              ],
            ),

            // Address Selection (only for Ship)
            if (widget.deliveryType == DeliveryType.ship) ...[
              const SizedBox(height: 12),

              if (widget.isLoadingAddresses)
                const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (widget.addresses.isEmpty)
                // No addresses - compact state
                _buildNoAddressStateCompact()
              else
                // Has addresses - compact dropdown with add icon
                _buildCompactAddressDropdown(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInlineToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAddressStateCompact() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'No saved addresses',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: widget.onAddNewAddress,
          icon: Icon(Icons.add_location_alt_outlined, color: AppColors.primary, size: 22),
          tooltip: 'Add New Address',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildCompactAddressDropdown() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CustomerAddress>(
                value: widget.selectedAddress,
                isExpanded: true,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Select address',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                isDense: true,
                items: widget.addresses.map((address) {
                  return DropdownMenuItem<CustomerAddress>(
                    value: address,
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address.displayText,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(fontSize: 9, color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (address) => widget.onAddressSelected(address),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: widget.onAddNewAddress,
          icon: Icon(Icons.add_location_alt_outlined, color: AppColors.primary, size: 22),
          tooltip: 'Add New Address',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

}
