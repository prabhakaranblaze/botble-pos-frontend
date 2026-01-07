import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../shared/constants/app_constants.dart';
import 'sales_provider.dart';

class ApplyDiscountDialog extends StatefulWidget {
  const ApplyDiscountDialog({super.key});

  @override
  State<ApplyDiscountDialog> createState() => _ApplyDiscountDialogState();
}

class _ApplyDiscountDialogState extends State<ApplyDiscountDialog> {
  String _discountType = 'amount'; // 'amount' or 'percentage'
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyDiscount() {
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a discount value';
      });
      return;
    }

    final value = double.tryParse(valueText);
    if (value == null || value <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid positive number';
      });
      return;
    }

    // Validate percentage doesn't exceed 100%
    if (_discountType == 'percentage' && value > 100) {
      setState(() {
        _errorMessage = 'Percentage cannot exceed 100%';
      });
      return;
    }

    final salesProvider = context.read<SalesProvider>();
    final subtotal = salesProvider.cart.subtotal;

    // Calculate discount amount
    double discountAmount;
    if (_discountType == 'percentage') {
      discountAmount = (subtotal * value) / 100;
    } else {
      discountAmount = value;
    }

    // Ensure discount doesn't exceed subtotal
    if (discountAmount > subtotal) {
      discountAmount = subtotal;
    }

    final description = _descriptionController.text.trim();

    salesProvider.applyManualDiscount(
      type: _discountType,
      value: value,
      discountAmount: discountAmount,
      description: description.isNotEmpty ? description : null,
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.discount_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Apply Discount',
                  style: TextStyle(
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

            // Discount Type Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _discountType = 'amount'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _discountType == 'amount'
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Fixed Amount',
                            style: TextStyle(
                              color: _discountType == 'amount'
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _discountType = 'percentage'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _discountType == 'percentage'
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Percentage',
                            style: TextStyle(
                              color: _discountType == 'percentage'
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Value Input
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: _discountType == 'amount' ? 'Amount' : 'Percentage',
                hintText: _discountType == 'amount' ? 'Enter amount' : 'Enter percentage',
                prefixIcon: Icon(
                  _discountType == 'amount' ? Icons.attach_money : Icons.percent,
                ),
                suffixText: _discountType == 'percentage' ? '%' : null,
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
              onSubmitted: (_) => _applyDiscount(),
            ),
            const SizedBox(height: 16),

            // Description Input
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., Staff discount, Loyalty reward',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLength: 100,
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
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyDiscount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply'),
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
