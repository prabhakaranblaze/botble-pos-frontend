import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'session_provider.dart';
import '../../shared/constants/app_constants.dart';

class OpenSessionDialog extends StatefulWidget {
  final int registerId;

  const OpenSessionDialog({super.key, required this.registerId});

  @override
  State<OpenSessionDialog> createState() => _OpenSessionDialogState();
}

class _OpenSessionDialogState extends State<OpenSessionDialog> {
  final _openingCashController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<int, int> _denominationCounts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadDenominations();
    });
  }

  @override
  void dispose() {
    _openingCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleOpenSession() async {
    final amount = double.tryParse(_openingCashController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter opening cash amount')),
      );
      return;
    }

    final session = context.read<SessionProvider>();
    final success = await session.openSession(
      cashRegisterId: widget.registerId,
      openingCash: amount,
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
                      'Open Session',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                TextField(
                  controller: _openingCashController,
                  decoration: const InputDecoration(
                    labelText: 'Opening Cash Amount',
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
                ),
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
                            session.isLoading ? null : _handleOpenSession,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: session.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Open Session'),
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
    _openingCashController.text = total.toStringAsFixed(2);
  }
}
