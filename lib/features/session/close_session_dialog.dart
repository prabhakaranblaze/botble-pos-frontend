import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'session_provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/widgets/app_toast.dart';
import '../../l10n/generated/app_localizations.dart';

class CloseSessionDialog extends StatefulWidget {
  const CloseSessionDialog({super.key});

  @override
  State<CloseSessionDialog> createState() => _CloseSessionDialogState();
}

class _CloseSessionDialogState extends State<CloseSessionDialog> {
  final _closingCashController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<int, int> _denominationCounts = {};
  bool _isClosing = false;
  bool _isRefreshing = true;

  @override
  void initState() {
    super.initState();
    // Refresh session data to get latest cash sales
    _refreshSession();
  }

  Future<void> _refreshSession() async {
    final sessionProvider = context.read<SessionProvider>();
    await sessionProvider.checkActiveSession();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _closingCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleCloseSession() async {
    final amount = double.tryParse(_closingCashController.text) ?? 0;
    if (amount < 0) {
      AppToast.error(context, 'Please enter closing cash amount');
      return;
    }

    setState(() => _isClosing = true);

    final sessionProvider = context.read<SessionProvider>();
    final authProvider = context.read<AuthProvider>();

    debugPrint('🔴 CloseSession: Closing session...');

    // Step 1: Close the session via API
    final success = await sessionProvider.closeSession(
      closingCash: amount,
      denominations: _denominationCounts.isEmpty
          ? null
          : _denominationCounts.map((k, v) => MapEntry(k.toString(), v)),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (!mounted) return;

    if (success) {
      debugPrint('✅ CloseSession: Session closed successfully');

      // Step 2: Close dialog
      Navigator.of(context).pop(true);

      // Step 3: Clear session from provider
      sessionProvider.clearSession();

      debugPrint('🔴 CloseSession: Logging out...');

      // Step 4: Logout (this will trigger navigation to login)
      await authProvider.logout();

      debugPrint('✅ CloseSession: Complete');
    } else {
      setState(() => _isClosing = false);

      if (sessionProvider.error != null && mounted) {
        AppToast.error(context, sessionProvider.error!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Consumer<SessionProvider>(
          builder: (context, session, _) {
            final activeSession = session.activeSession;

            if (activeSession == null || _isRefreshing) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading session data...'),
                    ],
                  ),
                ),
              );
            }

            final closingAmount =
                double.tryParse(_closingCashController.text) ?? 0;
            final openingCash =
                (activeSession['opening_cash'] as num).toDouble();
            final cashSales =
                (activeSession['cash_sales'] as num?)?.toDouble() ?? 0;
            final expectedCash = openingCash + cashSales;
            final difference = closingAmount - expectedCash;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.close_rounded, color: AppColors.error, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      l10n?.closeSession ?? 'Close Session',
                      style:
                          const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                          Text('${l10n?.openingCash ?? 'Opening Cash'}:'),
                          Text(
                            AppCurrency.format(openingCash),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${l10n?.cashSales ?? 'Cash Sales'}:'),
                          Text(
                            '+ ${AppCurrency.format(cashSales)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l10n?.expectedCash ?? 'Expected Cash'}:',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            AppCurrency.format(expectedCash),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _closingCashController,
                  decoration: InputDecoration(
                    labelText: l10n?.closingCashAmount ?? 'Closing Cash Amount',
                    prefixText: '${AppConstants.currencyCode} ',
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
                  enabled: !_isClosing,
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
                          AppCurrency.format(difference.abs()),
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
                    title: Text(l10n?.countDenominations ?? 'Count Denominations (Optional)'),
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
                                onPressed: _isClosing
                                    ? null
                                    : () {
                                        setState(() {
                                          _denominationCounts[denom.id] =
                                              (_denominationCounts[denom.id] ??
                                                      0) -
                                                  1;
                                          if (_denominationCounts[denom.id]! <=
                                              0) {
                                            _denominationCounts
                                                .remove(denom.id);
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
                                onPressed: _isClosing
                                    ? null
                                    : () {
                                        setState(() {
                                          _denominationCounts[denom.id] =
                                              (_denominationCounts[denom.id] ??
                                                      0) +
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
                  decoration: InputDecoration(
                    labelText: l10n?.notesOptional ?? 'Notes (Optional)',
                    hintText: l10n?.addNotes ?? 'Add any notes...',
                  ),
                  maxLines: 3,
                  enabled: !_isClosing,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed:
                            _isClosing ? null : () => Navigator.pop(context),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isClosing ? null : _handleCloseSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isClosing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n?.closeSession ?? 'Close Session'),
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
