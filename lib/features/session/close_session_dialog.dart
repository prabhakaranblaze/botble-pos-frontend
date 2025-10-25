import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'session_provider.dart';
import '../../shared/constants/app_constants.dart';

class CloseSessionDialog extends StatefulWidget {
  const CloseSessionDialog({super.key});

  @override
  State<CloseSessionDialog> createState() => _CloseSessionDialogState();
}

class _CloseSessionDialogState extends State<CloseSessionDialog> {
  final _closingCashController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<int, int> _denominationCounts = {};

  @override
  void dispose() {
    _closingCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleCloseSession() async {
    final amount = double.tryParse(_closingCashController.text) ?? 0;
    if (amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter closing cash amount')),
      );
      return;
    }

    final session = context.read<SessionProvider>();
    final success = await session.closeSession(
      closingCash: amount,
      denominations: _denominationCounts.isEmpty
          ? null
          : _denominationCounts.map((k, v) => MapEntry(k.toString(), v)),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (session.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Consumer<SessionProvider>(
          builder: (context, session, _) {
            final activeSession = session.activeSession!;
            final closingAmount =
                double.tryParse(_closingCashController.text) ?? 0;
            final openingCash =
                (activeSession['opening_cash'] as num).toDouble();
            final difference = closingAmount - openingCash;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.close_rounded, color: AppColors.error, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Close Session',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Opening Cash:'),
                          Text(
                            '\$${openingCash.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _closingCashController,
                  decoration: const InputDecoration(
                    labelText: 'Closing Cash Amount',
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: '0.00',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                  autofocus: true,
                ),
                if (closingAmount > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: difference >= 0
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          difference >= 0 ? 'Excess:' : 'Short:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: difference >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        Text(
                          '\$${difference.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: difference >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (session.denominations.isNotEmpty) ...[
                  ExpansionTile(
                    title: const Text('Count Denominations (Optional)'),
                    children: [
                      ...session.denominations.map((denom) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  denom.displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    _denominationCounts[denom.id] =
                                        (_denominationCounts[denom.id] ?? 0) -
                                            1;
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
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    _denominationCounts[denom.id] =
                                        (_denominationCounts[denom.id] ?? 0) +
                                            1;
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
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add any notes...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed:
                            session.isLoading ? null : _handleCloseSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: session.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Close Session'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _updateCashFromDenominations(SessionProvider session) {
    final total = session.calculateTotal(_denominationCounts);
    _closingCashController.text = total.toStringAsFixed(2);
  }
}
