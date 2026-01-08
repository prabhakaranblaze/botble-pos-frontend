import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';
import 'sales_provider.dart';

class ApplyCouponDialog extends StatefulWidget {
  const ApplyCouponDialog({super.key});

  @override
  State<ApplyCouponDialog> createState() => _ApplyCouponDialogState();
}

class _ApplyCouponDialogState extends State<ApplyCouponDialog> {
  final _couponController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    final l10n = AppLocalizations.of(context);
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = l10n?.pleaseEnterCouponCode ?? 'Please enter a coupon code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final salesProvider = context.read<SalesProvider>();
      final result = await salesProvider.validateCoupon(code);

      if (!mounted) return;

      if (result != null && result['valid'] == true) {
        final discount = result['discount'] as Map<String, dynamic>;
        final discountId = discount['id'] as int;
        final discountAmount = (discount['discount_amount'] as num).toDouble();
        final discountCode = discount['code'] as String;

        salesProvider.applyCouponDiscount(
          discountId: discountId,
          code: discountCode,
          discountAmount: discountAmount,
        );

        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = result?['message'] ?? l10n?.invalidCouponCode ?? 'Invalid coupon code';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  l10n?.applyCoupon ?? 'Apply Coupon',
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
            const SizedBox(height: 24),

            // Coupon Input
            TextField(
              controller: _couponController,
              decoration: InputDecoration(
                labelText: l10n?.couponCode ?? 'Coupon Code',
                hintText: l10n?.enterCouponCode ?? 'Enter coupon code',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _errorMessage,
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
              onSubmitted: (_) => _validateCoupon(),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n?.cancel ?? 'Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n?.apply ?? 'Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
