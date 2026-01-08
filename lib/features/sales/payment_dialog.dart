import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/models/cart.dart';
import '../session/session_provider.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/widgets/app_toast.dart';
import '../../l10n/generated/app_localizations.dart';

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

  /// Generate dynamic quick cash amounts based on total
  List<int> get _quickCashAmounts {
    final total = widget.cart.total;
    final List<int> amounts = [];

    // Standard denominations to consider
    const standardDenoms = [100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000];

    for (final denom in standardDenoms) {
      if (denom > total) {
        amounts.add(denom);
        if (amounts.length >= 4) break; // Max 4 quick amounts
      }
    }

    // If total is very high and no standard denoms work, add rounded up amounts
    if (amounts.isEmpty) {
      final roundedUp = ((total / 10000).ceil() * 10000).toInt();
      amounts.add(roundedUp);
      amounts.add(roundedUp + 10000);
    }

    return amounts;
  }

  @override
  void dispose() {
    _cashReceivedController.dispose();
    _cardDigitsController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final l10n = AppLocalizations.of(context);
    if (_paymentMethod == 'pos_cash') {
      if (_cashReceived < widget.cart.total) {
        AppToast.error(context, l10n?.insufficientCash ?? 'Insufficient cash received');
        return;
      }

      Navigator.pop(context, {
        'payment_method': 'pos_cash',
        'payment_details': 'Cash: \$${_cashReceived.toStringAsFixed(2)}, Change: \$${_change.toStringAsFixed(2)}',
        'payment_metadata': {
          'cash_received': _cashReceived,
          'change_given': _change,
        },
      });
    } else {
      if (_cardDigitsController.text.length != 4) {
        AppToast.error(context, l10n?.enterLast4Digits ?? 'Please enter last 4 digits');
        return;
      }

      Navigator.pop(context, {
        'payment_method': 'pos_card',
        'payment_details': 'Card ending in ${_cardDigitsController.text}',
        'payment_metadata': {
          'card_last_four': _cardDigitsController.text,
        },
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                Text(
                  l10n?.payment ?? 'Payment',
                  style: const TextStyle(
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
                  Text(
                    l10n?.totalAmount ?? 'Total Amount',
                    style: const TextStyle(
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
                    l10n?.cash ?? 'Cash',
                    Icons.money_rounded,
                    'pos_cash',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentMethodButton(
                    l10n?.card ?? 'Card',
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
              child: Text(
                l10n?.completePayment ?? 'Complete Payment',
                style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cash Received Input
            TextField(
              controller: _cashReceivedController,
              decoration: InputDecoration(
                labelText: l10n?.cashReceived ?? 'Cash Received',
                prefixIcon: const Icon(Icons.attach_money),
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
                      l10n?.change ?? 'Change',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _change >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    Text(
                      AppCurrency.format(_change.abs()),
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

            // Quick Cash Buttons (Dynamic based on total)
            const SizedBox(height: 16),
            Text(
              l10n?.quickCash ?? 'Quick Cash',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Exact amount button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _cashReceivedController.text = widget.cart.total.toStringAsFixed(2);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                  ),
                  child: Text(l10n?.exact ?? 'Exact'),
                ),
                // Dynamic amounts
                ..._quickCashAmounts.map((amount) {
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _cashReceivedController.text = amount.toString();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                    ),
                    child: Text(AppCurrency.formatCompact(amount.toDouble())),
                  );
                }),
              ],
            ),

            // Denomination Counter (Optional)
            if (session.denominations.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(l10n?.enterDenominations ?? 'Enter Denominations'),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _cardDigitsController,
          decoration: InputDecoration(
            labelText: l10n?.cardLastDigits ?? 'Last 4 digits of card',
            prefixIcon: const Icon(Icons.credit_card),
            hintText: l10n?.cardLastDigitsHint ?? '1234',
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
              Expanded(
                child: Text(
                  l10n?.cardPaymentInstruction ?? 'Process the card payment on your card terminal, then enter the last 4 digits here for record keeping.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
