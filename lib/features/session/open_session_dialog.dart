import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'session_provider.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/widgets/app_toast.dart';

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
    final amount = double.tryParse(_openingCashController.text) ?? 0;
    if (amount < 0) {
      AppToast.error(context, 'Please enter a valid opening cash amount');
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
      AppToast.error(context, session.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      'Open Register',
                      style: TextStyle(
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
                  decoration: const InputDecoration(
                    labelText: 'Opening Cash Amount',
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: '0.00',
                    helperText: 'Enter the cash in your drawer',
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
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add any notes...',
                    prefixIcon: Icon(Icons.note_outlined),
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
                        child: const Text('Cancel'),
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
                        label: Text(session.isLoading ? 'Opening...' : 'Open Register'),
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
