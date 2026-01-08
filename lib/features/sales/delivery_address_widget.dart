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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Delivery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Delivery Type Toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleOption(
                      icon: Icons.store,
                      label: 'Pickup at Store',
                      isSelected: widget.deliveryType == DeliveryType.pickup,
                      onTap: () => widget.onDeliveryTypeChanged(DeliveryType.pickup),
                    ),
                  ),
                  Expanded(
                    child: _buildToggleOption(
                      icon: Icons.local_shipping,
                      label: 'Ship to Address',
                      isSelected: widget.deliveryType == DeliveryType.ship,
                      onTap: () => widget.onDeliveryTypeChanged(DeliveryType.ship),
                    ),
                  ),
                ],
              ),
            ),

            // Address Selection (only for Ship)
            if (widget.deliveryType == DeliveryType.ship) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              if (widget.isLoadingAddresses)
                const Center(child: CircularProgressIndicator())
              else if (widget.addresses.isEmpty)
                // No addresses - show add button
                _buildNoAddressState()
              else
                // Has addresses - show dropdown
                _buildAddressDropdown(),

              const SizedBox(height: 12),

              // Add New Address button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onAddNewAddress,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Address'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAddressState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            'No saved addresses',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an address for delivery',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Address',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
                  'Select an address',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: widget.addresses.map((address) {
                return DropdownMenuItem<CustomerAddress>(
                  value: address,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              address.displayText,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (address.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (address.phone != null)
                        Text(
                          address.phone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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

        // Selected address details
        if (widget.selectedAddress != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.selectedAddress!.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.selectedAddress!.displayText,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (widget.selectedAddress!.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.selectedAddress!.phone!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
