import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/service/address_service.dart';
import 'package:martfury/src/model/address.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/view/screen/add_edit_address_screen.dart';

class ManageAddressScreen extends StatefulWidget {
  const ManageAddressScreen({super.key});

  @override
  State<ManageAddressScreen> createState() => _ManageAddressScreenState();
}

class _ManageAddressScreenState extends State<ManageAddressScreen> {
  final AddressService _addressService = AddressService();
  List<Address> _addresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final addresses = await _addressService.getAddresses();
      setState(() {
        _addresses = addresses;
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
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'address.manage_addresses'.tr(),
          style: kAppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditAddressScreen(),
                ),
              );
              if (result == true) {
                _loadAddresses();
              }
            },
            icon: const Icon(Icons.add),
            color: Colors.black,
            iconSize: 24,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAddresses,
        color: primaryColor,
        child:
            _isLoading
                ? _buildLoadingState()
                : _error != null
                ? _buildErrorState()
                : _addresses.isEmpty
                ? _buildEmptyState()
                : _buildAddressList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.getSkeletonColor(context),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.getSkeletonColor(context),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.red[900]!.withValues(alpha: 0.2)
                        : Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.red[300]
                        : Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'common.error_occurred'.tr(),
              style: kAppTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: kAppTextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadAddresses,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'address.no_addresses'.tr(),
              style: kAppTextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'address.no_addresses_description'.tr(),
              style: kAppTextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'address.add_new_hint'.tr(),
              style: kAppTextStyle(
                fontSize: 12,
                color: AppColors.getHintTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        return _buildAddressCard(address);
      },
    );
  }

  Widget _buildAddressCard(Address address) {
    const primaryColor = AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border:
            address.isDefault
                ? Border.all(color: primaryColor, width: 2)
                : Border.all(
                  color: AppColors.getBorderColor(context),
                  width: 1,
                ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Radio button for default selection
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      address.isDefault
                          ? primaryColor
                          : AppColors.getBorderColor(context),
                  width: 2,
                ),
                color: address.isDefault ? primaryColor : Colors.transparent,
              ),
              child:
                  address.isDefault
                      ? const Icon(Icons.circle, size: 12, color: Colors.white)
                      : null,
            ),
            const SizedBox(width: 16),

            // Address content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and phone in one row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address.name,
                          style: kAppTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getPrimaryTextColor(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        address.phone,
                        style: kAppTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getPrimaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Full address
                  Text(
                    address.computedFullAddress,
                    style: kAppTextStyle(
                      fontSize: 14,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Edit button
            IconButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddEditAddressScreen(address: address),
                  ),
                );
                if (result == true) {
                  _loadAddresses();
                }
              },
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.getSecondaryTextColor(context),
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }
}
