import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'close_session_dialog.dart';
import '../../shared/constants/app_constants.dart';

/// Dialog shown when user logs in with an existing open session
/// Gives options to Continue or Start Fresh
class ExistingSessionDialog extends StatelessWidget {
  final Map<String, dynamic> session;

  const ExistingSessionDialog({super.key, required this.session});

  Future<void> _handleStartFresh(BuildContext context) async {
    // Close the existing session first
    final shouldClose = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CloseSessionDialog(),
    );

    if (shouldClose == true && context.mounted) {
      // Session closed successfully - return 'start_fresh'
      Navigator.pop(context, 'start_fresh');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final openedAt = DateTime.parse(session['opened_at']);
    final userName = session['user_name'] ?? 'User';

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Session Already Open',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // Session Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You have an open session:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // User name
                  _buildInfoRow(
                    Icons.person,
                    'User',
                    userName,
                  ),

                  const SizedBox(height: 8),

                  // Opened time
                  _buildInfoRow(
                    Icons.access_time,
                    'Opened',
                    dateFormat.format(openedAt),
                  ),

                  const SizedBox(height: 8),

                  // Opening cash
                  _buildInfoRow(
                    Icons.attach_money,
                    'Opening Cash',
                    AppCurrency.format((session['opening_cash'] as num).toDouble()),
                  ),

                  // Transaction count if available
                  if (session['total_orders'] != null &&
                      session['total_orders'] > 0) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.receipt_long,
                      'Transactions',
                      '${session['total_orders']}',
                    ),
                  ],

                  // Total sales if available
                  if (session['total_sales'] != null &&
                      session['total_sales'] > 0) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.point_of_sale,
                      'Total Sales',
                      AppCurrency.format((session['total_sales'] as num).toDouble()),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Question
            Text(
              'What would you like to do?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Continue Button
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'continue'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continue Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 12),

            // Start Fresh Button
            OutlinedButton.icon(
              onPressed: () => _handleStartFresh(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Start Fresh'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.primary),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),

            const SizedBox(height: 12),

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Continue: Resume your session\nStart Fresh: Close & open new session',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
