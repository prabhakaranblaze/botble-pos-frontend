import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/models/cart.dart';
import '../session/session_provider.dart';
import '../../shared/constants/app_constants.dart';

class PaymentDialog extends StatefulWidget {
  final Cart cart;

  const PaymentDialog({super.key, required this.cart});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _paymentMethod = 'pos_cash'; // Laravel-style payment method
  final _cashReceivedController = TextEditingController();
  final _cardDigitsController = TextEditingController();
  final Map<int, int> _denominationCounts = {};

  double get _cashReceived {
    if (_paymentMethod == 'pos_cash' && _cashReceivedController.text.isNotEmpty) {
      return double.tryParse(_cashReceivedController.text) ?? 0;
    }
    return 0;
  }

  double get _change => _cashReceived - widget.cart.total;

  @override
  void dispose() {
    _cashReceivedController.dispose();
    _cardDigitsController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_paymentMethod == 'pos_cash') {
      if (_cashReceived < widget.cart.total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient cash received')),
        );
        return;
      }

      Navigator.pop(context, {
        'payment_method': 'pos_cash',
        'payment_details': 'Cash: \$${_cashReceived.toStringAsFixed(2)}, Change: \$${_change.toStringAsFixed(2)}',
      });
    } else {
      if (_cardDigitsController.text.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter last 4 digits')),
        );
        return;
      }

      Navigator.pop(context, {
        'payment_method': 'pos_card',
        'payment_details': 'Card ending in ${_cardDigitsController.text}',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.payment_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Payment',
                  style: TextStyle(
                    fontSize: 24,
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
            const Divider(height: 32),

            // Total Amount
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppCurrency.format(widget.cart.total),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method Selection
            Row(
              children: [
                Expanded(
                  child: _buildPaymentMethodButton(
                    'Cash',
                    Icons.money_rounded,
                    'pos_cash',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentMethodButton(
                    'Card',
                    Icons.credit_card_rounded,
                    'pos_card',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment Details
            if (_paymentMethod == 'pos_cash') ...[
              _buildCashPaymentSection(),
            ] else ...[
              _buildCardPaymentSection(),
            ],

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: AppColors.success,
              ),
              child: const Text(
                'Complete Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodButton(String label, IconData icon, String method) {
    final isSelected = _paymentMethod == method;
    
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surface,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashPaymentSection() {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cash Received Input
            TextField(
              controller: _cashReceivedController,
              decoration: const InputDecoration(
                labelText: 'Cash Received',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
              autofocus: true,
            ),
            
            if (_cashReceived > 0) ...[
              const SizedBox(height: 16),
              
              // Change Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _change >= 0
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _change >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    Text(
                      '\$${_change.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _change >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Quick Cash Buttons
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [20, 50, 100].map((amount) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _cashReceivedController.text = amount.toString();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: Text('\$$amount'),
                );
              }).toList(),
            ),

            // Denomination Counter (Optional)
            if (session.denominations.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Enter Denominations'),
                children: [
                  ...session.denominations.map((denom) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              denom.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                _denominationCounts[denom.id] = 
                                    (_denominationCounts[denom.id] ?? 0) - 1;
                                if (_denominationCounts[denom.id]! <= 0) {
                                  _denominationCounts.remove(denom.id);
                                }
                                _updateCashFromDenominations(session);
                              });
                            },
                          ),
                          Text(
                            '${_denominationCounts[denom.id] ?? 0}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _denominationCounts[denom.id] = 
                                    (_denominationCounts[denom.id] ?? 0) + 1;
                                _updateCashFromDenominations(session);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  void _updateCashFromDenominations(SessionProvider session) {
    final total = session.calculateTotal(_denominationCounts);
    _cashReceivedController.text = total.toStringAsFixed(2);
  }

  Widget _buildCardPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _cardDigitsController,
          decoration: const InputDecoration(
            labelText: 'Last 4 digits of card',
            prefixIcon: Icon(Icons.credit_card),
            hintText: '1234',
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          autofocus: true,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Process the card payment on your card terminal, then enter the last 4 digits here for record keeping.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
