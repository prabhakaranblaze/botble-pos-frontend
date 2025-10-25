import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'session_provider.dart';
import 'close_session_dialog.dart';
import '../../shared/constants/app_constants.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  Future<void> _closeSession(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CloseSessionDialog(),
    );

    // Dialog handles everything including logout, so we don't need to do anything here
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        if (!session.hasActiveSession) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_rounded,
                    size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No active session',
                  style:
                      TextStyle(fontSize: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final activeSession = session.activeSession!;
        final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

        // Parse the opened_at timestamp
        final openedAt = DateTime.parse(activeSession['opened_at'] as String);
        final duration = DateTime.now().difference(openedAt);
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Session',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              color: AppColors.primary, size: 32),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeSession['cash_register_name']
                                        as String? ??
                                    'Cash Register',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Session #${activeSession['id']}',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 8, color: AppColors.success),
                                const SizedBox(width: 8),
                                Text(
                                  'OPEN',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildInfoRow('Opened At', dateFormat.format(openedAt)),
                      _buildInfoRow('Duration', '${hours}h ${minutes}m'),
                      _buildInfoRow('Opened By',
                          activeSession['user_name'] as String? ?? 'User'),
                      _buildInfoRow(
                        'Opening Cash',
                        '\$${(activeSession['opening_cash'] as num).toStringAsFixed(2)}',
                      ),
                      if (activeSession['opening_notes'] != null &&
                          (activeSession['opening_notes'] as String)
                              .isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Notes:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(activeSession['opening_notes'] as String),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _closeSession(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: const Text(
                    'Close Session',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
