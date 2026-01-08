import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'session_provider.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/widgets/app_toast.dart';
import '../../l10n/generated/app_localizations.dart';

class OpenSessionDialog extends StatefulWidget {
  const OpenSessionDialog({super.key});

  @override
  State<OpenSessionDialog> createState() => _OpenSessionDialogState();
}

class _OpenSessionDialogState extends State<OpenSessionDialog> {
  final _openingCashController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _openingCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleOpenSession() async {
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_openingCashController.text) ?? 0;
    if (amount < 0) {
      AppToast.error(context, l10n?.enterValidOpeningCash ?? 'Please enter a valid opening cash amount');
      return;
    }

    final session = context.read<SessionProvider>();
    final success = await session.openSession(
      openingCash: amount,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (session.error != null && mounted) {
      // Check if error is "already have open register"
      if (session.error!.toLowerCase().contains('already have an open')) {
        _showRecoverSessionDialog();
      } else {
        AppToast.error(context, session.error!);
      }
    }
  }

  Future<void> _showRecoverSessionDialog() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            Text(l10n?.sessionFound ?? 'Session Found'),
          ],
        ),
        content: Text(
          l10n?.existingSessionMessage ?? 'You already have an open session. Would you like to continue with that session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.refresh),
            label: Text(l10n?.continueSession ?? 'Continue Session'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Retry fetching active session
      final session = context.read<SessionProvider>();
      await session.checkActiveSession();

      if (session.hasActiveSession && mounted) {
        Navigator.pop(context, true); // Close dialog and proceed
      } else if (mounted) {
        AppToast.error(context, l10n?.couldNotRecoverSession ?? 'Could not recover session. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Consumer<SessionProvider>(
          builder: (context, session, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      l10n?.openRegister ?? 'Open Register',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Opening Cash Amount
                TextField(
                  controller: _openingCashController,
                  decoration: InputDecoration(
                    labelText: l10n?.openingCashAmount ?? 'Opening Cash Amount',
                    prefixText: '${AppConstants.currencyCode} ',
                    hintText: '0.00',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  autofocus: true,
                ),
                const SizedBox(height: 20),

                // Notes
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n?.notesOptional ?? 'Notes (Optional)',
                    hintText: l10n?.addNotes ?? 'Add any notes...',
                    prefixIcon: const Icon(Icons.note_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed:
                            session.isLoading ? null : _handleOpenSession,
                        icon: session.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.play_arrow_rounded),
                        label: Text(session.isLoading ? (l10n?.loading ?? 'Opening...') : (l10n?.openRegister ?? 'Open Register')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
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
}
