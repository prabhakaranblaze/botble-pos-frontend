import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../shared/constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';
import 'sales_provider.dart';

class UpdateShippingDialog extends StatefulWidget {
  const UpdateShippingDialog({super.key});

  @override
  State<UpdateShippingDialog> createState() => _UpdateShippingDialogState();
}

class _UpdateShippingDialogState extends State<UpdateShippingDialog> {
  final _amountController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current shipping amount if any
    final salesProvider = context.read<SalesProvider>();
    if (salesProvider.shippingAmount > 0) {
      _amountController.text = salesProvider.shippingAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateShipping() {
    final amountText = _amountController.text.trim();

    // Allow empty to clear shipping
    if (amountText.isEmpty) {
      context.read<SalesProvider>().clearShippingAmount();
      Navigator.pop(context, true);
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount < 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    context.read<SalesProvider>().setShippingAmount(amount);
    Navigator.pop(context, true);
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
                Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  l10n?.updateShipping ?? 'Update Shipping',
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

            // Amount Input
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: l10n?.shippingAmount ?? 'Shipping Amount',
                hintText: l10n?.enterShippingAmount ?? 'Enter shipping amount',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: 'Rs',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _errorMessage,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              autofocus: true,
              onSubmitted: (_) => _updateShipping(),
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
                    onPressed: _updateShipping,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n?.update ?? 'Update'),
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
